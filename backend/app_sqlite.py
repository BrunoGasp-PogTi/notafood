"""
NotaFood - backend
API que recebe um código de barras, consulta o Open Food Facts (OFF),
calcula uma nota de 0 a 100 para o produto e guarda o resultado em SQLite
local (funciona como cache e como histórico de consultas).
"""

import json
import os
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
import base64

import requests
from flask import Flask, jsonify, render_template, request, send_from_directory
from flask_cors import CORS

# Carrega arquivo .env simples se existir
def carregar_env():
    env_paths = [Path(__file__).parent / ".env", Path(__file__).parent.parent / ".env"]
    for env_path in env_paths:
        if env_path.exists():
            try:
                with open(env_path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            k, v = line.split("=", 1)
                            k, v = k.strip(), v.strip().strip("'\"")
                            if k and k not in os.environ:
                                os.environ[k] = v
            except Exception:
                pass

carregar_env()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

# Configurável via env var para permitir apontar para um volume Docker;
# fora do container, cai no padrão (arquivo dentro da própria pasta backend/).
DB_PATH = Path(os.environ.get("NOTAFOOD_DB_PATH", Path(__file__).parent / "produtos.db"))

# Onde o .apk compilado (`flutter build apk`) deve ser colocado para a
# página /instalar conseguir servi-lo.
APK_DIR = Path(__file__).parent / "static" / "apk"
APK_FILENAME = "notafood.apk"

# Tempo que um produto fica "fresco" no cache local antes de consultarmos o
# OFF de novo. Evita martelar a API pública a cada scan do mesmo produto.
CACHE_VALIDADE_DIAS = 7

# Header obrigatório pelas diretrizes do Open Food Facts para identificar quem
# está consumindo a API (evita bloqueio por user-agent genérico).
OFF_USER_AGENT = "NotaFood/1.0 - app gratuito de analise de alimentos (contato via GitHub)"
OFF_URL = "https://world.openfoodfacts.org/api/v2/product/{codigo}.json"

# Penalidade por grupo NOVA (1 = in natura/minimamente processado,
# 4 = ultraprocessado). É o critério de maior peso na nota.
PENALIDADE_NOVA = {1: 0, 2: -5, 3: -15, 4: -35}
DESCRICAO_NOVA = {
    1: "alimento in natura ou minimamente processado",
    2: "ingrediente culinário processado",
    3: "alimento processado",
    4: "alimento ultraprocessado",
}

# Lista curta e curada de aditivos com maior controvérsia/preocupação
# (corantes azo, adoçantes, conservantes de nitrito/nitrato, glutamato).
# Não é uma lista clínica exaustiva, é um sinal extra além da contagem geral.
ADITIVOS_PREOCUPANTES = {
    "E102", "E110", "E122", "E124", "E129",  # corantes artificiais
    "E211", "E250", "E251",  # conservantes (benzoato, nitrito, nitrato)
    "E621",  # glutamato monossódico
    "E951",  # aspartame
}

from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
CORS(app)  # liberado para todas as origens
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)


def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with get_conn() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS produtos (
                codigo TEXT PRIMARY KEY,
                nome TEXT,
                marca TEXT,
                quantidade TEXT,
                imagem TEXT,
                nota INTEGER,
                classificacao TEXT,
                nova INTEGER,
                nutriscore TEXT,
                ingredientes TEXT,
                alergenos TEXT,
                aditivos TEXT,
                criterios TEXT,
                nutrientes TEXT,
                ultima_consulta TEXT
            )
            """
        )
        # Garante retrocompatibilidade se a tabela já existia sem a coluna nutrientes
        try:
            conn.execute("ALTER TABLE produtos ADD COLUMN nutrientes TEXT;")
        except Exception:
            pass



def buscar_off(codigo):
    """Consulta o produto no Open Food Facts. Retorna o dict `product` ou None."""
    try:
        resp = requests.get(
            OFF_URL.format(codigo=codigo),
            headers={"User-Agent": OFF_USER_AGENT},
            timeout=4,
        )
    except requests.RequestException as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ⚠️ Falha de conexão com Open Food Facts: {e}")
        return None

    if resp.status_code != 200:
        return None

    try:
        dados = resp.json()
    except Exception:
        return None

    if dados.get("status") != 1:
        return None
    return dados.get("product")


def extrair_aditivos(produto_off):
    tags = produto_off.get("additives_tags") or []
    return [tag.split(":")[-1].upper() for tag in tags]


def extrair_alergenos(produto_off):
    tags = produto_off.get("allergens_tags") or []
    return [tag.split(":")[-1] for tag in tags]


def calcular_nota(nova, nutrientes, aditivos):
    """
    Calcula a nota (0-100) e a lista de critérios que a justificam.
    Pesos, em ordem de importância:
      1. Classificação NOVA (nível de processamento)
      2. Perfil nutricional (açúcar, gordura saturada, sódio, fibra, proteína)
      3. Aditivos (quantidade e presença de itens mais controversos)

    `nutrientes` é um dict normalizado (mesmos valores por 100g independente
    da origem — Open Food Facts ou digitados/lidos manualmente pelo usuário):
    acucar_100g, gordura_saturada_100g, sal_100g, fibra_100g, proteina_100g.
    """
    pontos = 100
    criterios = []

    if nova in PENALIDADE_NOVA:
        efeito = PENALIDADE_NOVA[nova]
        pontos += efeito
        sinal = "+" if efeito >= 0 else ""
        criterios.append(
            {
                "item": f"classificação NOVA {nova} ({DESCRICAO_NOVA[nova]})",
                "efeito": f"{sinal}{efeito} pts",
            }
        )
    else:
        criterios.append({"item": "classificação NOVA não informada", "efeito": "0 pts"})

    acucar = nutrientes.get("acucar_100g")
    if isinstance(acucar, (int, float)):
        if acucar > 22.5:
            pontos -= 15
            criterios.append({"item": f"açúcar alto ({acucar:.1f}g/100g)", "efeito": "-15 pts"})
        elif acucar > 5:
            pontos -= 5
            criterios.append({"item": f"açúcar moderado ({acucar:.1f}g/100g)", "efeito": "-5 pts"})

    gordura_sat = nutrientes.get("gordura_saturada_100g")
    if isinstance(gordura_sat, (int, float)):
        if gordura_sat > 5:
            pontos -= 10
            criterios.append(
                {"item": f"gordura saturada alta ({gordura_sat:.1f}g/100g)", "efeito": "-10 pts"}
            )
        elif gordura_sat > 1.5:
            pontos -= 5
            criterios.append(
                {"item": f"gordura saturada moderada ({gordura_sat:.1f}g/100g)", "efeito": "-5 pts"}
            )

    sal = nutrientes.get("sal_100g")
    if isinstance(sal, (int, float)):
        if sal > 1.5:
            pontos -= 10
            criterios.append({"item": f"sódio/sal alto ({sal:.1f}g/100g)", "efeito": "-10 pts"})
        elif sal > 0.3:
            pontos -= 5
            criterios.append({"item": f"sódio/sal moderado ({sal:.1f}g/100g)", "efeito": "-5 pts"})

    fibra = nutrientes.get("fibra_100g")
    if isinstance(fibra, (int, float)):
        if fibra > 6:
            pontos += 10
            criterios.append({"item": f"rico em fibras ({fibra:.1f}g/100g)", "efeito": "+10 pts"})
        elif fibra > 3:
            pontos += 5
            criterios.append({"item": f"boa fonte de fibras ({fibra:.1f}g/100g)", "efeito": "+5 pts"})

    proteina = nutrientes.get("proteina_100g")
    if isinstance(proteina, (int, float)) and proteina > 8:
        pontos += 5
        criterios.append({"item": f"rico em proteína ({proteina:.1f}g/100g)", "efeito": "+5 pts"})

    if aditivos:
        penalidade_aditivos = min(len(aditivos) * 3, 15)
        pontos -= penalidade_aditivos
        criterios.append(
            {
                "item": f"{len(aditivos)} aditivo(s) identificado(s)",
                "efeito": f"-{penalidade_aditivos} pts",
            }
        )
        preocupantes = [a for a in aditivos if a in ADITIVOS_PREOCUPANTES]
        if preocupantes:
            pontos -= 5
            criterios.append(
                {
                    "item": f"aditivo(s) de maior preocupação: {', '.join(preocupantes)}",
                    "efeito": "-5 pts",
                }
            )

    pontos = max(0, min(100, round(pontos)))

    if pontos >= 75:
        classificacao = "bom"
    elif pontos >= 50:
        classificacao = "moderado"
    else:
        classificacao = "ruim"

    return pontos, classificacao, criterios


def processa_produto(codigo, produto_off):
    aditivos = extrair_aditivos(produto_off)
    nova = produto_off.get("nova_group")
    nutrimentos_off = produto_off.get("nutriments") or {}
    nutrientes = {
        "acucar_100g": nutrimentos_off.get("sugars_100g"),
        "gordura_saturada_100g": nutrimentos_off.get("saturated-fat_100g"),
        "sal_100g": nutrimentos_off.get("salt_100g"),
        "fibra_100g": nutrimentos_off.get("fiber_100g"),
        "proteina_100g": nutrimentos_off.get("proteins_100g"),
    }
    nota, classificacao, criterios = calcular_nota(nova, nutrientes, aditivos)

    return {
        "codigo": codigo,
        "nome": produto_off.get("product_name_pt") or produto_off.get("product_name") or "Produto sem nome",
        "marca": produto_off.get("brands") or "",
        "quantidade": produto_off.get("quantity") or "",
        "imagem": produto_off.get("image_url") or produto_off.get("image_front_url") or "",
        "nota": nota,
        "classificacao": classificacao,
        "nova": nova or 0,
        "nutriscore": (produto_off.get("nutriscore_grade") or "desconhecido").lower(),
        "ingredientes": produto_off.get("ingredients_text_pt") or produto_off.get("ingredients_text") or "",
        "alergenos": extrair_alergenos(produto_off),
        "aditivos": aditivos,
        "criterios": criterios,
        "nutrientes": nutrientes,
        "ultima_consulta": datetime.utcnow().isoformat(),
    }


def processa_produto_manual(codigo, dados_formulario):
    """
    Mesmo cálculo de `processa_produto`, mas a partir de dados digitados ou
    lidos por OCR pelo usuário (rótulo fotografado), quando o produto não
    está cadastrado no Open Food Facts.
    """
    aditivos = [a.strip().upper() for a in dados_formulario.get("aditivos") or [] if a.strip()]
    alergenos = [a.strip().lower() for a in dados_formulario.get("alergenos") or [] if a.strip()]
    nova = dados_formulario.get("nova") or None
    nutrientes = {
        "acucar_100g": dados_formulario.get("acucar_100g"),
        "gordura_saturada_100g": dados_formulario.get("gordura_saturada_100g"),
        "sal_100g": dados_formulario.get("sal_100g"),
        "fibra_100g": dados_formulario.get("fibra_100g"),
        "proteina_100g": dados_formulario.get("proteina_100g"),
    }
    nota, classificacao, criterios = calcular_nota(nova, nutrientes, aditivos)

    return {
        "codigo": codigo,
        "nome": dados_formulario.get("nome") or "Produto sem nome",
        "marca": dados_formulario.get("marca") or "",
        "quantidade": dados_formulario.get("quantidade") or "",
        "imagem": "",
        "nota": nota,
        "classificacao": classificacao,
        "nova": nova or 0,
        "nutriscore": "desconhecido",
        "ingredientes": dados_formulario.get("ingredientes") or "",
        "alergenos": alergenos,
        "aditivos": aditivos,
        "criterios": criterios,
        "nutrientes": nutrientes,
        "ultima_consulta": datetime.utcnow().isoformat(),
    }


def buscar_cache(codigo):
    with get_conn() as conn:
        linha = conn.execute("SELECT * FROM produtos WHERE codigo = ?", (codigo,)).fetchone()
    if linha is None:
        return None
    dados = dict(linha)
    dados["alergenos"] = json.loads(dados["alergenos"] or "[]")
    dados["aditivos"] = json.loads(dados["aditivos"] or "[]")
    dados["criterios"] = json.loads(dados["criterios"] or "[]")
    dados["nutrientes"] = json.loads(dados.get("nutrientes") or "{}")
    return dados


def cache_fresco(dados_cache):
    try:
        ts = datetime.fromisoformat(dados_cache["ultima_consulta"])
    except (TypeError, ValueError):
        return False
    return datetime.utcnow() - ts < timedelta(days=CACHE_VALIDADE_DIAS)


def salvar_cache(dados):
    with get_conn() as conn:
        conn.execute(
            """
            INSERT INTO produtos (
                codigo, nome, marca, quantidade, imagem, nota, classificacao,
                nova, nutriscore, ingredientes, alergenos, aditivos, criterios, nutrientes, ultima_consulta
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(codigo) DO UPDATE SET
                nome=excluded.nome, marca=excluded.marca, quantidade=excluded.quantidade,
                imagem=excluded.imagem, nota=excluded.nota, classificacao=excluded.classificacao,
                nova=excluded.nova, nutriscore=excluded.nutriscore, ingredientes=excluded.ingredientes,
                alergenos=excluded.alergenos, aditivos=excluded.aditivos, criterios=excluded.criterios,
                nutrientes=excluded.nutrientes, ultima_consulta=excluded.ultima_consulta
            """,
            (
                dados["codigo"], dados["nome"], dados["marca"], dados["quantidade"], dados["imagem"],
                dados["nota"], dados["classificacao"], dados["nova"], dados["nutriscore"],
                dados["ingredientes"], json.dumps(dados["alergenos"]), json.dumps(dados["aditivos"]),
                json.dumps(dados["criterios"]), json.dumps(dados.get("nutrientes") or {}), dados["ultima_consulta"],
            ),
        )


def listar_historico(limite):
    with get_conn() as conn:
        linhas = conn.execute(
            """
            SELECT codigo, nome, marca, nota, classificacao, ultima_consulta
            FROM produtos
            ORDER BY ultima_consulta DESC
            LIMIT ?
            """,
            (limite,),
        ).fetchall()
    return [dict(linha) for linha in linhas]


def monta_resposta(dados, origem):
    campos = (
        "codigo", "nome", "marca", "quantidade", "imagem", "nota", "classificacao",
        "nova", "nutriscore", "ingredientes", "alergenos", "aditivos", "criterios",
    )
    resposta = {campo: dados[campo] for campo in campos}
    resposta["nutrientes"] = dados.get("nutrientes") or {}
    resposta["encontrado"] = True
    resposta["origem"] = origem
    return resposta


@app.route("/produto/<codigo>", methods=["GET"])
def get_produto(codigo):
    codigo = codigo.strip()
    print(f"[{datetime.now().strftime('%H:%M:%S')}] [INFO] Consulta recebida para o codigo: {codigo}")

    cache = buscar_cache(codigo)
    if cache and cache_fresco(cache):
        print(f"[{datetime.now().strftime('%H:%M:%S')}] [OK] Encontrado no Cache Local: {cache.get('nome')} (Nota: {cache.get('nota')})")
        return jsonify(monta_resposta(cache, origem="base_local"))

    print(f"[{datetime.now().strftime('%H:%M:%S')}] [OFF] Consultando Open Food Facts para {codigo}...")
    produto_off = buscar_off(codigo)
    if produto_off is not None:
        dados = processa_produto(codigo, produto_off)
        salvar_cache(dados)
        print(f"[{datetime.now().strftime('%H:%M:%S')}] [OK] Sucesso Open Food Facts: {dados.get('nome')} (Nota: {dados.get('nota')})")
        return jsonify(monta_resposta(dados, origem="openfoodfacts"))

    # Fallback: Se já tinhamos um cache antigo, use
    if cache:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] [AVISO] OFF indisponivel, usando cache anterior: {cache.get('nome')}")
        return jsonify(monta_resposta(cache, origem="base_local"))

    print(f"[{datetime.now().strftime('%H:%M:%S')}] [404] Produto {codigo} nao cadastrado no Open Food Facts.")
    return (
        jsonify(
            {
                "encontrado": False,
                "codigo": codigo,
                "mensagem": "Produto ainda nao cadastrado na base publica. Tire uma foto do rotulo para a IA calcular a nota!",
            }
        ),
        404,
    )


def _para_numero(valor):
    if isinstance(valor, (int, float)):
        return valor
    if isinstance(valor, str) and valor.strip():
        try:
            return float(valor.replace(",", "."))
        except ValueError:
            return None
    return None


@app.route("/produto/manual", methods=["POST"])
def post_produto_manual():
    corpo = request.get_json(silent=True) or {}
    codigo = str(corpo.get("codigo") or "").strip()
    if not codigo:
        return jsonify({"mensagem": "Campo 'codigo' é obrigatório."}), 400

    nova = corpo.get("nova")
    nova = nova if nova in (1, 2, 3, 4) else None

    dados_formulario = {
        "nome": corpo.get("nome"),
        "marca": corpo.get("marca"),
        "quantidade": corpo.get("quantidade"),
        "ingredientes": corpo.get("ingredientes"),
        "aditivos": corpo.get("aditivos"),
        "alergenos": corpo.get("alergenos"),
        "nova": nova,
        "acucar_100g": _para_numero(corpo.get("acucar_100g")),
        "gordura_saturada_100g": _para_numero(corpo.get("gordura_saturada_100g")),
        "sal_100g": _para_numero(corpo.get("sal_100g")),
        "fibra_100g": _para_numero(corpo.get("fibra_100g")),
        "proteina_100g": _para_numero(corpo.get("proteina_100g")),
    }

def consultar_gemini_por_codigo(codigo):
    """
    Quando o produto não existe no Open Food Facts, consulta o Gemini para
    identificar o produto pelo código de barras EAN-13 brasileiro e estimar a tabela.
    """
    key = os.environ.get("GEMINI_API_KEY") or GEMINI_API_KEY
    if not key:
        return None

    prompt = f"""Você é um especialista em alimentos brasileiros.
Identifique o produto com o código de barras EAN-13 brasileiro: {codigo}.
Retorne EXCLUSIVAMENTE um objeto JSON válido (sem markdown) no seguinte formato:
{{
  "encontrado": true,
  "nome": "Nome comercial exato do produto no Brasil",
  "marca": "Marca do fabricante",
  "quantidade": "Peso/Volume da embalagem (ex: 250g, 500ml)",
  "ingredientes": "Lista provável de ingredientes",
  "aditivos": ["INS 100i", "INS 415"],
  "alergenos": ["leite", "gluten"],
  "nova": 1 a 4 (número inteiro: 1=in natura, 2=culinário, 3=processado, 4=ultraprocessado),
  "acucar_100g": float em gramas por 100g,
  "gordura_saturada_100g": float em gramas por 100g,
  "sal_100g": float em gramas de sal por 100g,
  "fibra_100g": float em gramas por 100g,
  "proteina_100g": float em gramas por 100g
}}
Se você tiver certeza absoluta de que esse código não existe no Brasil, retorne: {{"encontrado": false}}"""

    modelos = ["gemini-2.5-flash", "gemini-3.6-flash", "gemini-flash-latest"]
    for modelo in modelos:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{modelo}:generateContent?key={key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "response_mime_type": "application/json",
                "thinkingConfig": {"thinkingBudget": 0},
            },
        }
        try:
            resp = requests.post(url, headers={"Content-Type": "application/json"}, json=payload, timeout=6)
            if resp.status_code == 200:
                data = resp.json()
                texto = data["candidates"][0]["content"]["parts"][0]["text"].strip()
                if texto.startswith("```"):
                    texto = texto.split("\n", 1)[1].rsplit("```", 1)[0].strip()
                parsed = json.loads(texto)
                if parsed.get("encontrado") is not False and parsed.get("nome"):
                    return parsed
        except Exception as e:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] [AVISO] Falha Gemini codigo {modelo}: {e}")
            continue
    return None


def analisar_imagem_com_gemini(imagem_bytes, mime_type="image/jpeg"):
    """
    Usa o Gemini Vision para extrair informações nutricionais, ingredientes e classificação NOVA
    diretamente da imagem do rótulo ou embalagem.
    """
    key = os.environ.get("GEMINI_API_KEY") or GEMINI_API_KEY
    if not key:
        raise ValueError("Chave GEMINI_API_KEY não configurada. Defina no arquivo .env ou como variável de ambiente.")

    # Modelos recomendados em ordem de preferência
    modelos = ["gemini-2.5-flash", "gemini-3.6-flash", "gemini-flash-latest"]
    
    prompt = """Analise esta imagem de alimento/rótulo brasileiro.
Extraia e retorne EXCLUSIVAMENTE um objeto JSON válido (sem markdown em volta) com este formato exato:
{
  "nome": "Nome comercial do produto",
  "marca": "Marca ou fabricante (ou string vazia se não visível)",
  "quantidade": "Peso/Volume da embalagem (ex: 200g, 1L)",
  "ingredientes": "Texto completo dos ingredientes encontrados",
  "alergenos": ["leite", "gluten", "soja"],
  "aditivos": ["E330", "E621"],
  "nova": 1 a 4 (Classificação NOVA inteira: 1=in natura/minimamente processado, 2=ingrediente culinário, 3=processado, 4=ultraprocessado),
  "acucar_100g": número float em gramas por 100g (ou null se não encontrado),
  "gordura_saturada_100g": número float em gramas por 100g (ou null se não encontrado),
  "sal_100g": número float em gramas de sal por 100g (se tiver sódio em mg: sodio_mg * 2.5 / 1000) (ou null),
  "fibra_100g": número float em gramas por 100g (ou null se não encontrado),
  "proteina_100g": número float em gramas por 100g (ou null se não encontrado)
}

Importante: se a tabela tiver 3 colunas (100g, porção e %VD), extraia SEMPRE os valores por 100g."""

    img_b64 = base64.b64encode(imagem_bytes).decode("utf-8")

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt},
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": img_b64
                        }
                    }
                ]
            }
        ],
        "generationConfig": {
            "response_mime_type": "application/json",
            "thinkingConfig": {"thinkingBudget": 0}
        }
    }

    ultimo_erro = None
    for modelo in modelos:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{modelo}:generateContent?key={key}"
        try:
            resp = requests.post(url, json=payload, timeout=25)
            if resp.status_code == 200:
                data = resp.json()
                texto_resposta = data["candidates"][0]["content"]["parts"][0]["text"]
                return json.loads(texto_resposta)
            else:
                ultimo_erro = f"HTTP {resp.status_code}: {resp.text}"
        except Exception as e:
            ultimo_erro = str(e)
            continue

    raise RuntimeError(f"Falha ao consultar Gemini Vision: {ultimo_erro}")


@app.route("/produto/analisar-imagem", methods=["POST"])
def post_analisar_imagem():
    """
    Recebe uma imagem da embalagem ou rótulo e usa IA (Gemini Vision) para identificar
    o produto, ler a tabela nutricional, ingredientes, aditivos e calcular a nota.
    """
    codigo = ""
    imagem_bytes = None
    mime_type = "image/jpeg"

    # Suporta upload via Multipart Form ou JSON Base64
    if "imagem" in request.files:
        arquivo = request.files["imagem"]
        imagem_bytes = arquivo.read()
        mime_type = arquivo.mimetype or "image/jpeg"
        codigo = request.form.get("codigo", "").strip()
    else:
        corpo = request.get_json(silent=True) or {}
        codigo = str(corpo.get("codigo") or "").strip()
        b64_str = corpo.get("imagem_base64") or corpo.get("imagem")
        if b64_str:
            if "," in b64_str:
                b64_str = b64_str.split(",", 1)[1]
            imagem_bytes = base64.b64decode(b64_str)
            mime_type = corpo.get("mime_type", "image/jpeg")

    if not imagem_bytes:
        return jsonify({"mensagem": "Nenhuma imagem fornecida para análise."}), 400

    try:
        resultado_ia = analisar_imagem_com_gemini(imagem_bytes, mime_type)
    except ValueError as ve:
        return jsonify({"mensagem": str(ve), "config_necessaria": "GEMINI_API_KEY"}), 500
    except Exception as e:
        return jsonify({"mensagem": f"Erro no processamento da imagem por IA: {e}"}), 500

    # Se não tiver código de barras, gera um identificador único baseado no timestamp
    if not codigo:
        codigo = f"IA_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

    nova = resultado_ia.get("nova")
    nova = nova if nova in (1, 2, 3, 4) else None

    dados_formulario = {
        "nome": resultado_ia.get("nome"),
        "marca": resultado_ia.get("marca"),
        "quantidade": resultado_ia.get("quantidade"),
        "ingredientes": resultado_ia.get("ingredientes"),
        "aditivos": resultado_ia.get("aditivos"),
        "alergenos": resultado_ia.get("alergenos"),
        "nova": nova,
        "acucar_100g": _para_numero(resultado_ia.get("acucar_100g")),
        "gordura_saturada_100g": _para_numero(resultado_ia.get("gordura_saturada_100g")),
        "sal_100g": _para_numero(resultado_ia.get("sal_100g")),
        "fibra_100g": _para_numero(resultado_ia.get("fibra_100g")),
        "proteina_100g": _para_numero(resultado_ia.get("proteina_100g")),
    }

    dados = processa_produto_manual(codigo, dados_formulario)
    salvar_cache(dados)
    return jsonify(monta_resposta(dados, origem="ia_gemini"))


@app.route("/historico", methods=["GET"])
def get_historico():
    limite = request.args.get("limite", default=20, type=int)
    limite = max(1, min(limite, 100))
    return jsonify(listar_historico(limite))


@app.route("/")
@app.route("/instalar")
def instalar():
    # Procura o APK em múltiplos caminhos possíveis
    candidatos = [
        APK_DIR / APK_FILENAME,
        Path(__file__).parent.parent / "app" / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk",
        Path(__file__).parent.parent / "app" / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk",
    ]
    caminho_apk = next((p for p in candidatos if p.exists()), None)
    apk_disponivel = caminho_apk is not None
    tamanho_mb = round(caminho_apk.stat().st_size / (1024 * 1024), 1) if apk_disponivel else None
    return render_template("instalar.html", apk_disponivel=apk_disponivel, tamanho_mb=tamanho_mb)


@app.route("/download")
@app.route("/instalar/apk")
def instalar_apk():
    candidatos = [
        APK_DIR / APK_FILENAME,
        Path(__file__).parent.parent / "app" / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk",
        Path(__file__).parent.parent / "app" / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk",
    ]
    caminho_apk = next((p for p in candidatos if p.exists()), None)
    if not caminho_apk:
        return jsonify({"mensagem": "APK ainda não disponível neste servidor."}), 404
    return send_from_directory(caminho_apk.parent, caminho_apk.name, as_attachment=True, download_name="NotaFood.apk")


@app.route("/health")
def health():
    return jsonify({"status": "ok", "app": "NotaFood API", "version": "1.0.0"})


if __name__ == "__main__":
    init_db()
    # 6001: 5000/5001 colidem com outros processos já ocupando essas portas
    # nesta máquina (ver README).
    porta = int(os.environ.get("NOTAFOOD_PORT", 6001))
    print(f" Servidor NotaFood Backend rodando em http://0.0.0.0:{porta} (IP Local: 192.168.15.5:{porta})")
    app.run(host="0.0.0.0", port=porta, debug=False)

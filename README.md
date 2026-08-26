# NotaFood

App gratuito e open source de análise de alimentos por código de barras — no
estilo do Desrotulando, mas sem custo pro usuário. Os dados vêm do
[Open Food Facts](https://world.openfoodfacts.org) (OFF); a nota de 0 a 100 é
calculada por este projeto (NOVA + perfil nutricional + aditivos), não vem
pronta do OFF.

Monorepo:

```
/backend   API Flask (consulta o OFF, calcula a nota, cacheia em SQLite)
/app       App Flutter (scanner de código de barras + resultado + histórico)
```

## Backend

### Passo a passo do zero

```bash
cd backend
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python app_sqlite.py
```

O servidor sobe em `http://0.0.0.0:6001` (aceita conexões de outros
dispositivos na mesma rede, não só do localhost). Na primeira execução ele
cria o arquivo `produtos.db` (SQLite) na própria pasta `backend/`.

A porta é **6001** (não 5000, o padrão do Flask, nem 5001) porque ambas já
estavam ocupadas por outros processos nesta máquina — inclusive um serviço
do próprio Windows escutando em 5001, que só ficou visível depois de ligar
o modo `mirrored` de rede do WSL2 (ver nota abaixo). Se precisar de outra
porta, use a env var `NOTAFOOD_PORT` — e lembre de ajustar o `BASE_URL` do
app também:

```bash
NOTAFOOD_PORT=6002 python app_sqlite.py
```

**Nota sobre WSL2 + rede mirrored:** se o backend roda dentro do WSL2 e você
quer acessá-lo de outros dispositivos pelo IP do Windows na rede (não o IP
interno do WSL), o WSL2 precisa estar em modo de rede `mirrored`
(`%USERPROFILE%\.wslconfig` com `[wsl2]` e `networkingMode=mirrored`, depois
`wsl --shutdown` pra aplicar). Sem isso, o WSL vive numa rede virtual própria
e nada bate nele vindo de fora da máquina. Uma consequência desse modo: as
portas passam a ser compartilhadas entre Windows e WSL — se algo no Windows
já usa a porta que você escolher, o `docker compose up` sobe sem erro
aparente, mas a porta não é publicada de verdade (confira com
`docker inspect <container> --format '{{json .NetworkSettings.Ports}}'`; se
vier vazio, é conflito de porta compartilhada com o host Windows).

### Alternativa: rodar via Docker

Se preferir não instalar Python/pip na máquina, dá pra subir o backend só com
Docker (usa `backend/Dockerfile` + `docker-compose.yml` na raiz):

```bash
docker compose up -d --build
```

O servidor fica em `http://localhost:6001` — mesma porta e mesmas rotas da
execução via venv, então do ponto de vista do app Flutter não faz diferença
nenhuma qual dos dois modos você usa. O SQLite fica num volume Docker nomeado
(`notafood_data`, montado em `/data` dentro do container), então o histórico
sobrevive a `docker compose restart` e a rebuilds da imagem. Pra apagar tudo
(inclusive o histórico salvo):

```bash
docker compose down -v
```

### Rotas

- `GET /produto/<codigo>` — busca o produto (cache local primeiro; se estiver
  velho ou não existir, consulta o Open Food Facts, calcula a nota e salva).
  Resposta de sucesso:

  ```json
  {
    "encontrado": true,
    "origem": "openfoodfacts",
    "codigo": "7891000100103",
    "nome": "...",
    "marca": "...",
    "quantidade": "...",
    "imagem": "https://...",
    "nota": 42,
    "classificacao": "moderado",
    "nova": 4,
    "nutriscore": "d",
    "ingredientes": "texto...",
    "alergenos": ["gluten", "milk"],
    "aditivos": ["E330", "E322"],
    "criterios": [{ "item": "açúcar alto (38.0g/100g)", "efeito": "-25 pts" }]
  }
  ```

  Quando o produto não existe no OFF, responde HTTP 404:

  ```json
  { "encontrado": false, "codigo": "...", "mensagem": "..." }
  ```

- `GET /historico?limite=20` — devolve os últimos N produtos já consultados
  (`codigo`, `nome`, `nota`, `classificacao`, `ultima_consulta`), usados na
  tela de histórico do app. `limite` é opcional (padrão 20, máximo 100).

- `POST /produto/manual` — calcula e salva a nota de um produto que não foi
  encontrado no Open Food Facts, a partir de dados que o usuário digitou ou
  leu por OCR do rótulo físico (ver seção do app Flutter). Corpo esperado:

  ```json
  {
    "codigo": "...",
    "nome": "...",
    "marca": "...",
    "quantidade": "...",
    "ingredientes": "texto...",
    "aditivos": ["E330", "E322"],
    "alergenos": ["gluten", "soja"],
    "nova": 4,
    "acucar_100g": 30,
    "gordura_saturada_100g": 6,
    "sal_100g": 1.8,
    "fibra_100g": 1,
    "proteina_100g": 5
  }
  ```

  Todos os campos numéricos são opcionais — o que não vier simplesmente não
  entra no cálculo (mesmo comportamento do fluxo via Open Food Facts). A
  resposta segue o mesmo contrato de `GET /produto/<codigo>`, com
  `"origem": "manual"`, e o produto passa a aparecer no histórico normalmente.

### Como a nota é calculada

A nota começa em 100 e sofre bônus/penalidades. Critério de maior peso é a
classificação **NOVA** (nível de processamento):

| NOVA | Descrição                          | Efeito |
| ---- | ----------------------------------- | ------ |
| 1    | in natura / minimamente processado  | 0      |
| 2    | ingrediente culinário processado    | -5     |
| 3    | alimento processado                 | -15    |
| 4    | alimento ultraprocessado            | -35    |

Depois entram o **perfil nutricional** (por 100g: açúcar, gordura saturada e
sódio penalizam; fibra e proteína bonificam) e os **aditivos** (penalidade por
quantidade, com penalidade extra se houver algum aditivo de uma lista curta de
itens mais controversos, como corantes azo, nitrito/nitrato, glutamato e
aspartame). Os detalhes de cada cálculo ficam no array `criterios` da
resposta — é o "porquê" da nota mostrado no app. Os pesos e limiares estão
todos centralizados em `backend/app_sqlite.py` (`calcular_nota`) e podem ser
recalibrados livremente.

Faixas de classificação: `bom` (nota ≥ 75), `moderado` (50–74), `ruim` (< 50).

### Cache, User-Agent e rate limit

- O backend identifica-se ao Open Food Facts com um `User-Agent` próprio
  (exigido pelas diretrizes de uso da API pública). Está fixo em
  `OFF_USER_AGENT`, em `app_sqlite.py`.
- Todo produto consultado é salvo no SQLite local. Enquanto o cache tiver
  menos de `CACHE_VALIDADE_DIAS` (7 dias por padrão), a próxima consulta ao
  mesmo código de barras **não** bate no OFF de novo — a resposta vem com
  `"origem": "base_local"`. Isso evita martelar a API pública a cada scan
  repetido. Ajuste `CACHE_VALIDADE_DIAS` em `app_sqlite.py` se quiser outro
  intervalo.

### Página de instalação do APK (`/instalar`)

O backend serve uma página simples em `GET /instalar` com um botão "Baixar
APK" e o passo a passo de instalação (permitir fontes desconhecidas etc.) —
pensada para abrir direto do navegador do celular, apontando pro IP da
máquina na rede local (ex.: `http://192.168.15.5:6001/instalar`).

Ela não gera o APK sozinha. Para publicá-lo:

```bash
cd app
flutter build apk --release --dart-define=BASE_URL=http://192.168.15.5:6001
cp build/app/outputs/flutter-apk/app-release.apk ../backend/static/apk/notafood.apk
```

**Importante:** o `--dart-define=BASE_URL=...` não é opcional aqui. Sem ele,
o APK usa o padrão de `config.dart` (`http://10.0.2.2:6001`), que só existe
dentro do **emulador** Android — instalado num celular físico, o app tenta
falar com um endereço que não existe e a tela de Resultado fica carregando
para sempre (a request nem chega a dar erro de forma perceptível). Sempre
aponte pro IP real da máquina na rede local ao gerar o APK pra distribuir.

Enquanto esse arquivo não existir, a página mostra "nenhum APK disponível"
em vez do botão de download. Rodando via Docker, `backend/static/apk/` já
está montado como volume (ver `docker-compose.yml`), então basta colocar o
arquivo ali — não precisa rebuildar a imagem.

### Testando manualmente

```bash
curl http://127.0.0.1:6001/produto/7891000100103   # Leite Moça
curl http://127.0.0.1:6001/produto/7891000100103   # 2a vez: origem = base_local
curl http://127.0.0.1:6001/historico
```

## App Flutter

### Passo a passo do zero

1. Instale o Flutter SDK (canal stable): https://docs.flutter.dev/get-started/install
2. Suba o backend primeiro (seção acima) — o app depende dele.
3. Instale as dependências e rode:

   ```bash
   cd app
   flutter pub get
   flutter run
   ```

   `flutter run` mostra a lista de dispositivos disponíveis (emulador Android,
   device físico conectado, etc.) para escolher onde rodar.

### Apontando o app para o backend certo (`BASE_URL`)

O endereço da API fica centralizado em `lib/config.dart`, como
`AppConfig.baseUrl`. O valor padrão é `http://10.0.2.2:6001` — esse IP é
especial, é como o **emulador Android** vê o `localhost` da máquina host.
Ou seja, se você está usando o emulador Android e o backend está rodando na
mesma máquina (venv ou Docker, tanto faz), não precisa mudar nada.

Para outros cenários, sobrescreva em tempo de execução com
`--dart-define`, sem editar código:

```bash
# device físico (celular) na mesma rede Wi-Fi da máquina que roda o backend:
# descubra o IP da máquina com `ip a` (Linux/WSL) ou `ipconfig` (Windows)
flutter run --dart-define=BASE_URL=http://192.168.15.5:6001

# iOS simulator ou app rodando na própria máquina (desktop/web):
flutter run --dart-define=BASE_URL=http://127.0.0.1:6001
```

Se preferir, também pode simplesmente editar o `defaultValue` em
`lib/config.dart`.

### Arquitetura e decisões

- **Gerenciamento de estado: Riverpod** (`flutter_riverpod`). Escolhido em vez
  do Provider simples porque o app precisa de um provider por código de barras
  (`FutureProvider.family<Produto, String>` em
  `lib/providers/app_providers.dart`) — cada tela de Resultado observa a nota
  do seu próprio código sem interferir em outras instâncias abertas, e dá pra
  invalidar/refazer a busca de um único produto (botão "tentar novamente") sem
  tocar no resto do estado do app. Isso é direto com `ref.invalidate` no
  Riverpod; com `Provider` (`ChangeNotifier`) teria que modelar esse
  "cache por chave" manualmente.
- **Camada de dados isolada**: nenhuma tela chama `http` diretamente.
  `lib/services/api_client.dart` fala com o backend, `cache_service.dart` fala
  com o `shared_preferences`, e `produto_repository.dart` combina os dois
  (busca na API → salva no cache → se a rede falhar, cai para o último
  resultado salvo daquele código). As telas só leem os providers.
- **Cache offline mínimo**: cada produto buscado com sucesso é salvo em
  `shared_preferences` por código de barras. Se uma consulta falhar por rede
  (sem internet, backend fora do ar), o app tenta mostrar o último resultado
  salvo daquele código, com um aviso na tela de que os dados podem estar
  desatualizados. Isso é independente do cache do próprio backend
  (`base_local` no SQLite) — são dois níveis de cache: um no servidor, um no
  aparelho.
- **3 estados de rede**: tanto a tela de Resultado quanto a de Histórico usam
  `AsyncValue.when(loading: ..., error: ..., data: ...)` do Riverpod para
  cobrir carregando/erro/sucesso. O caso HTTP 404 (`encontrado: false`) é
  tratado como uma exceção específica (`ProdutoNaoEncontradoException`), não
  como erro genérico, pra cair na tela de "produto não encontrado" em vez de
  numa tela de erro comum.
- **Organização**: `lib/config.dart`, `lib/models/`, `lib/services/`,
  `lib/providers/`, `lib/screens/`, `lib/widgets/`.

### Testes

```bash
flutter analyze   # deve terminar sem nenhum issue
flutter test      # testes de widget das telas de Resultado e Histórico
```

Os testes de widget usam um `ApiClient` falso (subclasse que sobrescreve
`buscarProduto`/`buscarHistorico`) injetado via `ProviderScope(overrides:
[...])`, sem precisar de um backend real rodando.

### Testando ponta a ponta com o app de verdade

Com o backend rodando (venv ou Docker) e `flutter run` de pé:

1. Abra o app — ele começa na tela de Scanner.
2. Aponte a câmera para o código de barras **7891000100103** (Leite Moça), ou
   digite esse número no campo manual e toque na lupa.
3. A tela de Resultado deve mostrar a nota, o "porquê" (critérios) e os
   selos de NOVA/Nutri-Score. `origem` vem `"openfoodfacts"` na primeira vez.
4. Volte pro Scanner e escaneie o mesmo código de novo: a resposta deve vir
   com `origem: "base_local"` (o backend não bateu no Open Food Facts de
   novo).
5. Toque no ícone de histórico (canto superior direito da tela de Scanner):
   o produto escaneado deve aparecer na lista, com nota e data.

### Sobre o Open Food Facts: User-Agent, cache e rate limit

O backend já se identifica ao OFF com um `User-Agent` próprio e cacheia cada
produto consultado por `CACHE_VALIDADE_DIAS` (7 dias por padrão) — isso já
evita martelar a API pública a cada scan repetido do mesmo produto (ver seção
do backend acima). Ainda assim, ao testar:

- Evite escanear muitos códigos diferentes em sequência rápida só para
  testar — cada código novo é uma chamada real ao OFF.
- O cache do dispositivo (`shared_preferences`) e o cache do backend
  (SQLite) são independentes; não martele o botão de "tentar novamente" — se
  a primeira falha foi por rede, provavelmente a segunda vai falhar do mesmo
  jeito no mesmo instante.

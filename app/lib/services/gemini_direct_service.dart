import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/produto.dart';
import 'api_exceptions.dart';
import 'nutricao_calculator.dart';

class GeminiDirectService {
  static const String _defaultApiKey = 'AIzaSyDTlyRRgfFXjpWMehOhHwghAtrZZ4Ki72g';
  final http.Client _client;

  GeminiDirectService({http.Client? client}) : _client = client ?? http.Client();

  Future<Produto> analisarFotoRotulo({
    required String caminhoArquivo,
    String? codigo,
    String? apiKey,
  }) async {
    final key = apiKey ?? _defaultApiKey;
    final bytes = await File(caminhoArquivo).readAsBytes();
    final imgB64 = base64Encode(bytes);

    const prompt = '''Analise esta imagem de alimento/rótulo brasileiro.
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

Importante: se a tabela tiver 3 colunas (100g, porção e %VD), extraia SEMPRE os valores por 100g.''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': imgB64,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'thinkingConfig': {'thinkingBudget': 0},
      }
    };

    http.Response resp;
    try {
      resp = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const ApiException('Tempo esgotado ao conectar com a Inteligência Artificial.');
    }

    if (resp.statusCode != 200) {
      throw ApiException('Falha no processamento da IA (HTTP ${resp.statusCode}).');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const ApiException('Não foi possível identificar dados nutricionais na imagem.');
    }

    var texto = candidates.first['content']['parts'][0]['text'] as String;
    texto = texto.trim();
    if (texto.startsWith('```')) {
      texto = texto.split('\n').skip(1).join('\n');
      if (texto.endsWith('```')) {
        texto = texto.substring(0, texto.length - 3).trim();
      }
    }

    final parsed = jsonDecode(texto) as Map<String, dynamic>;

    final aditivos = ((parsed['aditivos'] as List<dynamic>?) ?? [])
        .map((e) => e.toString().toUpperCase())
        .toList();

    final alergenos = ((parsed['alergenos'] as List<dynamic>?) ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    final nova = parsed['nova'] as int?;
    final nutrientes = {
      'acucar_100g': parsed['acucar_100g'],
      'gordura_saturada_100g': parsed['gordura_saturada_100g'],
      'sal_100g': parsed['sal_100g'],
      'fibra_100g': parsed['fibra_100g'],
      'proteina_100g': parsed['proteina_100g'],
    };

    final resultadoNota = NutricaoCalculator.calcularNota(
      nova: nova,
      nutrientes: nutrientes,
      aditivos: aditivos,
    );

    final codFinal = codigo ?? DateTime.now().millisecondsSinceEpoch.toString();

    return Produto(
      codigo: codFinal,
      nome: (parsed['nome'] as String?)?.isNotEmpty == true ? parsed['nome'] : 'Produto Identificado por IA',
      marca: parsed['marca'] ?? '',
      quantidade: parsed['quantidade'] ?? '',
      imagem: '',
      nota: resultadoNota.nota,
      classificacao: resultadoNota.classificacao,
      nova: nova ?? 0,
      nutriscore: 'desconhecido',
      ingredientes: parsed['ingredientes'] ?? '',
      alergenos: alergenos,
      aditivos: aditivos,
      criterios: resultadoNota.criterios,
      origem: 'ia_gemini',
      nutrientes: nutrientes,
    );
  }

  void dispose() => _client.close();
}

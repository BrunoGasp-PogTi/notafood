import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/historico_item.dart';
import '../models/produto.dart';
import 'api_exceptions.dart';

/// Camada de acesso à API do backend NotaFood. Nenhuma tela deve chamar
/// `http` diretamente — sempre passar por aqui.
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<Produto> buscarProduto(String codigo) async {
    final uri = Uri.parse('$baseUrl/produto/$codigo');
    final resposta = await _requisitar(uri);

    final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (resposta.statusCode == 404) {
      throw ProdutoNaoEncontradoException(
        codigo: codigo,
        mensagem: corpo['mensagem'] as String? ?? 'Produto não encontrado.',
      );
    }

    if (resposta.statusCode != 200) {
      throw ApiException('Erro ao consultar o produto (HTTP ${resposta.statusCode}).');
    }

    return Produto.fromJson(corpo);
  }

  Future<List<HistoricoItem>> buscarHistorico({int limite = 20}) async {
    final uri = Uri.parse('$baseUrl/historico?limite=$limite');
    final resposta = await _requisitar(uri);

    if (resposta.statusCode != 200) {
      throw ApiException('Erro ao consultar o histórico (HTTP ${resposta.statusCode}).');
    }

    final lista = jsonDecode(resposta.body) as List<dynamic>;
    return lista
        .map((item) => HistoricoItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Envia os dados que o usuário digitou/leu por OCR do rótulo, para um
  /// produto que não foi encontrado no Open Food Facts.
  Future<Produto> enviarProdutoManual(Map<String, dynamic> corpo) async {
    final uri = Uri.parse('$baseUrl/produto/manual');
    http.Response resposta;
    try {
      resposta = await _client
          .post(uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(corpo))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const ApiException('Não foi possível conectar ao servidor.');
    }

    if (resposta.statusCode != 200) {
      throw ApiException('Erro ao enviar o produto (HTTP ${resposta.statusCode}).');
    }

    return Produto.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }

  /// Envia a foto do rótulo/produto para o backend analisar via Gemini Vision.
  Future<Produto> analisarImagem({required String caminhoArquivo, String? codigo}) async {
    final uri = Uri.parse('$baseUrl/produto/analisar-imagem');
    final req = http.MultipartRequest('POST', uri);
    if (codigo != null && codigo.isNotEmpty) {
      req.fields['codigo'] = codigo;
    }
    req.files.add(await http.MultipartFile.fromPath('imagem', caminhoArquivo));

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await req.send().timeout(const Duration(seconds: 35));
    } catch (_) {
      throw const ApiException('Tempo esgotado ou erro de conexão com o servidor.');
    }

    final resposta = await http.Response.fromStream(streamedResponse);
    final corpo = jsonDecode(resposta.body) as Map<String, dynamic>?;

    if (resposta.statusCode != 200) {
      throw ApiException(corpo?['mensagem'] as String? ?? 'Erro ao analisar imagem por IA (HTTP ${resposta.statusCode}).');
    }

    return Produto.fromJson(corpo!);
  }

  Future<http.Response> _requisitar(Uri uri) async {
    try {
      return await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const ApiException('Não foi possível conectar ao servidor.');
    }
  }

  void dispose() => _client.close();
}

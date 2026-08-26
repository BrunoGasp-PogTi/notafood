import '../models/produto.dart';
import 'api_client.dart';
import 'api_exceptions.dart';
import 'cache_service.dart';
import 'gemini_direct_service.dart';
import 'open_food_facts_direct.dart';

/// Repositório híbrido: busca primeiro no cache do aparelho, depois no
/// Open Food Facts direto pela internet. Não depende de nenhum servidor local!
class ProdutoRepository {
  final CacheService cacheService;
  final OpenFoodFactsDirectService offService;
  final GeminiDirectService geminiService;
  final ApiClient? apiClient;

  ProdutoRepository({
    required this.cacheService,
    required this.offService,
    required this.geminiService,
    this.apiClient,
  });

  Future<Produto> buscarProduto(String codigo) async {
    // 1. Verifica cache local do dispositivo
    final doCache = await cacheService.buscarProduto(codigo);
    if (doCache != null) {
      return doCache.copyWith(origem: 'cache_dispositivo');
    }

    // 2. Consulta Open Food Facts diretamente pela internet (4G/5G/Wi-Fi)
    final prodOff = await offService.buscarProduto(codigo);
    if (prodOff != null) {
      await cacheService.salvarProduto(prodOff);
      return prodOff;
    }

    // 3. Fallback: Se houver backend configurado, tenta nele também
    if (apiClient != null) {
      try {
        final prodApi = await apiClient!.buscarProduto(codigo);
        await cacheService.salvarProduto(prodApi);
        return prodApi;
      } catch (_) {}
    }

    // 4. Produto não encontrado
    throw ProdutoNaoEncontradoException(
      codigo: codigo,
      mensagem: 'Produto ainda não cadastrado na base pública. Tire uma foto do rótulo para a IA calcular a nota!',
    );
  }

  Future<Produto> analisarFoto({required String caminhoArquivo, String? codigo}) async {
    final produto = await geminiService.analisarFotoRotulo(
      caminhoArquivo: caminhoArquivo,
      codigo: codigo,
    );
    await cacheService.salvarProduto(produto);
    return produto;
  }
}

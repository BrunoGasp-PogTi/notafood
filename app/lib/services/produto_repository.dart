import '../models/produto.dart';
import 'api_client.dart';
import 'api_exceptions.dart';
import 'cache_service.dart';
import 'gemini_direct_service.dart';
import 'open_food_facts_direct.dart';

/// Repositório inteligente e ultra-rápido:
/// 1. Consulta Open Food Facts direto pela internet (~1s).
/// 2. Se o Open Food Facts não tiver (404), consulta a API do Servidor que busca na WEB automaticamente!
/// 3. Se houver falha de conexão, consulta o cache do aparelho.
/// 4. Se não encontrar em nenhuma base, oferece foto do rótulo com IA.
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
    bool falhaDeRede = false;

    // 1. Tenta consulta direta no Open Food Facts (~1s)
    try {
      final prodOff = await offService.buscarProduto(codigo);
      if (prodOff != null) {
        await cacheService.salvarProduto(prodOff);
        return prodOff;
      }
    } catch (_) {
      falhaDeRede = true;
    }

    // 2. Se o Open Food Facts não tem o produto (404), o Servidor busca na Web automaticamente!
    if (apiClient != null) {
      try {
        final prodApi = await apiClient!.buscarProduto(codigo);
        await cacheService.salvarProduto(prodApi);
        return prodApi;
      } catch (e) {
        if (e is! ProdutoNaoEncontradoException) {
          falhaDeRede = true;
        }
      }
    }

    // 3. Em caso de perda total de sinal/rede, usa o cache local do dispositivo
    if (falhaDeRede) {
      final doCache = await cacheService.buscarProduto(codigo);
      if (doCache != null) {
        return doCache.copyWith(origem: 'cache_dispositivo');
      }
    }

    // 4. Produto não encontrado na base pública nem na web: tirar foto do rótulo
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

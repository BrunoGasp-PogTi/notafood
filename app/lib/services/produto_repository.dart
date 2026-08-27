import '../models/produto.dart';
import 'api_client.dart';
import 'api_exceptions.dart';
import 'cache_service.dart';
import 'gemini_direct_service.dart';
import 'open_food_facts_direct.dart';

/// Repositório híbrido e resiliente:
/// 1. Busca primeiro online (Open Food Facts direto pela internet 4G/5G/Wi-Fi).
/// 2. Se não encontrar, tenta a API do Backend.
/// 3. Se houver falha total de conexão, consulta o cache do aparelho (Modo Offline real).
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

    // 1. Tenta consulta ao vivo no Open Food Facts
    try {
      final prodOff = await offService.buscarProduto(codigo);
      if (prodOff != null) {
        await cacheService.salvarProduto(prodOff);
        return prodOff;
      }
    } catch (_) {
      falhaDeRede = true;
    }

    // 2. Se houver backend configurado, tenta nele também
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

    // 3. Se deu erro de rede, tenta recuperar do cache local do aparelho
    if (falhaDeRede) {
      final doCache = await cacheService.buscarProduto(codigo);
      if (doCache != null) {
        return doCache.copyWith(origem: 'cache_dispositivo');
      }
    }

    // 4. Produto não encontrado em nenhuma base
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

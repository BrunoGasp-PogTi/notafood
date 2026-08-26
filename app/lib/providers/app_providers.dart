import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../models/historico_item.dart';
import '../models/produto.dart';
import '../services/api_client.dart';
import '../services/cache_service.dart';
import '../services/gemini_direct_service.dart';
import '../services/open_food_facts_direct.dart';
import '../services/produto_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: AppConfig.baseUrl);
  ref.onDispose(client.dispose);
  return client;
});

final offDirectServiceProvider = Provider<OpenFoodFactsDirectService>((ref) {
  final service = OpenFoodFactsDirectService();
  ref.onDispose(service.dispose);
  return service;
});

final geminiDirectServiceProvider = Provider<GeminiDirectService>((ref) {
  final service = GeminiDirectService();
  ref.onDispose(service.dispose);
  return service;
});

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

final produtoRepositoryProvider = Provider<ProdutoRepository>((ref) {
  return ProdutoRepository(
    cacheService: ref.watch(cacheServiceProvider),
    offService: ref.watch(offDirectServiceProvider),
    geminiService: ref.watch(geminiDirectServiceProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

final produtoProvider = FutureProvider.family<Produto, String>((ref, codigo) {
  return ref.watch(produtoRepositoryProvider).buscarProduto(codigo);
});

final historicoProvider = FutureProvider<List<HistoricoItem>>((ref) {
  return ref.watch(cacheServiceProvider).listarHistorico();
});

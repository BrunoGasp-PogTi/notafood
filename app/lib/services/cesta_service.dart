import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/produto.dart';

final cestaComprasProvider =
    NotifierProvider<CestaComprasNotifier, List<Produto>>(
  CestaComprasNotifier.new,
);

class CestaComprasNotifier extends Notifier<List<Produto>> {
  @override
  List<Produto> build() => [];

  void adicionar(Produto produto) {
    if (!state.any((p) => p.codigo == produto.codigo)) {
      state = [...state, produto];
    }
  }

  void remover(String codigo) {
    state = state.where((p) => p.codigo != codigo).toList();
  }

  void limpar() {
    state = [];
  }

  int get scoreMedio {
    if (state.isEmpty) return 0;
    final total = state.map((p) => p.nota).reduce((a, b) => a + b);
    return total ~/ state.length;
  }
}

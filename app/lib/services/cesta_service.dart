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

  bool contem(String codigo) {
    return state.any((p) => p.codigo == codigo);
  }

  int get scoreMedio {
    if (state.isEmpty) return 0;
    final total = state.map((p) => p.nota).reduce((a, b) => a + b);
    return total ~/ state.length;
  }

  int get totalSaudaveis => state.where((p) => p.nota >= 75).length;
  int get totalModerados => state.where((p) => p.nota >= 50 && p.nota < 75).length;
  int get totalRuins => state.where((p) => p.nota < 50).length;

  List<String> get recomendacoes {
    if (state.isEmpty) return [];
    final recs = <String>[];
    final media = scoreMedio;

    final ultraprocessados = state.where((p) => p.nova == 4 || p.nota < 50).toList();
    final altosSodio = state.where((p) {
      final sal = (p.nutrientes['sal_100g'] as num?)?.toDouble();
      return sal != null && sal > 1.5;
    }).toList();
    final altosAcucar = state.where((p) {
      final acucar = (p.nutrientes['acucar_100g'] as num?)?.toDouble();
      return acucar != null && acucar > 15.0;
    }).toList();

    if (media >= 80) {
      recs.add('🎉 Excelente seleção de compras! Mais de 80% da sua cesta é de alimentos com alto valor nutricional.');
    } else if (media < 55) {
      recs.add('⚠️ Sua cesta atual contém uma concentração alta de ultraprocessados. Substituir alguns itens pode transformar a saúde da sua despensa.');
    }

    if (ultraprocessados.isNotEmpty) {
      final nomes = ultraprocessados.take(2).map((p) => p.nome).join(' e ');
      recs.add('💡 Troca inteligente: Você tem itens como $nomes. Confira a aba "Melhores Trocas" para alternativas saborosas e sem aditivos.');
    }

    if (altosSodio.length >= 2) {
      recs.add('🧂 Alerta de Sódio: Identificamos ${altosSodio.length} produtos com alto teor de sal. Cuidado especial se alguém na casa tiver hipertensão.');
    }

    if (altosAcucar.length >= 2) {
      recs.add('🍬 Alerta de Açúcar: ${altosAcucar.length} itens contêm alto índice de açúcar adicionado. Prefira versões integrais ou 100% fruta.');
    }

    if (recs.isEmpty) {
      recs.add('✅ Cesta equilibrada! Continue priorizando alimentos in natura e minimamente processados.');
    }

    return recs;
  }
}

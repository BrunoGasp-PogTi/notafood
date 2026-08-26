import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/produto.dart';

import '../models/historico_item.dart';

/// Guarda o histórico e cache de cada produto no dispositivo, funcionando
/// 100% autônomo e offline.
class CacheService {
  static const _prefixo = 'produto_cache_';
  static const _kCodigosHistorico = 'codigos_historico_lista';

  Future<void> salvarProduto(Produto produto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefixo${produto.codigo}',
      jsonEncode(produto.toJson()),
    );

    // Atualiza a lista de histórico (últimos 100 itens)
    final lista = prefs.getStringList(_kCodigosHistorico) ?? [];
    lista.remove(produto.codigo);
    lista.insert(0, produto.codigo);
    if (lista.length > 100) {
      lista.removeLast();
    }
    await prefs.setStringList(_kCodigosHistorico, lista);
  }

  Future<Produto?> buscarProduto(String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString('$_prefixo$codigo');
    if (bruto == null) return null;
    return Produto.fromJson(jsonDecode(bruto) as Map<String, dynamic>);
  }

  Future<List<HistoricoItem>> listarHistorico({int limite = 50}) async {
    final prefs = await SharedPreferences.getInstance();
    final codigos = prefs.getStringList(_kCodigosHistorico) ?? [];
    final itens = <HistoricoItem>[];

    for (final codigo in codigos.take(limite)) {
      final bruto = prefs.getString('$_prefixo$codigo');
      if (bruto != null) {
        try {
          final p = Produto.fromJson(jsonDecode(bruto) as Map<String, dynamic>);
          itens.add(
            HistoricoItem(
              codigo: p.codigo,
              nome: p.nome,
              nota: p.nota,
              classificacao: p.classificacao,
              ultimaConsulta: DateTime.now(),
            ),
          );
        } catch (_) {}
      }
    }
    return itens;
  }
}

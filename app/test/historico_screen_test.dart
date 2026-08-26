import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notafood/models/historico_item.dart';
import 'package:notafood/models/produto.dart';
import 'package:notafood/providers/app_providers.dart';
import 'package:notafood/screens/historico_screen.dart';
import 'package:notafood/services/api_client.dart';

class _ApiClientComHistorico extends ApiClient {
  _ApiClientComHistorico() : super(baseUrl: 'http://fake');

  @override
  Future<List<HistoricoItem>> buscarHistorico({int limite = 20}) async {
    return [
      HistoricoItem(
        codigo: '111',
        nome: 'Produto do Histórico',
        nota: 62,
        classificacao: 'moderado',
        ultimaConsulta: DateTime(2026, 8, 4, 10, 30),
      ),
    ];
  }

  @override
  Future<Produto> buscarProduto(String codigo) => throw UnimplementedError();
}

void main() {
  testWidgets('mostra os itens do histórico com nota e data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_ApiClientComHistorico())],
        child: const MaterialApp(home: HistoricoScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Produto do Histórico'), findsOneWidget);
    expect(find.text('62'), findsOneWidget);
    expect(find.text('04/08/2026 às 10:30'), findsOneWidget);
  });
}

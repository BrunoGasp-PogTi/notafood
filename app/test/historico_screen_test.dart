import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notafood/models/historico_item.dart';
import 'package:notafood/providers/app_providers.dart';
import 'package:notafood/screens/historico_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('mostra os itens do histórico com nota e nome', (tester) async {
    final itensMock = [
      HistoricoItem(
        codigo: '111',
        nome: 'Produto do Histórico',
        nota: 62,
        classificacao: 'moderado',
        ultimaConsulta: DateTime(2026, 8, 4, 10, 30),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historicoProvider.overrideWith((ref) => Future.value(itensMock)),
        ],
        child: const MaterialApp(home: HistoricoScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Produto do Histórico'), findsOneWidget);
    expect(find.text('62'), findsWidgets);
    expect(find.text('MODERADO'), findsOneWidget);
  });
}

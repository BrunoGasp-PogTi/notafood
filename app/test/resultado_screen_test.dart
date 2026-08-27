import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notafood/models/criterio.dart';
import 'package:notafood/models/produto.dart';
import 'package:notafood/providers/app_providers.dart';
import 'package:notafood/screens/resultado_screen.dart';
import 'package:notafood/services/api_exceptions.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('mostra nota, nome e critérios em caso de sucesso', (tester) async {
    final produtoMock = Produto(
      codigo: '123',
      origem: 'openfoodfacts',
      nome: 'Produto Teste',
      marca: 'Marca Teste',
      quantidade: '100 g',
      imagem: '',
      nota: 80,
      classificacao: 'bom',
      nova: 1,
      nutriscore: 'a',
      ingredientes: 'ingrediente teste',
      alergenos: const [],
      aditivos: const [],
      criterios: const [Criterio(item: 'critério de teste', efeito: '+10 pts')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          produtoProvider('123').overrideWith((ref) => Future.value(produtoMock)),
        ],
        child: const MaterialApp(home: ResultadoScreen(codigo: '123')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('80'), findsWidgets);
    expect(find.text('Produto Teste'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('critério de teste'), 200);
    expect(find.text('critério de teste'), findsOneWidget);
    expect(find.text('+10 pts'), findsOneWidget);
  });

  testWidgets('mostra tela de não cadastrado quando o produto não existe', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          produtoProvider('000').overrideWith(
            (ref) => Future.error(
              ProdutoNaoEncontradoException(
                codigo: '000',
                mensagem: 'Produto não cadastrado.',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ResultadoScreen(codigo: '000')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Produto não cadastrado'), findsOneWidget);
    expect(find.text('Ver no Open Food Facts'), findsOneWidget);
  });
}

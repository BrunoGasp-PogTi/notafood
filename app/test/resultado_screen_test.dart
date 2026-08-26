import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notafood/models/criterio.dart';
import 'package:notafood/models/historico_item.dart';
import 'package:notafood/models/produto.dart';
import 'package:notafood/providers/app_providers.dart';
import 'package:notafood/screens/resultado_screen.dart';
import 'package:notafood/services/api_client.dart';
import 'package:notafood/services/api_exceptions.dart';

class _ApiClientSucesso extends ApiClient {
  _ApiClientSucesso() : super(baseUrl: 'http://fake');

  @override
  Future<Produto> buscarProduto(String codigo) async {
    return Produto(
      codigo: codigo,
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
  }

  @override
  Future<List<HistoricoItem>> buscarHistorico({int limite = 20}) async => const [];
}

class _ApiClientNaoEncontrado extends ApiClient {
  _ApiClientNaoEncontrado() : super(baseUrl: 'http://fake');

  @override
  Future<Produto> buscarProduto(String codigo) {
    throw ProdutoNaoEncontradoException(
      codigo: codigo,
      mensagem: 'Produto não encontrado na base do Open Food Facts.',
    );
  }

  @override
  Future<List<HistoricoItem>> buscarHistorico({int limite = 20}) async => const [];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('mostra nota, nome e critérios em caso de sucesso', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_ApiClientSucesso())],
        child: const MaterialApp(home: ResultadoScreen(codigo: '123')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('80'), findsOneWidget);
    expect(find.text('Produto Teste'), findsOneWidget);
    expect(find.text('critério de teste'), findsOneWidget);
    expect(find.text('+10 pts'), findsOneWidget);
  });

  testWidgets('mostra tela de não encontrado com CTA para o OFF', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_ApiClientNaoEncontrado())],
        child: const MaterialApp(home: ResultadoScreen(codigo: '000')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Produto não encontrado'), findsOneWidget);
    expect(find.text('Contribuir no Open Food Facts'), findsOneWidget);
  });
}

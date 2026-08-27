import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notafood/models/criterio.dart';
import 'package:notafood/models/produto.dart';
import 'package:notafood/providers/app_providers.dart';
import 'package:notafood/screens/cesta_compras_screen.dart';
import 'package:notafood/screens/resultado_screen.dart';
import 'package:notafood/services/cesta_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final prodA = Produto(
    codigo: '7891000100103',
    origem: 'openfoodfacts',
    nome: 'Batata Ruffles Original',
    marca: 'Elma Chips',
    quantidade: '167g',
    imagem: 'https://images.openfoodfacts.org/images/products/789/100/010/0103/front_pt.4.400.jpg',
    nota: 45,
    classificacao: 'ruim',
    nova: 4,
    nutriscore: 'e',
    ingredientes: 'Batata, óleo vegetal e sal',
    alergenos: const [],
    aditivos: const [],
    criterios: const [Criterio(item: 'Alimento Ultraprocessado (NOVA 4)', efeito: '-35 pts')],
    nutrientes: const {
      'gordura_saturada_100g': 8.0,
      'sal_100g': 1.8,
    },
  );

  final prodB = Produto(
    codigo: '7891515634186',
    origem: 'openfoodfacts',
    nome: 'Hambúrguer Bovino',
    marca: 'Perdigão',
    quantidade: '670g',
    imagem: 'https://images.openfoodfacts.org/images/products/789/151/563/4186/front_pt.6.400.jpg',
    nota: 40,
    classificacao: 'ruim',
    nova: 4,
    nutriscore: 'd',
    ingredientes: 'Carne bovina, gordura bovina, água, sal e conservantes',
    alergenos: const [],
    aditivos: const ['E250'],
    criterios: const [Criterio(item: 'Alimento Ultraprocessado (NOVA 4)', efeito: '-35 pts')],
    nutrientes: const {
      'gordura_saturada_100g': 7.5,
      'sal_100g': 1.9,
    },
  );

  testWidgets('Simulação Completa: Adição à Cesta, Imagens e Recomendações', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        produtoProvider('7891000100103').overrideWith((ref) => Future.value(prodA)),
        produtoProvider('7891515634186').overrideWith((ref) => Future.value(prodB)),
      ],
    );

    // 1. Adiciona Produto A e Produto B diretamente na Cesta
    final cestaNotifier = container.read(cestaComprasProvider.notifier);
    cestaNotifier.adicionar(prodA);
    cestaNotifier.adicionar(prodB);

    // 2. Renderiza a Tela CestaComprasScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CestaComprasScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 3. Valida se os dois produtos estão visíveis com nome, nota e marca
    expect(find.text('Batata Ruffles Original'), findsOneWidget);
    expect(find.text('Hambúrguer Bovino'), findsOneWidget);
    expect(find.text('Elma Chips'), findsOneWidget);
    expect(find.text('Perdigão'), findsOneWidget);

    // 4. Valida a nota média calculada (45 + 40) / 2 = 42
    expect(find.text('42'), findsOneWidget);
    expect(find.text('2 produto(s) no carrinho'), findsOneWidget);
    expect(find.text('2 A Evitar'), findsOneWidget);

    // 5. Valida se as recomendações inteligentes foram geradas
    expect(find.text('Recomendações para sua Compra'), findsOneWidget);
    expect(find.textContaining('Alerta de Sódio'), findsOneWidget);

    // 6. Remove um produto da cesta e valida atualização instantânea
    cestaNotifier.remover(prodA.codigo);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Batata Ruffles Original'), findsNothing);
    expect(find.text('Hambúrguer Bovino'), findsOneWidget);
    expect(find.text('40'), findsWidgets); // Score médio agora é 40
  });

  testWidgets('ResultadoConteudo renderiza header unificado e Melhores Trocas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ResultadoConteudo(
              produto: prodA,
              header: const Text('Header do Peek de Teste'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Header do Peek de Teste'), findsOneWidget);
    expect(find.text('Batata Ruffles Original'), findsOneWidget);
    expect(find.text('Melhores Trocas'), findsOneWidget);
  });
}

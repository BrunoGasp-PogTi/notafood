import 'package:flutter_test/flutter_test.dart';
import 'package:notafood/services/rotulo_parser.dart';

void main() {
  group('analisarIngredientes', () {
    test('extrai códigos de aditivo em formato E e INS', () {
      final resultado = analisarIngredientes(
        'farinha de trigo, açúcar, INS 330, conservante E 211, corante E102',
      );
      expect(resultado.aditivos, containsAll(['E330', 'E211', 'E102']));
    });

    test('identifica alérgenos declarados e ignora os negados', () {
      final resultado = analisarIngredientes(
        'Contém glúten e leite. Não contém amendoim. Pode conter traços de soja.',
      );
      expect(resultado.alergenos, containsAll(['gluten', 'milk', 'soy']));
      expect(resultado.alergenos, isNot(contains('peanuts')));
    });
  });

  group('analisarTabelaNutricional', () {
    test('lê porção e valores de uma tabela em formato comum', () {
      const texto = '''
        INFORMAÇÃO NUTRICIONAL
        Porção de 30 g
        Valor energético 150 kcal
        Carboidratos 20 g
        Açúcares totais 12 g
        Proteínas 2 g
        Gorduras totais 5 g
        Gorduras saturadas 2 g
        Fibra alimentar 1 g
        Sódio 100 mg
      ''';

      final valores = analisarTabelaNutricional(texto);

      expect(valores.porcaoG, 30);
      expect(valores.acucarPorcao, 12);
      expect(valores.gorduraSaturadaPorcao, 2);
      expect(valores.sodioMgPorcao, 100);
      expect(valores.fibraPorcao, 1);
      expect(valores.proteinaPorcao, 2);
    });

    test('não confunde açúcares adicionados com açúcares totais', () {
      const texto = '''
        Porção de 50 g
        Açúcares totais 8 g
        Açúcares adicionados 5 g
      ''';

      final valores = analisarTabelaNutricional(texto);
      expect(valores.acucarPorcao, 8);
    });
  });

  group('normalizarPara100g', () {
    test('converte valores por porção para por 100g, incluindo sódio em sal', () {
      const valores = ValoresRotulo(
        porcaoG: 30,
        acucarPorcao: 12,
        gorduraSaturadaPorcao: 3,
        sodioMgPorcao: 120,
        fibraPorcao: 1.5,
        proteinaPorcao: 2,
      );

      final normalizado = normalizarPara100g(valores);

      expect(normalizado.acucar100g, closeTo(40, 0.01));
      expect(normalizado.gorduraSaturada100g, closeTo(10, 0.01));
      // 120mg de sódio -> 0.12g -> *2.5 = 0.3g de sal por porção -> *(100/30)
      expect(normalizado.sal100g, closeTo(1.0, 0.01));
      expect(normalizado.fibra100g, closeTo(5, 0.01));
      expect(normalizado.proteina100g, closeTo(6.67, 0.01));
    });

    test('sem porção informada, não normaliza nada', () {
      const valores = ValoresRotulo(acucarPorcao: 12);
      final normalizado = normalizarPara100g(valores);
      expect(normalizado.acucar100g, isNull);
    });
  });
}

import '../models/criterio.dart';

class ResultadoCalculoNota {
  final int nota;
  final String classificacao;
  final List<Criterio> criterios;

  const ResultadoCalculoNota({
    required this.nota,
    required this.classificacao,
    required this.criterios,
  });
}

class NutricaoCalculator {
  static const Map<int, int> penalidadeNova = {
    1: 0,
    2: -5,
    3: -15,
    4: -35,
  };

  static const Map<int, String> descricaoNova = {
    1: "alimento in natura ou minimamente processado",
    2: "ingrediente culinário processado",
    3: "alimento processado",
    4: "alimento ultraprocessado",
  };

  static const Set<String> aditivosPreocupantes = {
    "E102", "E110", "E122", "E124", "E129",
    "E211", "E250", "E251",
    "E621",
    "E951",
  };

  /// Infere a classificação NOVA quando a base de dados pública não informou.
  static int inferirNova({
    required String nome,
    required String ingredientes,
    List<String> categorias = const [],
  }) {
    final texto = '$nome $ingredientes ${categorias.join(' ')}'.toLowerCase();

    // 1. Ultraprocessados evidentes
    if (texto.contains('chips') ||
        texto.contains('batata frita') ||
        texto.contains('ruffles') ||
        texto.contains('doritos') ||
        texto.contains('cheetos') ||
        texto.contains('lays') ||
        texto.contains('lay\'s') ||
        texto.contains('pringles') ||
        texto.contains('salgadinho') ||
        texto.contains('snack') ||
        texto.contains('refrigerante') ||
        texto.contains('coca-cola') ||
        texto.contains('coca cola') ||
        texto.contains('pepsi') ||
        texto.contains('fanta') ||
        texto.contains('guaraná') ||
        texto.contains('sprite') ||
        texto.contains('biscoito') ||
        texto.contains('bolacha') ||
        texto.contains('recheado') ||
        texto.contains('wafer') ||
        texto.contains('oreo') ||
        texto.contains('passatempo') ||
        texto.contains('empanado') ||
        texto.contains('nugget') ||
        texto.contains('salsicha') ||
        texto.contains('linguiça') ||
        texto.contains('mortadela') ||
        texto.contains('presunto') ||
        texto.contains('miojo') ||
        texto.contains('macarrão instantâneo') ||
        texto.contains('achocolatado') ||
        texto.contains('energético') ||
        texto.contains('red bull') ||
        texto.contains('monster') ||
        texto.contains('sorvete') ||
        texto.contains('margarina') ||
        texto.contains('bala') ||
        texto.contains('pirulito') ||
        texto.contains('goma de mascar') ||
        texto.contains('gordura vegetal hidrogenada') ||
        texto.contains('gordura hidrogenada') ||
        texto.contains('aromatizante') ||
        texto.contains('realçador de sabor') ||
        texto.contains('glutamato monossódico') ||
        texto.contains('maltodextrina')) {
      return 4;
    }

    // 2. Processados
    if (texto.contains('conserva') ||
        texto.contains('atum em óleo') ||
        texto.contains('sardinha') ||
        texto.contains('queijo') ||
        texto.contains('pão artesanal') ||
        texto.contains('pão francês')) {
      return 3;
    }

    // 3. Ingredientes Culinários
    if (texto.contains('azeite') ||
        texto.contains('óleo') ||
        texto.contains('manteiga') ||
        texto.contains('açúcar') ||
        texto.contains('sal refinado') ||
        texto.contains('farinha')) {
      return 2;
    }

    // 4. In Natura / Minimamente processado
    if (texto.contains('fruta') ||
        texto.contains('legume') ||
        texto.contains('verdura') ||
        texto.contains('arroz') ||
        texto.contains('feijão') ||
        texto.contains('ovo') ||
        texto.contains('leite integral') ||
        texto.contains('água')) {
      return 1;
    }

    return 0;
  }

  static ResultadoCalculoNota calcularNota({
    required int? nova,
    required Map<String, dynamic> nutrientes,
    required List<String> aditivos,
    String nomeProduto = '',
    String ingredientes = '',
  }) {
    int pontos = 100;
    final criterios = <Criterio>[];

    // Se NOVA não veio cadastrada, tenta inferir
    int novaFinal = nova ?? 0;
    if (novaFinal == 0 && (nomeProduto.isNotEmpty || ingredientes.isNotEmpty)) {
      novaFinal = inferirNova(nome: nomeProduto, ingredientes: ingredientes);
    }

    // 1. Penalidade NOVA
    if (novaFinal > 0 && penalidadeNova.containsKey(novaFinal)) {
      final efeito = penalidadeNova[novaFinal]!;
      pontos += efeito;
      final sinal = efeito >= 0 ? "+" : "";
      final sufixo = (nova == null || nova == 0) ? " (identificado pelo tipo)" : "";
      criterios.add(
        Criterio(
          item: "Classificação NOVA $novaFinal (${descricaoNova[novaFinal]})$sufixo",
          efeito: "$sinal$efeito pts",
        ),
      );
    } else {
      criterios.add(
        const Criterio(
          item: "Classificação NOVA não informada",
          efeito: "0 pts",
        ),
      );
    }

    final acucar = (nutrientes['acucar_100g'] as num?)?.toDouble();
    final gorduraSat = (nutrientes['gordura_saturada_100g'] as num?)?.toDouble();
    final sal = (nutrientes['sal_100g'] as num?)?.toDouble();
    final fibra = (nutrientes['fibra_100g'] as num?)?.toDouble();
    final proteina = (nutrientes['proteina_100g'] as num?)?.toDouble();

    final bool semTabelaNutricional = (acucar == null && gorduraSat == null && sal == null);

    // Se a base pública não cadastrou a tabela nutricional:
    if (semTabelaNutricional) {
      final nomeLower = nomeProduto.toLowerCase();
      if (nomeLower.contains('refrigerante') ||
          nomeLower.contains('coca') ||
          nomeLower.contains('pepsi') ||
          nomeLower.contains('fanta') ||
          nomeLower.contains('guaraná') ||
          nomeLower.contains('sprite') ||
          nomeLower.contains('soda')) {
        // Refrigerantes regulares: muito alto em açúcar
        pontos -= 25; // Total vai para 40 pts
        criterios.add(
          const Criterio(
            item: "Estimativa de refrigerante: alto teor de açúcar adicionado",
            efeito: "-25 pts",
          ),
        );
      } else if (nomeLower.contains('chips') ||
          nomeLower.contains('ruffles') ||
          nomeLower.contains('salgadinho') ||
          nomeLower.contains('batata frita') ||
          nomeLower.contains('doritos') ||
          nomeLower.contains('cheetos') ||
          nomeLower.contains('lays') ||
          nomeLower.contains('snack')) {
        // Salgadinhos/Chips: alto em gordura saturada e sódio
        pontos -= 35; // Total vai para 30 pts
        criterios.add(
          const Criterio(
            item: "Estimativa de salgadinho/chips: alto teor de gorduras saturadas e sódio",
            efeito: "-35 pts",
          ),
        );
      } else if (nomeLower.contains('biscoito') ||
          nomeLower.contains('bolacha') ||
          nomeLower.contains('doce') ||
          nomeLower.contains('chocolate') ||
          nomeLower.contains('wafer') ||
          nomeLower.contains('recheado') ||
          nomeLower.contains('bala')) {
        // Biscoitos/Doces
        pontos -= 25;
        criterios.add(
          const Criterio(
            item: "Estimativa de confeitaria/biscoito: açúcares e gorduras",
            efeito: "-25 pts",
          ),
        );
      } else if (novaFinal == 4) {
        pontos -= 20;
        criterios.add(
          const Criterio(
            item: "Alimento ultraprocessado (tabela nutricional não informada na base pública)",
            efeito: "-20 pts",
          ),
        );
      } else if (novaFinal == 0) {
        // Produto sem nenhuma informação de nutrientes e sem NOVA: base neutra
        pontos = 50;
        criterios.add(
          const Criterio(
            item: "Tabela nutricional ausente na base pública (tire foto do rótulo para precisão)",
            efeito: "Base neutra",
          ),
        );
      }
    } else {
      // 2. Açúcares
      if (acucar != null) {
        if (acucar > 22.5) {
          pontos -= 15;
          criterios.add(
            Criterio(
              item: "Muito alto teor de açúcar (${acucar.toStringAsFixed(1)}g/100g)",
              efeito: "-15 pts",
            ),
          );
        } else if (acucar > 12.5) {
          pontos -= 8;
          criterios.add(
            Criterio(
              item: "Alto teor de açúcar (${acucar.toStringAsFixed(1)}g/100g)",
              efeito: "-8 pts",
            ),
          );
        } else if (acucar <= 5.0) {
          criterios.add(
            Criterio(
              item: "Baixo teor de açúcar (${acucar.toStringAsFixed(1)}g/100g)",
              efeito: "+0 pts",
            ),
          );
        }
      }

      // 3. Gordura Saturada
      if (gorduraSat != null) {
        if (gorduraSat > 5.0) {
          pontos -= 10;
          criterios.add(
            Criterio(
              item: "Alto teor de gordura saturada (${gorduraSat.toStringAsFixed(1)}g/100g)",
              efeito: "-10 pts",
            ),
          );
        } else if (gorduraSat <= 1.5) {
          criterios.add(
            Criterio(
              item: "Baixo teor de gordura saturada (${gorduraSat.toStringAsFixed(1)}g/100g)",
              efeito: "+0 pts",
            ),
          );
        }
      }

      // 4. Sal / Sódio
      if (sal != null) {
        if (sal > 1.5) {
          pontos -= 10;
          criterios.add(
            Criterio(
              item: "Alto teor de sal (${sal.toStringAsFixed(2)}g/100g)",
              efeito: "-10 pts",
            ),
          );
        } else if (sal <= 0.3) {
          criterios.add(
            Criterio(
              item: "Baixo teor de sódio (${sal.toStringAsFixed(2)}g de sal/100g)",
              efeito: "+0 pts",
            ),
          );
        }
      }

      // 5. Fibras
      if (fibra != null && fibra >= 3.0) {
        pontos += 5;
        criterios.add(
          Criterio(
            item: "Fonte de fibras (${fibra.toStringAsFixed(1)}g/100g)",
            efeito: "+5 pts",
          ),
        );
      }

      // 6. Proteínas
      if (proteina != null && proteina >= 8.0) {
        pontos += 5;
        criterios.add(
          Criterio(
            item: "Rico em proteínas (${proteina.toStringAsFixed(1)}g/100g)",
            efeito: "+5 pts",
          ),
        );
      }
    }

    // 7. Aditivos Químicos
    if (aditivos.isNotEmpty) {
      final penalidadeAditivos = -2 * aditivos.length;
      pontos += penalidadeAditivos;
      criterios.add(
        Criterio(
          item: "${aditivos.length} aditivo(s) identificado(s)",
          efeito: "$penalidadeAditivos pts",
        ),
      );

      final perigosos = aditivos
          .where((a) => aditivosPreocupantes.contains(a.toUpperCase()))
          .toList();
      if (perigosos.isNotEmpty) {
        final penExtra = -5 * perigosos.length;
        pontos += penExtra;
        criterios.add(
          Criterio(
            item: "Aditivo(s) com alerta de saúde: ${perigosos.join(', ')}",
            efeito: "$penExtra pts",
          ),
        );
      }
    } else if (!semTabelaNutricional) {
      criterios.add(
        const Criterio(
          item: "Sem aditivos químicos identificados",
          efeito: "+0 pts",
        ),
      );
    }

    pontos = pontos.clamp(0, 100);

    String classificacao;
    if (pontos >= 75) {
      classificacao = "bom";
    } else if (pontos >= 50) {
      classificacao = "moderado";
    } else {
      classificacao = "ruim";
    }

    return ResultadoCalculoNota(
      nota: pontos,
      classificacao: classificacao,
      criterios: criterios,
    );
  }
}

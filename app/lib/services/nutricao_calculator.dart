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

  static ResultadoCalculoNota calcularNota({
    required int? nova,
    required Map<String, dynamic> nutrientes,
    required List<String> aditivos,
  }) {
    int pontos = 100;
    final criterios = <Criterio>[];

    // 1. Penalidade NOVA
    if (nova != null && penalidadeNova.containsKey(nova)) {
      final efeito = penalidadeNova[nova]!;
      pontos += efeito;
      final sinal = efeito >= 0 ? "+" : "";
      criterios.add(
        Criterio(
          item: "Classificação NOVA $nova (${descricaoNova[nova]})",
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

    // 2. Açúcares
    final acucar = (nutrientes['acucar_100g'] as num?)?.toDouble();
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
    final gorduraSat = (nutrientes['gordura_saturada_100g'] as num?)?.toDouble();
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
    final sal = (nutrientes['sal_100g'] as num?)?.toDouble();
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
    final fibra = (nutrientes['fibra_100g'] as num?)?.toDouble();
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
    final proteina = (nutrientes['proteina_100g'] as num?)?.toDouble();
    if (proteina != null && proteina >= 8.0) {
      pontos += 5;
      criterios.add(
        Criterio(
          item: "Rico em proteínas (${proteina.toStringAsFixed(1)}g/100g)",
          efeito: "+5 pts",
        ),
      );
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
    } else {
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

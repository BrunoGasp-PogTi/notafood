/// Interpreta o texto reconhecido por OCR nas fotos do rótulo. É um
/// best-effort: os resultados sempre passam por uma tela de revisão onde o
/// usuário confirma ou corrige antes de calcular a nota.
library;

class ResultadoOcrIngredientes {
  final String textoIngredientes;
  final List<String> aditivos;
  final List<String> alergenos;

  const ResultadoOcrIngredientes({
    required this.textoIngredientes,
    required this.aditivos,
    required this.alergenos,
  });
}

/// Valores lidos do rótulo tal como impressos (por porção, nas unidades da
/// própria tabela) — ainda não normalizados para 100g.
class ValoresRotulo {
  final double? porcaoG;
  final double? acucarPorcao;
  final double? gorduraSaturadaPorcao;
  final double? sodioMgPorcao;
  final double? fibraPorcao;
  final double? proteinaPorcao;

  const ValoresRotulo({
    this.porcaoG,
    this.acucarPorcao,
    this.gorduraSaturadaPorcao,
    this.sodioMgPorcao,
    this.fibraPorcao,
    this.proteinaPorcao,
  });
}

/// Valores já normalizados para 100g, prontos para enviar ao backend (mesma
/// unidade que o Open Food Facts usa).
class NutrientesPor100g {
  final double? acucar100g;
  final double? gorduraSaturada100g;
  final double? sal100g;
  final double? fibra100g;
  final double? proteina100g;

  const NutrientesPor100g({
    this.acucar100g,
    this.gorduraSaturada100g,
    this.sal100g,
    this.fibra100g,
    this.proteina100g,
  });
}

const _aditivosRegex = r'(?:E|INS)[\s\-]?(\d{3,4})\s?([a-zA-Z])?\b';

final _alergenosConhecidos = <String, RegExp>{
  'gluten': RegExp(r'gl[uú]ten', caseSensitive: false),
  'milk': RegExp(r'\bleite\b', caseSensitive: false),
  'soy': RegExp(r'\bsoja\b', caseSensitive: false),
  'wheat': RegExp(r'\btrigo\b', caseSensitive: false),
  'eggs': RegExp(r'\bovos?\b', caseSensitive: false),
  'peanuts': RegExp(r'amendoim', caseSensitive: false),
  'nuts': RegExp(r'castanha|am[eê]ndoa|\bnoz(es)?\b', caseSensitive: false),
  'fish': RegExp(r'\bpeixe', caseSensitive: false),
  'crustaceans': RegExp(r'crust[aá]ceo|frutos do mar', caseSensitive: false),
};

/// Extrai aditivos (códigos E/INS) e alérgenos do texto de ingredientes.
/// Alérgenos citados numa frase com "não contém"/"não possui" são ignorados.
ResultadoOcrIngredientes analisarIngredientes(String textoOcr) {
  final aditivos = <String>{};
  for (final m in RegExp(_aditivosRegex, caseSensitive: false).allMatches(textoOcr)) {
    final numero = m.group(1)!;
    final letra = m.group(2) ?? '';
    aditivos.add('E$numero$letra'.toUpperCase());
  }

  final alergenos = <String>{};
  for (final segmento in textoOcr.split(RegExp(r'[.;\n]'))) {
    final baixo = segmento.toLowerCase();
    final negado = baixo.contains('não cont') ||
        baixo.contains('nao cont') ||
        baixo.contains('não possui') ||
        baixo.contains('nao possui');
    if (negado) continue;
    for (final entrada in _alergenosConhecidos.entries) {
      if (entrada.value.hasMatch(baixo)) {
        alergenos.add(entrada.key);
      }
    }
  }

  return ResultadoOcrIngredientes(
    textoIngredientes: textoOcr.replaceAll(RegExp(r'\s+'), ' ').trim(),
    aditivos: aditivos.toList()..sort(),
    alergenos: alergenos.toList()..sort(),
  );
}

double? _valorApos(String texto, String padraoRotulo) {
  final m = RegExp('$padraoRotulo[^\\d]{0,25}(\\d+[.,]?\\d*)', caseSensitive: false)
      .firstMatch(texto);
  if (m == null) return null;
  return double.tryParse(m.group(1)!.replaceAll(',', '.'));
}

/// Tenta achar a porção e os valores nutricionais no texto da tabela.
/// Layouts variam bastante entre marcas — por isso a tela de revisão sempre
/// deixa esses campos editáveis.
ValoresRotulo analisarTabelaNutricional(String textoOcr) {
  final porcao = _valorApos(textoOcr, r'por[çc][ãa]o\s*(?:de)?');

  var acucar = _valorApos(textoOcr, r'a[çc][uú]cares?\s+totais');
  acucar ??= _valorApos(textoOcr, r'a[çc][uú]cares?(?!\s+adicionados)');

  return ValoresRotulo(
    porcaoG: porcao,
    acucarPorcao: acucar,
    gorduraSaturadaPorcao: _valorApos(textoOcr, r'gorduras?\s+saturadas?'),
    sodioMgPorcao: _valorApos(textoOcr, r's[oó]dio'),
    fibraPorcao: _valorApos(textoOcr, r'fibra\s+aliment(?:ar)?'),
    proteinaPorcao: _valorApos(textoOcr, r'prote[íi]nas?'),
  );
}

/// Converte os valores "por porção" para "por 100g/100ml" — mesma base do
/// Open Food Facts — usando o tamanho da porção informado. Sódio (mg) é
/// convertido para sal (g) multiplicando por 2,5, que é a mesma equivalência
/// usada pelos rótulos e pelo próprio Open Food Facts.
NutrientesPor100g normalizarPara100g(ValoresRotulo valores) {
  final porcao = valores.porcaoG;
  if (porcao == null || porcao <= 0) {
    return const NutrientesPor100g();
  }

  final fator = 100 / porcao;
  double? converter(double? valor) => valor == null ? null : valor * fator;

  return NutrientesPor100g(
    acucar100g: converter(valores.acucarPorcao),
    gorduraSaturada100g: converter(valores.gorduraSaturadaPorcao),
    sal100g: valores.sodioMgPorcao == null ? null : (valores.sodioMgPorcao! / 1000 * 2.5) * fator,
    fibra100g: converter(valores.fibraPorcao),
    proteina100g: converter(valores.proteinaPorcao),
  );
}

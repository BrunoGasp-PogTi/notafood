class AlternativaSaudavel {
  final String nome;
  final String categoria;
  final int nota;
  final int nova;
  final String motivo;
  final String? marcaExemplo;

  const AlternativaSaudavel({
    required this.nome,
    required this.categoria,
    required this.nota,
    required this.nova,
    required this.motivo,
    this.marcaExemplo,
  });
}

class AlternativasService {
  static const Map<String, List<AlternativaSaudavel>> _catalogo = {
    'refrigerante': [
      AlternativaSaudavel(
        nome: 'Água com gás + Limão espremido',
        categoria: 'Bebidas',
        nota: 100,
        nova: 1,
        motivo: 'Zero açúcares adicionados e hidratação pura.',
      ),
      AlternativaSaudavel(
        nome: 'Suco de Uva Integral 100%',
        categoria: 'Bebidas',
        nota: 88,
        nova: 1,
        motivo: 'Rico em antioxidantes naturais, sem adição de açúcar.',
      ),
      AlternativaSaudavel(
        nome: 'Kombucha de Frutas Vermelhas',
        categoria: 'Bebidas',
        nota: 85,
        nova: 2,
        motivo: 'Bebida fermentada probiótica natural.',
      ),
    ],
    'achocolatado': [
      AlternativaSaudavel(
        nome: 'Cacau em Pó 100% Puro',
        categoria: 'Achocolatados',
        nota: 95,
        nova: 1,
        motivo: 'Sem açúcar adicionado, rico em magnésio e flavonoides.',
      ),
      AlternativaSaudavel(
        nome: 'Cacau 70% com Açúcar de Coco',
        categoria: 'Achocolatados',
        nota: 80,
        nova: 2,
        motivo: 'Muito menos açúcares simples que os achocolatados convencionais.',
      ),
    ],
    'biscoito': [
      AlternativaSaudavel(
        nome: 'Biscoito Integral de Aveia e Mel',
        categoria: 'Biscoitos & Snacks',
        nota: 82,
        nova: 3,
        motivo: 'Alta concentração de fibras solúveis e sem gordura hidrogenada.',
      ),
      AlternativaSaudavel(
        nome: 'Chips de Maçã Desidratada 100% Fruta',
        categoria: 'Biscoitos & Snacks',
        nota: 95,
        nova: 1,
        motivo: 'Apenas fruta desidratada, sem conservantes ou açúcares.',
      ),
      AlternativaSaudavel(
        nome: 'Crackers de Sementes e Grãos',
        categoria: 'Biscoitos & Snacks',
        nota: 88,
        nova: 3,
        motivo: 'Fonte de gorduras boas e proteínas vegetais.',
      ),
    ],
    'salgadinho': [
      AlternativaSaudavel(
        nome: 'Pipoca Caseira com Azeite e Sal Marinho',
        categoria: 'Snacks',
        nota: 90,
        nova: 2,
        motivo: 'Grão integral rico em polifenóis, sem gordura vegetal hidrogenada.',
      ),
      AlternativaSaudavel(
        nome: 'Chips de Mandioca ou Batata Doce Assados',
        categoria: 'Snacks',
        nota: 80,
        nova: 3,
        motivo: 'Assado em vez de frito, ingredientes simples.',
      ),
      AlternativaSaudavel(
        nome: 'Mix de Castanhas de Caju e do Pará',
        categoria: 'Snacks',
        nota: 96,
        nova: 1,
        motivo: 'Alimento in natura, rico em selênio e gorduras monoinsaturadas.',
      ),
    ],
    'embutido': [
      AlternativaSaudavel(
        nome: 'Atum Sólido ao Natural em Água',
        categoria: 'Proteínas',
        nota: 92,
        nova: 1,
        motivo: 'Rico em Ômega-3, sem nitritos ou conservantes perigosos.',
      ),
      AlternativaSaudavel(
        nome: 'Peito de Frango Desfiado com Ervas',
        categoria: 'Proteínas',
        nota: 95,
        nova: 1,
        motivo: 'Carne in natura sem aditivos químicos ou excesso de sódio.',
      ),
      AlternativaSaudavel(
        nome: 'Ovos Caipiras Cozidos',
        categoria: 'Proteínas',
        nota: 98,
        nova: 1,
        motivo: 'Proteína completa com colina e vitaminas naturais.',
      ),
    ],
    'cereal': [
      AlternativaSaudavel(
        nome: 'Aveia em Flocos Finos 100% Integral',
        categoria: 'Cereais',
        nota: 100,
        nova: 1,
        motivo: 'Rica em beta-glucana que reduz colesterol e sacia.',
      ),
      AlternativaSaudavel(
        nome: 'Granola Artesanal Sem Açúcar Adicionado',
        categoria: 'Cereais',
        nota: 86,
        nova: 2,
        motivo: 'Sementes, castanhas e grãos integrais tostados.',
      ),
    ],
    'molho': [
      AlternativaSaudavel(
        nome: 'Passata de Tomate 100% Pomodoro',
        categoria: 'Molhos',
        nota: 90,
        nova: 1,
        motivo: 'Apenas tomate puro, sem amido, açúcar ou glutamato.',
      ),
      AlternativaSaudavel(
        nome: 'Molho Caseiro de Tomate com Manjericão',
        categoria: 'Molhos',
        nota: 95,
        nova: 2,
        motivo: 'Feito com azeite de oliva e ingredientes frescos.',
      ),
    ],
  };

  /// Identifica a categoria do produto e retorna alternativas mais saudáveis
  static List<AlternativaSaudavel> buscarAlternativas(String nomeProduto, String ingredientes) {
    final texto = '$nomeProduto $ingredientes'.toLowerCase();

    if (texto.contains('coca') ||
        texto.contains('refrigerante') ||
        texto.contains('guaraná') ||
        texto.contains('fanta') ||
        texto.contains('sprite') ||
        texto.contains('soda') ||
        texto.contains('pepsi') ||
        texto.contains('energético') ||
        texto.contains('energetico')) {
      return _catalogo['refrigerante']!;
    }

    if (texto.contains('nescau') ||
        texto.contains('toddy') ||
        texto.contains('achocolatado') ||
        texto.contains('chocolat')) {
      return _catalogo['achocolatado']!;
    }

    if (texto.contains('biscoito') ||
        texto.contains('bolacha') ||
        texto.contains('rechead') ||
        texto.contains('wafer') ||
        texto.contains('oreo') ||
        texto.contains('passatempo')) {
      return _catalogo['biscoito']!;
    }

    if (texto.contains('doritos') ||
        texto.contains('ruffles') ||
        texto.contains('cheetos') ||
        texto.contains('fandangos') ||
        texto.contains('salgadinho') ||
        texto.contains('chips') ||
        texto.contains('batata frita')) {
      return _catalogo['salgadinho']!;
    }

    if (texto.contains('salsicha') ||
        texto.contains('presunto') ||
        texto.contains('linguiça') ||
        texto.contains('linguica') ||
        texto.contains('salame') ||
        texto.contains('mortadela') ||
        texto.contains('nuggets')) {
      return _catalogo['embutido']!;
    }

    if (texto.contains('sucrilhos') ||
        texto.contains('cereal matinal') ||
        texto.contains('corn flakes') ||
        texto.contains('chocoball') ||
        texto.contains('froot loops')) {
      return _catalogo['cereal']!;
    }

    if (texto.contains('ketchup') ||
        texto.contains('maionese') ||
        texto.contains('molho pronto') ||
        texto.contains('extrato')) {
      return _catalogo['molho']!;
    }

    // Alternativas genéricas saudáveis de alta qualidade
    return const [
      AlternativaSaudavel(
        nome: 'Alimentos In Natura do Grupo 1',
        categoria: 'Alimentação Limpa',
        nota: 100,
        nova: 1,
        motivo: 'Substitua ultraprocessados por frutas frescas, castanhas e grãos integrais.',
      ),
      AlternativaSaudavel(
        nome: 'Opções com lista curta de ingredientes',
        categoria: 'Dica Prática',
        nota: 90,
        nova: 2,
        motivo: 'Prefira produtos com no máximo 5 ingredientes reconhecíveis na despensa.',
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import '../theme.dart';

/// Tela de Guia e Educação Nutricional
class GuiaScreen extends StatelessWidget {
  const GuiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guia de Saúde & Rótulos'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          // Banner de Destaque
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: Color(0xFFFDE047), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Como avaliamos os alimentos?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Nossa nota de 0 a 100 analisa 3 pilares: grau de processamento industrial (NOVA), tabela nutricional e presença de aditivos químicos.',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Classificação NOVA
          const _TituloSecao(titulo: '1. Classificação NOVA (Processamento)'),
          const SizedBox(height: 10),
          _CardExplicativo(
            cor: AppColors.nova1,
            corBg: AppColors.healthExcellentBg,
            icone: Icons.eco_rounded,
            titulo: 'Grupo 1 — In Natura ou Minimamente Processados',
            descricao:
                'Frutas, legumes, verduras, grãos, carnes, leite e ovos. Alimentos sem adição de substâncias industriais. Base da alimentação saudável.',
            pontos: 'Pontuação Máxima (+0 pts penalidade)',
          ),
          const SizedBox(height: 8),
          _CardExplicativo(
            cor: AppColors.nova2,
            corBg: const Color(0xFFF7FEE7),
            icone: Icons.soup_kitchen_rounded,
            titulo: 'Grupo 2 — Ingredientes Culinários Processados',
            descricao:
                'Óleos vegetais, azeite, manteiga, açúcar e sal. Usados para temperar e cozinhar alimentos do Grupo 1.',
            pontos: 'Penalidade Leve (-5 pts)',
          ),
          const SizedBox(height: 8),
          _CardExplicativo(
            cor: AppColors.nova3,
            corBg: AppColors.healthModerateBg,
            icone: Icons.inventory_2_rounded,
            titulo: 'Grupo 3 — Alimentos Processados',
            descricao:
                'Conservas, queijos simples, pães artesanais e frutas em calda. Fabricados com adição de sal ou açúcar a alimentos do Grupo 1.',
            pontos: 'Penalidade Moderada (-15 pts)',
          ),
          const SizedBox(height: 8),
          _CardExplicativo(
            cor: AppColors.nova4,
            corBg: AppColors.healthBadBg,
            icone: Icons.warning_amber_rounded,
            titulo: 'Grupo 4 — Alimentos Ultraprocessados',
            descricao:
                'Refrigerantes, salgadinhos, embutidos, bolachas recheadas, macarrão instantâneo e guloseimas. Ricos em corantes, aromatizantes e conservantes.',
            pontos: 'Penalidade Severa (-35 pts)',
          ),
          const SizedBox(height: 24),

          // 2. Rotulagem Frontal ANVISA
          const _TituloSecao(titulo: '2. Nova Rotulagem Frontal (Lupa ANVISA)'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desde 2023, alimentos no Brasil devem exibir uma lupa preta na frente da embalagem caso ultrapassem os limites saudáveis:',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.4),
                ),
                SizedBox(height: 14),
                _LinhaAnvisa(
                  rotulo: 'Açúcar Adicionado',
                  limite: 'Acima de 15g por 100g (sólidos) ou 7.5g por 100ml (líquidos).',
                ),
                Divider(height: 18),
                _LinhaAnvisa(
                  rotulo: 'Gordura Saturada',
                  limite: 'Acima de 6g por 100g (sólidos) ou 3g por 100ml (líquidos).',
                ),
                Divider(height: 18),
                _LinhaAnvisa(
                  rotulo: 'Sódio',
                  limite: 'Acima de 600mg (1.5g de sal) por 100g ou 300mg por 100ml.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Dicas de Ouro
          const _TituloSecao(titulo: '3. Regra dos 5 Ingredientes'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A lista é sempre em ordem decrescente',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'O primeiro ingrediente é o que mais existe no produto. Se açúcar ou gordura vegetal for um dos 3 primeiros, o produto deve ser evitado.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String titulo;

  const _TituloSecao({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _CardExplicativo extends StatelessWidget {
  final Color cor;
  final Color corBg;
  final IconData icone;
  final String titulo;
  final String descricao;
  final String pontos;

  const _CardExplicativo({
    required this.cor,
    required this.corBg,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.pontos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: corBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cor.withValues(alpha: 0.3)),
                ),
                child: Icon(icone, color: cor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: corBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              pontos,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaAnvisa extends StatelessWidget {
  final String rotulo;
  final String limite;

  const _LinhaAnvisa({required this.rotulo, required this.limite});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.search, size: 16, color: Color(0xFF0F172A)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alto em $rotulo',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                limite,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

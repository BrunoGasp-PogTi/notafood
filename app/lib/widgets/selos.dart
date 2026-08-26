import 'package:flutter/material.dart';
import '../theme.dart';

/// Selo NOVA moderno com ícone descritivo e gradiente sutil.
class SeloNova extends StatelessWidget {
  final int nova;

  const SeloNova({super.key, required this.nova});

  @override
  Widget build(BuildContext context) {
    if (nova < 1 || nova > 4) return const SizedBox.shrink();

    Color cor;
    Color corBg;
    String titulo;
    String descricao;
    IconData icone;

    switch (nova) {
      case 1:
        cor = AppColors.nova1;
        corBg = AppColors.healthExcellentBg;
        titulo = 'NOVA 1';
        descricao = 'In natura / Mínimo';
        icone = Icons.eco_rounded;
        break;
      case 2:
        cor = AppColors.nova2;
        corBg = const Color(0xFFF7FEE7);
        titulo = 'NOVA 2';
        descricao = 'Ingrediente Culinário';
        icone = Icons.soup_kitchen_rounded;
        break;
      case 3:
        cor = AppColors.nova3;
        corBg = AppColors.healthModerateBg;
        titulo = 'NOVA 3';
        descricao = 'Processado';
        icone = Icons.inventory_2_rounded;
        break;
      case 4:
      default:
        cor = AppColors.nova4;
        corBg = AppColors.healthBadBg;
        titulo = 'NOVA 4';
        descricao = 'Ultraprocessado';
        icone = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: corBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  height: 1.1,
                ),
              ),
              Text(
                descricao,
                style: TextStyle(
                  color: cor.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 9.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selo circular com a letra do Nutri-Score (A a E).
class SeloNutriscore extends StatelessWidget {
  final String nutriscore;

  const SeloNutriscore({super.key, required this.nutriscore});

  @override
  Widget build(BuildContext context) {
    final letra = nutriscore.toUpperCase().trim();
    if (!['A', 'B', 'C', 'D', 'E'].contains(letra)) return const SizedBox.shrink();

    Color cor;
    switch (letra) {
      case 'A':
        cor = AppColors.nutriscoreA;
        break;
      case 'B':
        cor = AppColors.nutriscoreB;
        break;
      case 'C':
        cor = AppColors.nutriscoreC;
        break;
      case 'D':
        cor = AppColors.nutriscoreD;
        break;
      case 'E':
      default:
        cor = AppColors.nutriscoreE;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
            child: Text(
              letra,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nutri-Score',
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  height: 1.1,
                ),
              ),
              Text(
                'Grau $letra',
                style: TextStyle(
                  color: cor.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 9.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selo de Alerta de Rotulagem Frontal (Padrão ANVISA: Alto em Açúcar, Gordura, Sódio)
class SeloAlertaAnvisa extends StatelessWidget {
  final String tipo; // "acucar", "gordura", "sodio"

  const SeloAlertaAnvisa({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    String rotulo;
    switch (tipo) {
      case 'acucar':
        rotulo = 'ALTO EM AÇÚCAR ADICIONADO';
        break;
      case 'gordura':
        rotulo = 'ALTO EM GORDURA SATURADA';
        break;
      case 'sodio':
      default:
        rotulo = 'ALTO EM SÓDIO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            rotulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

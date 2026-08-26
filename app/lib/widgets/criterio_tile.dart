import 'package:flutter/material.dart';
import '../models/criterio.dart';
import '../theme.dart';

/// Item da lista de impacto na nota (Pontos Positivos / Pontos Negativos)
class CriterioTile extends StatelessWidget {
  final Criterio criterio;

  const CriterioTile({super.key, required this.criterio});

  @override
  Widget build(BuildContext context) {
    final bonus = criterio.isBonus;
    final cor = bonus ? AppColors.healthExcellent : AppColors.healthBad;
    final corFundo = bonus ? AppColors.healthExcellentBg : AppColors.healthBadBg;

    IconData icone = bonus ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded;
    final itemBaixo = criterio.item.toLowerCase();
    if (itemBaixo.contains('açúcar') || itemBaixo.contains('acucar')) {
      icone = Icons.cake_outlined;
    } else if (itemBaixo.contains('gordura')) {
      icone = Icons.opacity_rounded;
    } else if (itemBaixo.contains('sal') || itemBaixo.contains('sódio') || itemBaixo.contains('sodio')) {
      icone = Icons.grain_rounded;
    } else if (itemBaixo.contains('fibra')) {
      icone = Icons.grass_rounded;
    } else if (itemBaixo.contains('proteína') || itemBaixo.contains('proteina')) {
      icone = Icons.fitness_center_rounded;
    } else if (itemBaixo.contains('aditivo')) {
      icone = Icons.science_outlined;
    } else if (itemBaixo.contains('nova')) {
      icone = Icons.precision_manufacturing_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: corFundo,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icone, color: cor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              criterio.item,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: corFundo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              criterio.efeito,
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


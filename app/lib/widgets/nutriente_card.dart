import 'package:flutter/material.dart';
import '../theme.dart';

enum NivelNutriente { bom, moderado, ruim, neutro }

class NutrienteCard extends StatelessWidget {
  final String titulo;
  final String valorFormatado;
  final double? valorNumerico;
  final double valorMaximoReferencia;
  final String nivelTexto;
  final NivelNutriente nivel;
  final IconData icone;

  const NutrienteCard({
    super.key,
    required this.titulo,
    required this.valorFormatado,
    required this.valorNumerico,
    required this.valorMaximoReferencia,
    required this.nivelTexto,
    required this.nivel,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    Color cor;
    Color corFundo;

    switch (nivel) {
      case NivelNutriente.bom:
        cor = AppColors.healthExcellent;
        corFundo = AppColors.healthExcellentBg;
        break;
      case NivelNutriente.moderado:
        cor = AppColors.healthModerate;
        corFundo = AppColors.healthModerateBg;
        break;
      case NivelNutriente.ruim:
        cor = AppColors.healthBad;
        corFundo = AppColors.healthBadBg;
        break;
      case NivelNutriente.neutro:
        cor = AppColors.textSecondary;
        corFundo = AppColors.surfaceSecondary;
        break;
    }

    final double progresso = valorNumerico != null
        ? (valorNumerico! / valorMaximoReferencia).clamp(0.05, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: corFundo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: corFundo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nivelTexto,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valorFormatado,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'por 100g',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 5,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
        ],
      ),
    );
  }
}

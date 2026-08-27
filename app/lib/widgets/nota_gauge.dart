import 'package:flutter/material.dart';
import '../theme.dart';

/// Medidor circular moderno com gradiente, anel de brilho suave e badge de status.
class NotaGauge extends StatelessWidget {
  final int nota;
  final String classificacao;
  final double tamanho;

  const NotaGauge({
    super.key,
    required this.nota,
    required this.classificacao,
    this.tamanho = 180,
  });

  @override
  Widget build(BuildContext context) {
    final cor = AppColors.forScore(nota);
    final corFundo = AppColors.forScoreBg(nota);
    final valorProgresso = (nota.clamp(0, 100) / 100).toDouble();

    String rotulo;
    IconData icone;
    if (nota >= 75) {
      rotulo = 'Excelente Escolha';
      icone = Icons.check_circle_rounded;
    } else if (nota >= 50) {
      rotulo = 'Consumo Moderado';
      icone = Icons.info_rounded;
    } else {
      rotulo = 'Pouco Saudável';
      icone = Icons.warning_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: 0.15),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Trilha de fundo
              SizedBox(
                width: tamanho - 24,
                height: tamanho - 24,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: corFundo,
                ),
              ),
              // Arco de progresso ativo
              SizedBox(
                width: tamanho - 24,
                height: tamanho - 24,
                child: CircularProgressIndicator(
                  value: valorProgresso,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  color: cor,
                ),
              ),
              // Conteúdo central
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$nota',
                        style: TextStyle(
                          fontSize: tamanho * 0.23,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -1.0,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2, left: 1),
                        child: Text(
                          '/100',
                          style: TextStyle(
                            fontSize: tamanho * 0.085,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Score de Saúde',
                    style: TextStyle(
                      fontSize: tamanho * 0.065,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Badge de Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cor.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 6),
              Text(
                rotulo,
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

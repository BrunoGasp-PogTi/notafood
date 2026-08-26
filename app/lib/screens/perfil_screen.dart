import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/perfil_service.dart';
import '../theme.dart';

/// Tela de Configuração do Perfil de Saúde Personalizado
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilSaudeNotifierProvider);
    final notifier = ref.read(perfilSaudeNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meu Perfil de Saúde'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Banner Explicativo
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertas Médicos Personalizados',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Ao escanear produtos, o app emitirá alertas imediatos caso algum ingrediente seja incompatível com seu perfil.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.onPrimaryContainer, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'Condições & Restrições',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 6),

          // 1. Hipertensão
          _SwitchCard(
            titulo: 'Hipertensão Arterial',
            descricao: 'Alerta quando o alimento tiver alto teor de sódio (> 400mg ou > 1g de sal).',
            icone: Icons.monitor_heart_rounded,
            corIcone: const Color(0xFFE11D48),
            valor: perfil.alertaHipertensao,
            onChanged: (v) => notifier.atualizar(perfil.copyWith(alertaHipertensao: v)),
          ),
          const SizedBox(height: 10),

          // 2. Diabetes
          _SwitchCard(
            titulo: 'Diabetes / Pré-Diabetes',
            descricao: 'Alerta sobre açúcares simples, maltodextrina, xarope de glicose e amidos ocultos.',
            icone: Icons.bloodtype_rounded,
            corIcone: const Color(0xFFEA580C),
            valor: perfil.alertaDiabetes,
            onChanged: (v) => notifier.atualizar(perfil.copyWith(alertaDiabetes: v)),
          ),
          const SizedBox(height: 10),

          // 3. Glúten
          _SwitchCard(
            titulo: 'Sem Glúten (Doença Celíaca)',
            descricao: 'Alerta vermelho imediato caso o produto contenha trigo, aveia não certificada, centeio ou cevada.',
            icone: Icons.grass_rounded,
            corIcone: const Color(0xFFD97706),
            valor: perfil.semGluten,
            onChanged: (v) => notifier.atualizar(perfil.copyWith(semGluten: v)),
          ),
          const SizedBox(height: 10),

          // 4. Lactose
          _SwitchCard(
            titulo: 'Intolerância a Lactose',
            descricao: 'Alerta caso o produto contenha leite, soro de leite, lactose ou derivados lácteos.',
            icone: Icons.water_drop_rounded,
            corIcone: const Color(0xFF0284C7),
            valor: perfil.semLactose,
            onChanged: (v) => notifier.atualizar(perfil.copyWith(semLactose: v)),
          ),
          const SizedBox(height: 10),

          // 5. Vegano
          _SwitchCard(
            titulo: 'Alimentação Vegana / Sem Origem Animal',
            descricao: 'Alerta caso contenha carnes, leite, ovos, gelatina, mel ou corante carmim de cochonilha.',
            icone: Icons.eco_rounded,
            corIcone: const Color(0xFF10B981),
            valor: perfil.vegano,
            onChanged: (v) => notifier.atualizar(perfil.copyWith(vegano: v)),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color corIcone;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.corIcone,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: valor ? AppColors.primary : AppColors.border,
          width: valor ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: corIcone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: corIcone, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: valor,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

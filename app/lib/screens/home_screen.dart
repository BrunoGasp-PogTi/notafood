import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cesta_service.dart';
import '../theme.dart';
import 'cesta_compras_screen.dart';
import 'historico_screen.dart';
import 'perfil_screen.dart';
import 'scanner_screen.dart';

/// Shell principal do app com barra de navegação fluida e badges de alerta
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _indiceAtual = 0;

  final List<Widget> _telas = const [
    ScannerScreen(),
    CestaComprasScreen(),
    HistoricoScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cesta = ref.watch(cestaComprasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  indice: 0,
                  icone: Icons.qr_code_scanner_rounded,
                  rotulo: 'Scanner',
                ),
                _buildNavItem(
                  indice: 1,
                  icone: Icons.shopping_basket_rounded,
                  rotulo: 'Cesta',
                  badgeContador: cesta.isNotEmpty ? cesta.length : null,
                ),
                _buildNavItem(
                  indice: 2,
                  icone: Icons.history_rounded,
                  rotulo: 'Histórico',
                ),
                _buildNavItem(
                  indice: 3,
                  icone: Icons.person_rounded,
                  rotulo: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int indice,
    required IconData icone,
    required String rotulo,
    int? badgeContador,
  }) {
    final bool ativo = _indiceAtual == indice;

    return InkWell(
      onTap: () => setState(() => _indiceAtual = indice),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: ativo ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: ativo ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeContador != null,
              label: Text('$badgeContador'),
              backgroundColor: AppColors.primary,
              child: Icon(
                icone,
                color: ativo ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            if (ativo) ...[
              const SizedBox(width: 6),
              Text(
                rotulo,
                style: const TextStyle(
                  color: AppColors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


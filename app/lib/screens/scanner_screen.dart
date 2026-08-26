import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';
import 'foto_rotulo_screen.dart';
import 'guia_screen.dart';
import 'resultado_screen.dart';

/// Tela inicial com leitor de código de barras imersivo e atalhos de IA
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _codigoManual = TextEditingController();
  bool _navegando = false;
  bool _lanternaLigada = false;

  late AnimationController _animController;
  late Animation<double> _animPosicao;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _animPosicao = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _codigoManual.dispose();
    super.dispose();
  }

  DateTime? _ultimoScan;

  Future<void> _aoDetectarCodigo(BarcodeCapture captura) async {
    if (_navegando) return;

    final agora = DateTime.now();
    if (_ultimoScan != null && agora.difference(_ultimoScan!).inMilliseconds < 1500) {
      return;
    }

    final codigo = captura.barcodes.firstOrNull?.rawValue;
    if (codigo == null || codigo.trim().isEmpty) return;

    _ultimoScan = agora;
    await _abrirResultado(codigo.trim());
  }

  Future<void> _abrirResultado(String codigo) async {
    if (_navegando) return;
    setState(() => _navegando = true);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultadoScreen(codigo: codigo)),
    );

    if (!mounted) return;
    // Pequeno cooldown ao retornar para a câmera não re-ler o mesmo código instantaneamente
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _navegando = false);
    }
  }

  void _aoBuscarManualmente() {
    final codigo = _codigoManual.text.trim();
    if (codigo.isEmpty) return;
    _codigoManual.clear();
    _abrirResultado(codigo);
  }

  Future<void> _abrirFotoIA() async {
    if (_navegando) return;
    setState(() => _navegando = true);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FotoRotuloScreen()),
    );

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _navegando = false);
    }
  }

  Future<void> _alternarLanterna() async {
    await _controller.toggleTorch();
    setState(() => _lanternaLigada = !_lanternaLigada);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Câmera Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectarCodigo,
            errorBuilder: (context, error) => const _ErroCamera(),
          ),

          // 2. Mira e Linha Laser Animada
          Center(
            child: _MolduraDeEscaneamento(animacao: _animPosicao),
          ),

          // 3. Barra Superior Transparente / Glassmorphism
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.health_and_safety_rounded, color: AppColors.primaryLight, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'NotaFood',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _BotaoTopo(
                        icone: _lanternaLigada ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        ativo: _lanternaLigada,
                        tooltip: 'Lanterna',
                        onTap: _alternarLanterna,
                      ),
                      const SizedBox(width: 8),
                      _BotaoTopo(
                        icone: Icons.lightbulb_outline_rounded,
                        ativo: false,
                        tooltip: 'Guia Nutricional',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GuiaScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Painel Inferior (Botão de IA + Digitação Manual)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botão de Destaque: Analisar com IA
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: const Text(
                      'Tirar Foto do Rótulo (IA)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _abrirFotoIA,
                  ),
                  const SizedBox(height: 14),

                  // Digitação manual de código
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codigoManual,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ou digite o código de barras...',
                            prefixIcon: const Icon(Icons.numbers_rounded, size: 20, color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          onSubmitted: (_) => _aoBuscarManualmente(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceSecondary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: _aoBuscarManualmente,
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Overlay de Carregamento
          if (_navegando)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryLight),
                    SizedBox(height: 16),
                    Text(
                      'Consultando produto...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BotaoTopo extends StatelessWidget {
  final IconData icone;
  final bool ativo;
  final String tooltip;
  final VoidCallback onTap;

  const _BotaoTopo({
    required this.icone,
    required this.ativo,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ativo ? AppColors.primary : Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          alignment: Alignment.center,
          child: Icon(icone, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _MolduraDeEscaneamento extends StatelessWidget {
  final Animation<double> animacao;

  const _MolduraDeEscaneamento({required this.animacao});

  @override
  Widget build(BuildContext context) {
    const double largura = 280;
    const double altura = 180;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: largura,
              height: altura,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
            ),
            // Cantos destacados
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primaryLight, width: 4),
                    left: BorderSide(color: AppColors.primaryLight, width: 4),
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primaryLight, width: 4),
                    right: BorderSide(color: AppColors.primaryLight, width: 4),
                  ),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryLight, width: 4),
                    left: BorderSide(color: AppColors.primaryLight, width: 4),
                  ),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryLight, width: 4),
                    right: BorderSide(color: AppColors.primaryLight, width: 4),
                  ),
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
                ),
              ),
            ),
            // Laser Animado
            AnimatedBuilder(
              animation: animacao,
              builder: (context, child) {
                return Positioned(
                  top: animacao.value * (altura - 8),
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryLight.withValues(alpha: 0.1),
                          AppColors.primaryLight,
                          AppColors.primaryLight.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Text(
            'Enquadre o código de barras na área acima',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 70), // espaço para o painel inferior não sobrepor
      ],
    );
  }
}

class _ErroCamera extends StatelessWidget {
  const _ErroCamera();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Acesso à câmera indisponível.\nUse a digitação ou a foto com IA.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}


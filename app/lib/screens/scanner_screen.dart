import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/produto.dart';
import '../providers/app_providers.dart';
import '../services/cesta_service.dart';
import '../theme.dart';
import 'foto_rotulo_screen.dart';
import 'guia_screen.dart';
import 'resultado_screen.dart';

/// Tela inicial com leitor contínuo de código de barras e aba expansível inferior
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _codigoManual = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  String? _codigoDetectado;
  DateTime? _ultimoScan;
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
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _aoDetectarCodigo(BarcodeCapture captura) async {
    final agora = DateTime.now();
    if (_ultimoScan != null && agora.difference(_ultimoScan!).inMilliseconds < 1200) {
      return;
    }

    final codigo = captura.barcodes.firstOrNull?.rawValue;
    if (codigo == null || codigo.trim().isEmpty) return;

    final codigoLimpo = codigo.trim();
    _ultimoScan = agora;

    // Se já estiver exibindo o mesmo código, ignora
    if (_codigoDetectado == codigoLimpo) return;

    setState(() {
      _codigoDetectado = codigoLimpo;
    });

    // Anima a aba para a posição visível
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.28,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _aoBuscarManualmente() {
    final codigo = _codigoManual.text.trim();
    if (codigo.isEmpty) return;
    _codigoManual.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _codigoDetectado = codigo;
    });
  }

  Future<void> _abrirFotoIA() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FotoRotuloScreen()),
    );
  }

  Future<void> _alternarLanterna() async {
    await _controller.toggleTorch();
    setState(() => _lanternaLigada = !_lanternaLigada);
  }

  void _fecharAba() {
    setState(() {
      _codigoDetectado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Câmera Scanner Contínua
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectarCodigo,
            errorBuilder: (context, error) => const _ErroCamera(),
          ),

          // 2. Mira e Linha Laser Animada (apenas se a aba não estiver expandida)
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

          // 4. Painel Padrão Inferior (Quando nenhum produto foi escaneado ainda)
          if (_codigoDetectado == null)
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botão de Destaque: Analisar com IA
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                    const SizedBox(height: 12),

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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

          // 5. Aba Expansível Inferior (Quando há produto escaneado)
          if (_codigoDetectado != null)
            _AbaInferiorProduto(
              key: ValueKey(_codigoDetectado),
              codigo: _codigoDetectado!,
              sheetController: _sheetController,
              onFechar: _fecharAba,
            ),
        ],
      ),
    );
  }
}

/// Aba deslizante inferior do produto escaneado (Peek + Detalhes Completos)
class _AbaInferiorProduto extends ConsumerWidget {
  final String codigo;
  final DraggableScrollableController sheetController;
  final VoidCallback onFechar;

  const _AbaInferiorProduto({
    super.key,
    required this.codigo,
    required this.sheetController,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultado = ref.watch(produtoProvider(codigo));

    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.28,
      minChildSize: 0.16,
      maxChildSize: 0.90,
      snap: true,
      snapSizes: const [0.28, 0.90],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 28,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barra de arrasto e cabeçalho
              GestureDetector(
                onTap: () {
                  if (sheetController.isAttached) {
                    final target = sheetController.size < 0.5 ? 0.90 : 0.28;
                    sheetController.animateTo(
                      target,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '▲ Puxe para cima para ver análise completa e trocas',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo da Aba
              Expanded(
                child: resultado.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 12),
                          Text(
                            'Identificando produto e calculando nota...',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (erro, _) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Produto não cadastrado',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: onFechar,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'O código $codigo ainda não está na base. Tire uma foto do rótulo para a IA calcular:',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Tirar Foto do Rótulo (IA)'),
                              onPressed: () {
                                onFechar();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const FotoRotuloScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  data: (produto) {
                    return _ConteudoSheetProduto(
                      produto: produto,
                      scrollController: scrollController,
                      onFechar: onFechar,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConteudoSheetProduto extends ConsumerWidget {
  final Produto produto;
  final ScrollController scrollController;
  final VoidCallback onFechar;

  const _ConteudoSheetProduto({
    required this.produto,
    required this.scrollController,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cestaNotifier = ref.read(cestaComprasProvider.notifier);
    final estaNaCesta = ref.watch(cestaComprasProvider).any((p) => p.codigo == produto.codigo);
    final cor = AppColors.forScore(produto.nota);
    final corFundo = AppColors.forScoreBg(produto.nota);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // Card Rápido (Visível no modo Peek)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              // Badge de Nota
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: cor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${produto.nota}',
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nome e Marca
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      produto.marca.isNotEmpty ? produto.marca : produto.classificacao.toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Botão Rápido de Adicionar à Compra
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: estaNaCesta ? AppColors.healthGood : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(10),
                ),
                icon: Icon(
                  estaNaCesta ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                  size: 20,
                ),
                tooltip: estaNaCesta ? 'Na Compra' : 'Adicionar à Compra',
                onPressed: () {
                  if (estaNaCesta) {
                    cestaNotifier.remover(produto.codigo);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${produto.nome} removido da compra.'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    cestaNotifier.adicionar(produto);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${produto.nome} adicionado à Minha Compra! 🛒'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),

              // Botão Fechar / Scan Próximo
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
                onPressed: onFechar,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Análise Nutricional Completa (Quando o usuário puxa para cima)
        ResultadoConteudo(produto: produto),
      ],
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
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: ativo ? AppColors.primary : Colors.black.withValues(alpha: 0.55),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
      icon: Icon(icone, size: 20),
    );
  }
}

class _MolduraDeEscaneamento extends StatelessWidget {
  final Animation<double> animacao;

  const _MolduraDeEscaneamento({required this.animacao});

  @override
  Widget build(BuildContext context) {
    final tamanho = MediaQuery.of(context).size.width * 0.72;

    return SizedBox(
      width: tamanho,
      height: tamanho * 0.75,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(tamanho, tamanho * 0.75),
            painter: _BordasMiraPainter(),
          ),
          AnimatedBuilder(
            animation: animacao,
            builder: (context, child) {
              return Positioned(
                top: (tamanho * 0.75 - 4) * animacao.value,
                left: 12,
                right: 12,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primaryLight,
                        Colors.white,
                        AppColors.primaryLight,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BordasMiraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;
    const radius = 18.0;

    // Canto Superior Esquerdo
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Canto Superior Direito
    final pathTR = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Canto Inferior Esquerdo
    final pathBL = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - radius)
      ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(pathBL, paint);

    // Canto Inferior Direito
    final pathBR = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErroCamera extends StatelessWidget {
  const _ErroCamera();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_rounded, size: 48, color: AppColors.healthBad),
          SizedBox(height: 12),
          Text(
            'Permissão de Câmera Necessária',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Ative a permissão de câmera nas configurações do aparelho para escanear alimentos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

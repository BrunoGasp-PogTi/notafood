import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/app_providers.dart';
import '../services/api_exceptions.dart';
import '../theme.dart';
import 'resultado_screen.dart';

/// Tela para fotografar o rótulo/embalagem e analisar com IA (Gemini Vision)
class FotoRotuloScreen extends ConsumerStatefulWidget {
  final String? codigo;
  final VoidCallback? onManual;

  const FotoRotuloScreen({
    super.key,
    this.codigo,
    this.onManual,
  });

  @override
  ConsumerState<FotoRotuloScreen> createState() => _FotoRotuloScreenState();
}

class _FotoRotuloScreenState extends ConsumerState<FotoRotuloScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _foto;
  bool _processando = false;
  String? _statusTexto;

  Future<void> _tirarFoto(ImageSource source) async {
    final foto = await _picker.pickImage(source: source, imageQuality: 85);
    if (foto == null) return;
    setState(() => _foto = foto);
  }

  Future<void> _analisarComIA() async {
    final foto = _foto;
    if (foto == null) return;

    setState(() {
      _processando = true;
      _statusTexto = 'A Inteligência Artificial está analisando o rótulo...';
    });

    try {
      final repository = ref.read(produtoRepositoryProvider);

      final produto = await repository.analisarFoto(
        caminhoArquivo: foto.path,
        codigo: widget.codigo,
      );

      // Atualiza os providers
      ref.invalidate(produtoProvider(produto.codigo));
      ref.invalidate(historicoProvider);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Análise Nutricional')),
            body: ResultadoConteudo(produto: produto),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processando = false;
        _statusTexto = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.mensagem : 'Erro na análise: $e',
          ),
          backgroundColor: AppColors.healthBad,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Análise por Foto (IA)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fotografe a tabela nutricional, a lista de ingredientes ou a frente da embalagem.',
              style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _foto == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 54, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'Nenhuma foto selecionada',
                              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : Image.file(File(_foto!.path), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 20),
            if (_processando) ...[
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              const SizedBox(height: 14),
              Text(
                _statusTexto ?? 'Processando...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(_foto == null ? 'Câmera' : 'Outra Foto'),
                      onPressed: () => _tirarFoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galeria'),
                      onPressed: () => _tirarFoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_foto != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('Analisar com IA'),
                  onPressed: _analisarComIA,
                ),
              if (widget.onManual != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: widget.onManual,
                  child: const Text('Preencher manualmente'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}


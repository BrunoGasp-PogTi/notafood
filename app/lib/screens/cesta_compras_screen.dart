import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cesta_service.dart';
import '../theme.dart';
import 'resultado_screen.dart';

/// Tela do Carrinho / Cesta de Compras Saudável
class CestaComprasScreen extends ConsumerWidget {
  const CestaComprasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cesta = ref.watch(cestaComprasProvider);
    final notifier = ref.read(cestaComprasProvider.notifier);
    final score = notifier.scoreMedio;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Minha Cesta de Compras'),
        actions: [
          if (cesta.isNotEmpty)
            IconButton(
              tooltip: 'Limpar Cesta',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpar cesta?'),
                    content: const Text('Deseja remover todos os produtos da sua cesta atual?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          notifier.limpar();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Limpar', style: TextStyle(color: AppColors.healthBad)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cesta.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_basket_outlined, size: 44, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sua cesta está vazia',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ao escanear produtos no supermercado, toque em "Adicionar à Cesta" para acompanhar a qualidade das suas compras.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // 1. Painel de Score da Cesta
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forScore(score).withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.forScoreBg(score),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.forScore(score), width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$score',
                          style: TextStyle(
                            color: AppColors.forScore(score),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              score >= 75
                                  ? 'Cesta Muito Saudável! 🥗'
                                  : (score >= 50 ? 'Cesta Equilibrada ⚖️' : 'Atenção aos Ultraprocessados ⚠️'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cesta.length} item(ns) analisado(s).',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Lista de Itens na Cesta
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: cesta.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final produto = cesta[index];
                      final cor = AppColors.forScore(produto.nota);
                      final corFundo = AppColors.forScoreBg(produto.nota);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: corFundo,
                              shape: BoxShape.circle,
                              border: Border.all(color: cor.withValues(alpha: 0.35), width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${produto.nota}',
                              style: TextStyle(
                                color: cor,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            produto.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                          ),
                          subtitle: Text(
                            produto.marca.isNotEmpty ? produto.marca : produto.classificacao.toUpperCase(),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.healthBad, size: 20),
                            onPressed: () => notifier.remover(produto.codigo),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: const Text('Resultado')),
                                body: ResultadoConteudo(produto: produto),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cesta_service.dart';
import '../theme.dart';
import 'resultado_screen.dart';

/// Tela do Carrinho / Minha Compra Saudável
class CestaComprasScreen extends ConsumerWidget {
  const CestaComprasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cesta = ref.watch(cestaComprasProvider);
    final notifier = ref.read(cestaComprasProvider.notifier);
    final score = notifier.scoreMedio;
    final recomendacoes = notifier.recomendacoes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Minha Compra'),
        actions: [
          if (cesta.isNotEmpty)
            IconButton(
              tooltip: 'Limpar Compra',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpar lista de compras?'),
                    content: const Text('Deseja remover todos os produtos da sua lista atual?'),
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
                      'Sua lista de compras está vazia',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ao escanear produtos no supermercado, toque no botão 🛒 para adicioná-los à sua compra e acompanhar a nota média.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // 1. Painel de Score Médio da Compra
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
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
                                fontSize: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NOTA MÉDIA DA COMPRA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  score >= 75
                                      ? 'Compra Saudável 🥗'
                                      : (score >= 50 ? 'Compra Equilibrada ⚖️' : 'Atenção aos Ultraprocessados ⚠️'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forScore(score),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${cesta.length} produto(s) no carrinho',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),

                      // Discriminativo de Itens
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatPill(
                              label: 'Saudáveis',
                              count: notifier.totalSaudaveis,
                              color: AppColors.healthGood,
                              bgColor: AppColors.healthGoodBg,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildStatPill(
                              label: 'Moderados',
                              count: notifier.totalModerados,
                              color: AppColors.healthModerate,
                              bgColor: AppColors.healthModerateBg,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildStatPill(
                              label: 'A Evitar',
                              count: notifier.totalRuins,
                              color: AppColors.healthBad,
                              bgColor: AppColors.healthBadBg,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Recomendações Inteligentes da Compra
                if (recomendacoes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Recomendações para sua Compra',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...recomendacoes.map(
                          (rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              rec,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Título da Lista
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Produtos na sua Compra',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 4. Lista de Produtos
                ...cesta.map((produto) {
                  final cor = AppColors.forScore(produto.nota);
                  final corFundo = AppColors.forScoreBg(produto.nota);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.white,
                      child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: corFundo,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cor.withValues(alpha: 0.3), width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: produto.imagem.isNotEmpty
                                  ? Image.network(
                                      produto.imagem,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.fastfood_rounded, color: cor, size: 22),
                                    )
                                  : Icon(Icons.fastfood_rounded, color: cor, size: 22),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: cor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${produto.nota}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.healthBad, size: 22),
                        onPressed: () => notifier.remover(produto.codigo),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('Análise Nutricional')),
                            body: ResultadoConteudo(produto: produto),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                }),
              ],
            ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$count $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

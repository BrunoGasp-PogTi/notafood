import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/historico_item.dart';
import '../providers/app_providers.dart';
import '../theme.dart';
import 'resultado_screen.dart';

/// Tela de Histórico de Produtos com busca, filtros de saúde e métricas
class HistoricoScreen extends ConsumerStatefulWidget {
  const HistoricoScreen({super.key});

  @override
  ConsumerState<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends ConsumerState<HistoricoScreen> {
  String _filtroTexto = '';
  int _filtroCategoria = 0; // 0 = Todos, 1 = Bons (>=75), 2 = Moderados (50-74), 3 = Ruins (<50)

  @override
  Widget build(BuildContext context) {
    final historico = ref.watch(historicoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Histórico de Scans'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(historicoProvider),
          ),
        ],
      ),
      body: historico.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (erro, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.healthBadBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.healthBad),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Não foi possível carregar o histórico',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  erro.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                  onPressed: () => ref.invalidate(historicoProvider),
                ),
              ],
            ),
          ),
        ),
        data: (itens) => _buildConteudo(context, itens),
      ),
    );
  }

  Widget _buildConteudo(BuildContext context, List<HistoricoItem> itens) {
    if (itens.isEmpty) {
      return Center(
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
                child: const Icon(Icons.history_rounded, size: 44, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nenhum produto escaneado',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aponte a câmera para o código de barras ou tire foto do rótulo para começar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Calcula a média de notas
    final media = itens.map((i) => i.nota).reduce((a, b) => a + b) ~/ itens.length;
    final totalBons = itens.where((i) => i.nota >= 75).length;

    // Filtra os itens
    final itensFiltrados = itens.where((item) {
      final matchTexto = _filtroTexto.isEmpty ||
          item.nome.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          item.codigo.contains(_filtroTexto);
      
      if (!matchTexto) return false;

      if (_filtroCategoria == 1) return item.nota >= 75;
      if (_filtroCategoria == 2) return item.nota >= 50 && item.nota < 75;
      if (_filtroCategoria == 3) return item.nota < 50;
      return true;
    }).toList();

    return Column(
      children: [
        // 1. Resumo Geral de Saúde
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.forScoreBg(media),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.forScore(media), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$media',
                  style: TextStyle(
                    color: AppColors.forScore(media),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Média Geral da sua Despensa',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalBons de ${itens.length} produtos classificados como saudáveis.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Barra de Busca
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (val) => setState(() => _filtroTexto = val),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou código...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
              suffixIcon: _filtroTexto.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _filtroTexto = ''),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. Chips de Filtro
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFiltroChip(0, 'Todos (${itens.length})'),
              const SizedBox(width: 8),
              _buildFiltroChip(1, '🌟 Saudáveis (${itens.where((i) => i.nota >= 75).length})'),
              const SizedBox(width: 8),
              _buildFiltroChip(2, '⚠️ Moderados (${itens.where((i) => i.nota >= 50 && i.nota < 75).length})'),
              const SizedBox(width: 8),
              _buildFiltroChip(3, '❌ Evitar (${itens.where((i) => i.nota < 50).length})'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. Lista Filtrada de Produtos
        Expanded(
          child: itensFiltrados.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum produto com este filtro.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(historicoProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: itensFiltrados.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = itensFiltrados[index];
                      final cor = AppColors.forScore(item.nota);
                      final corFundo = AppColors.forScoreBg(item.nota);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResultadoScreen(codigo: item.codigo),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Badge Redondo de Nota
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: corFundo,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cor.withValues(alpha: 0.35), width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.nota}',
                                    style: TextStyle(
                                      color: cor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Textos
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nome,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            item.classificacao.toUpperCase(),
                                            style: TextStyle(
                                              color: cor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '•  ${_formatarData(item.ultimaConsulta)}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(int id, String rotulo) {
    final bool selecionado = _filtroCategoria == id;
    return ChoiceChip(
      label: Text(rotulo),
      selected: selecionado,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : AppColors.textPrimary,
        fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selecionado ? AppColors.primary : AppColors.border,
        ),
      ),
      onSelected: (_) => setState(() => _filtroCategoria = id),
    );
  }
}

String _formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  return '$dia/$mes às $hora:$minuto';
}


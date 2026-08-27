import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/perfil_saude.dart';
import '../models/produto.dart';
import '../providers/app_providers.dart';
import '../services/alternativas_service.dart';
import '../services/api_exceptions.dart';
import '../services/cesta_service.dart';
import '../services/perfil_service.dart';
import '../theme.dart';
import '../widgets/criterio_tile.dart';
import '../widgets/nota_gauge.dart';
import '../widgets/nutriente_card.dart';
import '../widgets/selos.dart';
import 'leitura_rotulo_flow.dart';

/// Tela de Resultado da Análise de Saúde do Alimento
class ResultadoScreen extends ConsumerWidget {
  final String codigo;

  const ResultadoScreen({super.key, required this.codigo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultado = ref.watch(produtoProvider(codigo));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Análise Nutricional'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(produtoProvider(codigo)),
          ),
        ],
      ),
      body: resultado.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Calculando nota de saúde...',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        error: (erro, _) {
          if (erro is ProdutoNaoEncontradoException) {
            return _ProdutoNaoEncontrado(codigo: erro.codigo, mensagem: erro.mensagem);
          }
          return _ErroConsulta(
            mensagem: erro.toString(),
            onTentarNovamente: () => ref.invalidate(produtoProvider(codigo)),
          );
        },
        data: (produto) => ResultadoConteudo(produto: produto),
      ),
    );
  }
}

class _ProdutoNaoEncontrado extends StatelessWidget {
  final String codigo;
  final String mensagem;

  const _ProdutoNaoEncontrado({required this.codigo, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.healthModerateBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.healthModerate.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 44, color: AppColors.healthModerate),
            ),
            const SizedBox(height: 20),
            const Text(
              'Produto não cadastrado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'O código $codigo ainda não está na base pública.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Analisar com IA (Foto do Rótulo)'),
                onPressed: () => iniciarLeituraRotulo(context, codigo),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ver no Open Food Facts'),
                onPressed: () => launchUrl(
                  Uri.parse('https://world.openfoodfacts.org/product/$codigo'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroConsulta extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _ErroConsulta({required this.mensagem, required this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            const SizedBox(height: 20),
            const Text(
              'Falha na Conexão',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              onPressed: onTentarNovamente,
            ),
          ],
        ),
      ),
    );
  }
}

class ResultadoConteudo extends ConsumerWidget {
  final Produto produto;

  const ResultadoConteudo({super.key, required this.produto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Perfil de Saúde do Usuário
    final perfil = ref.watch(perfilSaudeNotifierProvider);
    final perfilService = ref.watch(perfilServiceProvider);
    final alertasPerfil = perfilService.avaliarProduto(produto, perfil);

    // Alternativas Saudáveis (Troca Inteligente)
    final alternativas = produto.nota < 75
        ? AlternativasService.buscarAlternativas(produto.nome, produto.ingredientes)
        : <AlternativaSaudavel>[];

    // Alertas ANVISA automáticos com base nos nutrientes
    final acucar = (produto.nutrientes['acucar_100g'] as num?)?.toDouble();
    final gorduraSat = (produto.nutrientes['gordura_saturada_100g'] as num?)?.toDouble();
    final sal = (produto.nutrientes['sal_100g'] as num?)?.toDouble();

    final bool altoAcucar = (acucar != null && acucar > 15.0);
    final bool altoGordura = (gorduraSat != null && gorduraSat > 6.0);
    final bool altoSodio = (sal != null && sal > 1.5);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        if (produto.origem == 'cache_dispositivo') const _AvisoSemConexao(),

        // 1. Alertas Críticos do Perfil Médico do Usuário (se houver restrição violada)
        if (alertasPerfil.isNotEmpty) ...[
          _SecaoAlertasPerfil(alertas: alertasPerfil),
          const SizedBox(height: 14),
        ],

        // 2. Card Principal do Produto e Nota
        _HeroProdutoCard(produto: produto),
        const SizedBox(height: 16),

        // 3. Melhores Trocas (Sugestões mais saudáveis)
        if (alternativas.isNotEmpty) ...[
          _SecaoMelhoresTrocas(alternativas: alternativas),
          const SizedBox(height: 16),
        ],

        // 4. Botão Adicionar à Compra
        _BotaoAdicionarCompra(produto: produto),
        const SizedBox(height: 16),

        // 5. Alertas de Lupa ANVISA (Se houver excesso)
        if (altoAcucar || altoGordura || altoSodio) ...[
          _SecaoLupasAnvisa(
            altoAcucar: altoAcucar,
            altoGordura: altoGordura,
            altoSodio: altoSodio,
          ),
          const SizedBox(height: 16),
        ],

        // 6. Matriz de Macronutrientes (Cards Visuais)
        _MatrizNutricional(produto: produto),
        const SizedBox(height: 16),

        // 7. Detalhamento da Pontuação (Positivos vs Negativos)
        _SecaoCriterios(produto: produto),
        const SizedBox(height: 16),

        // 8. Ingredientes & Aditivos
        _SecaoIngredientesEAditivos(produto: produto),
      ],
    );
  }
}

class _BotaoAdicionarCompra extends ConsumerWidget {
  final Produto produto;

  const _BotaoAdicionarCompra({required this.produto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cestaNotifier = ref.read(cestaComprasProvider.notifier);
    final estaNaCesta = ref.watch(cestaComprasProvider).any((p) => p.codigo == produto.codigo);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(
          estaNaCesta ? Icons.check_circle_rounded : Icons.shopping_cart_rounded,
          size: 20,
        ),
        label: Text(
          estaNaCesta ? 'Item Adicionado à Minha Compra' : 'Adicionar à Minha Compra',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: estaNaCesta ? AppColors.healthGood : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
    );
  }
}

class _SecaoMelhoresTrocas extends StatelessWidget {
  final List<AlternativaSaudavel> alternativas;

  const _SecaoMelhoresTrocas({required this.alternativas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Melhores Trocas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Opções mais saudáveis da mesma categoria para substituir:',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          for (final alt in alternativas) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${alt.nota}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alt.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alt.motivo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecaoAlertasPerfil extends StatelessWidget {
  final List<AlertaPerfilItem> alertas;

  const _SecaoAlertasPerfil({required this.alertas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.healthBad.withValues(alpha: 0.35), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.healthBad,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Atenção ao seu Perfil de Saúde!',
                  style: TextStyle(
                    color: AppColors.healthBad,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final alerta in alertas) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.healthBad, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: '${alerta.titulo}: ',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.healthBad),
                          ),
                          TextSpan(text: alerta.motivo),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroProdutoCard extends ConsumerWidget {
  final Produto produto;

  const _HeroProdutoCard({required this.produto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        children: [
          // Imagem do Produto (se disponível)
          if (produto.imagem.isNotEmpty) ...[
            Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                produto.imagem,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood_rounded, size: 40, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Nome do Produto
          Text(
            produto.nome,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Marca e Quantidade
          if (produto.marca.isNotEmpty || produto.quantidade.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (produto.marca.isNotEmpty)
                  Text(
                    produto.marca,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                if (produto.quantidade.isNotEmpty)
                  Text(
                    '•  ${produto.quantidade}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          // Medidor de Nota
          NotaGauge(nota: produto.nota, classificacao: produto.classificacao, tamanho: 175),
          const SizedBox(height: 18),

          // Selos NOVA e Nutri-Score
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (produto.nova > 0) SeloNova(nova: produto.nova),
              if (produto.nutriscore.isNotEmpty && produto.nutriscore != 'desconhecido')
                SeloNutriscore(nutriscore: produto.nutriscore),
            ],
          ),

          const SizedBox(height: 18),
          // Botão Adicionar à Cesta de Compras
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.shopping_basket_outlined, size: 18),
              label: const Text('Adicionar à Cesta de Compras', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () {
                ref.read(cestaComprasProvider.notifier).adicionar(produto);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${produto.nome} adicionado à sua cesta!'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
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

class _SecaoLupasAnvisa extends StatelessWidget {
  final bool altoAcucar;
  final bool altoGordura;
  final bool altoSodio;

  const _SecaoLupasAnvisa({
    required this.altoAcucar,
    required this.altoGordura,
    required this.altoSodio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 20),
              SizedBox(width: 8),
              Text(
                'Rotulagem Frontal (ANVISA)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (altoAcucar) const SeloAlertaAnvisa(tipo: 'acucar'),
              if (altoGordura) const SeloAlertaAnvisa(tipo: 'gordura'),
              if (altoSodio) const SeloAlertaAnvisa(tipo: 'sodio'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatrizNutricional extends StatelessWidget {
  final Produto produto;

  const _MatrizNutricional({required this.produto});

  @override
  Widget build(BuildContext context) {
    final nutri = produto.nutrientes;
    final acucar = (nutri['acucar_100g'] as num?)?.toDouble();
    final gorduraSat = (nutri['gordura_saturada_100g'] as num?)?.toDouble();
    final sal = (nutri['sal_100g'] as num?)?.toDouble();
    final fibra = (nutri['fibra_100g'] as num?)?.toDouble();
    final proteina = (nutri['proteina_100g'] as num?)?.toDouble();

    // Se nenhum nutriente estiver disponível
    if (acucar == null && gorduraSat == null && sal == null && fibra == null && proteina == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            'Perfil Nutricional',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (acucar != null)
          NutrienteCard(
            titulo: 'Açúcares',
            valorFormatado: '${acucar.toStringAsFixed(1)} g',
            valorNumerico: acucar,
            valorMaximoReferencia: 45.0,
            nivelTexto: acucar > 22.5 ? 'Muito Alto' : (acucar > 5 ? 'Moderado' : 'Baixo'),
            nivel: acucar > 22.5 ? NivelNutriente.ruim : (acucar > 5 ? NivelNutriente.moderado : NivelNutriente.bom),
            icone: Icons.cake_outlined,
          ),
        if (acucar != null) const SizedBox(height: 8),

        if (gorduraSat != null)
          NutrienteCard(
            titulo: 'Gordura Saturada',
            valorFormatado: '${gorduraSat.toStringAsFixed(1)} g',
            valorNumerico: gorduraSat,
            valorMaximoReferencia: 15.0,
            nivelTexto: gorduraSat > 5.0 ? 'Alto' : (gorduraSat > 1.5 ? 'Moderado' : 'Baixo'),
            nivel: gorduraSat > 5.0 ? NivelNutriente.ruim : (gorduraSat > 1.5 ? NivelNutriente.moderado : NivelNutriente.bom),
            icone: Icons.opacity_rounded,
          ),
        if (gorduraSat != null) const SizedBox(height: 8),

        if (sal != null)
          NutrienteCard(
            titulo: 'Sal / Sódio',
            valorFormatado: '${sal.toStringAsFixed(2)} g',
            valorNumerico: sal,
            valorMaximoReferencia: 3.0,
            nivelTexto: sal > 1.5 ? 'Alto' : (sal > 0.3 ? 'Moderado' : 'Baixo'),
            nivel: sal > 1.5 ? NivelNutriente.ruim : (sal > 0.3 ? NivelNutriente.moderado : NivelNutriente.bom),
            icone: Icons.grain_rounded,
          ),
        if (sal != null) const SizedBox(height: 8),

        if (fibra != null)
          NutrienteCard(
            titulo: 'Fibras Alimentares',
            valorFormatado: '${fibra.toStringAsFixed(1)} g',
            valorNumerico: fibra,
            valorMaximoReferencia: 10.0,
            nivelTexto: fibra >= 6.0 ? 'Excelente Fonte' : (fibra >= 3.0 ? 'Boa Fonte' : 'Baixo'),
            nivel: fibra >= 3.0 ? NivelNutriente.bom : NivelNutriente.neutro,
            icone: Icons.grass_rounded,
          ),
        if (fibra != null) const SizedBox(height: 8),

        if (proteina != null)
          NutrienteCard(
            titulo: 'Proteínas',
            valorFormatado: '${proteina.toStringAsFixed(1)} g',
            valorNumerico: proteina,
            valorMaximoReferencia: 25.0,
            nivelTexto: proteina >= 8.0 ? 'Rico em Proteína' : 'Comum',
            nivel: proteina >= 8.0 ? NivelNutriente.bom : NivelNutriente.neutro,
            icone: Icons.fitness_center_rounded,
          ),
      ],
    );
  }
}

class _SecaoCriterios extends StatelessWidget {
  final Produto produto;

  const _SecaoCriterios({required this.produto});

  @override
  Widget build(BuildContext context) {
    if (produto.criterios.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Icon(Icons.fact_check_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Impactos no Score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          for (var i = 0; i < produto.criterios.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            CriterioTile(criterio: produto.criterios[i]),
          ],
        ],
      ),
    );
  }
}

class _SecaoIngredientesEAditivos extends StatelessWidget {
  final Produto produto;

  const _SecaoIngredientesEAditivos({required this.produto});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ingredientes Expansíveis
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            shape: const Border(),
            leading: const Icon(Icons.eco_rounded, color: AppColors.primary),
            title: const Text('Ingredientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            expandedAlignment: Alignment.topLeft,
            children: [
              Text(
                produto.ingredientes.isNotEmpty ? produto.ingredientes : 'Ingredientes não informados no rótulo.',
                style: const TextStyle(height: 1.5, color: AppColors.textPrimary, fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Aditivos
        if (produto.aditivos.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              shape: const Border(),
              leading: const Icon(Icons.science_rounded, color: AppColors.healthBad),
              title: Text('Aditivos Químicos (${produto.aditivos.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              expandedAlignment: Alignment.topLeft,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: produto.aditivos
                      .map((aditivo) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.healthBadBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.healthBad.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              aditivo,
                              style: const TextStyle(color: AppColors.healthBad, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        if (produto.aditivos.isNotEmpty) const SizedBox(height: 10),

        // Alérgenos
        if (produto.alergenos.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              shape: const Border(),
              leading: const Icon(Icons.warning_amber_rounded, color: AppColors.healthModerate),
              title: Text('Alérgenos (${produto.alergenos.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              expandedAlignment: Alignment.topLeft,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: produto.alergenos
                      .map((alergeno) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.healthModerateBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.healthModerate.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              alergeno.toUpperCase(),
                              style: const TextStyle(color: AppColors.healthModerate, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AvisoSemConexao extends StatelessWidget {
  const _AvisoSemConexao();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.healthModerateBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.healthModerate.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.offline_bolt_rounded, size: 18, color: AppColors.healthModerate),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo Offline — exibindo cache local do aparelho.',
              style: TextStyle(color: AppColors.healthModerate, fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}


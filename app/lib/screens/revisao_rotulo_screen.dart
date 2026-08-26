import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/rotulo_parser.dart';
import 'resultado_screen.dart';

const _descricaoNova = {
  1: 'in natura ou minimamente processado',
  2: 'ingrediente culinário processado',
  3: 'alimento processado',
  4: 'alimento ultraprocessado',
};

/// Formulário final do fluxo de leitura de rótulo: mostra o que o OCR
/// conseguiu ler (editável) e pede o que ele não consegue adivinhar (nome do
/// produto, classificação NOVA). Só ao confirmar aqui a nota é calculada.
class RevisaoRotuloScreen extends ConsumerStatefulWidget {
  final String codigo;
  final String ingredientesTexto;
  final List<String> aditivosIniciais;
  final List<String> alergenosIniciais;
  final ValoresRotulo valoresRotulo;

  const RevisaoRotuloScreen({
    super.key,
    required this.codigo,
    required this.ingredientesTexto,
    required this.aditivosIniciais,
    required this.alergenosIniciais,
    required this.valoresRotulo,
  });

  @override
  ConsumerState<RevisaoRotuloScreen> createState() => _RevisaoRotuloScreenState();
}

class _RevisaoRotuloScreenState extends ConsumerState<RevisaoRotuloScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nomeController = TextEditingController();
  late final _marcaController = TextEditingController();
  late final _quantidadeController = TextEditingController();
  late final _ingredientesController = TextEditingController(text: widget.ingredientesTexto);
  late final _porcaoController =
      TextEditingController(text: _formatarInicial(widget.valoresRotulo.porcaoG));
  late final _acucarController =
      TextEditingController(text: _formatarInicial(widget.valoresRotulo.acucarPorcao));
  late final _gorduraController =
      TextEditingController(text: _formatarInicial(widget.valoresRotulo.gorduraSaturadaPorcao));
  late final _sodioController =
      TextEditingController(text: _formatarInicial(widget.valoresRotulo.sodioMgPorcao));
  late final _fibraController =
      TextEditingController(text: _formatarInicial(widget.valoresRotulo.fibraPorcao));
  late final _proteinaController =
      TextEditingController(text: _formatarInicial(widget.valoresRotulo.proteinaPorcao));

  late List<String> _aditivos = List.of(widget.aditivosIniciais);
  late List<String> _alergenos = List.of(widget.alergenosIniciais);
  int? _nova;
  bool _enviando = false;
  String? _erroEnvio;

  static String _formatarInicial(double? valor) => valor == null ? '' : valor.toString();

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _quantidadeController.dispose();
    _ingredientesController.dispose();
    _porcaoController.dispose();
    _acucarController.dispose();
    _gorduraController.dispose();
    _sodioController.dispose();
    _fibraController.dispose();
    _proteinaController.dispose();
    super.dispose();
  }

  double? _numero(TextEditingController controller) {
    final texto = controller.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  Future<void> _calcularNota() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _erroEnvio = null;
    });

    final normalizados = normalizarPara100g(
      ValoresRotulo(
        porcaoG: _numero(_porcaoController),
        acucarPorcao: _numero(_acucarController),
        gorduraSaturadaPorcao: _numero(_gorduraController),
        sodioMgPorcao: _numero(_sodioController),
        fibraPorcao: _numero(_fibraController),
        proteinaPorcao: _numero(_proteinaController),
      ),
    );

    try {
      await ref.read(apiClientProvider).enviarProdutoManual({
        'codigo': widget.codigo,
        'nome': _nomeController.text.trim(),
        'marca': _marcaController.text.trim(),
        'quantidade': _quantidadeController.text.trim(),
        'ingredientes': _ingredientesController.text.trim(),
        'aditivos': _aditivos,
        'alergenos': _alergenos,
        'nova': _nova,
        'acucar_100g': normalizados.acucar100g,
        'gordura_saturada_100g': normalizados.gorduraSaturada100g,
        'sal_100g': normalizados.sal100g,
        'fibra_100g': normalizados.fibra100g,
        'proteina_100g': normalizados.proteina100g,
      });

      if (!mounted) return;
      ref.invalidate(produtoProvider(widget.codigo));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultadoScreen(codigo: widget.codigo)),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erroEnvio = erro.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar dados do rótulo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _SecaoCard(
              titulo: 'Produto',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome do produto *'),
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _marcaController,
                    decoration: const InputDecoration(labelText: 'Marca'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantidadeController,
                    decoration: const InputDecoration(labelText: 'Quantidade (ex.: 200g)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SecaoCard(
              titulo: 'Classificação NOVA',
              subtitulo: 'Nível de processamento — o critério de maior peso na nota.',
              child: RadioGroup<int?>(
                groupValue: _nova,
                onChanged: (valor) => setState(() => _nova = valor),
                child: Column(
                  children: [
                    for (final nova in _descricaoNova.entries)
                      RadioListTile<int?>(
                        contentPadding: EdgeInsets.zero,
                        value: nova.key,
                        title: Text('NOVA ${nova.key}'),
                        subtitle: Text(nova.value),
                      ),
                    const RadioListTile<int?>(
                      contentPadding: EdgeInsets.zero,
                      value: null,
                      title: Text('Não sei'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SecaoCard(
              titulo: 'Tabela nutricional (por porção)',
              subtitulo: 'Copie os valores exatamente como aparecem no rótulo.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _porcaoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tamanho da porção (g)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _acucarController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Açúcares totais (g)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gorduraController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Gorduras saturadas (g)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sodioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sódio (mg)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fibraController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Fibra alimentar (g)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _proteinaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Proteínas (g)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SecaoCard(
              titulo: 'Ingredientes',
              child: TextFormField(
                controller: _ingredientesController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Lista de ingredientes'),
              ),
            ),
            const SizedBox(height: 16),
            _SecaoCard(
              titulo: 'Aditivos',
              child: _ListaEditavel(
                itens: _aditivos,
                dica: 'Ex.: E330',
                onAlterar: (novos) => setState(() => _aditivos = novos),
              ),
            ),
            const SizedBox(height: 16),
            _SecaoCard(
              titulo: 'Alérgenos',
              child: _ListaEditavel(
                itens: _alergenos,
                dica: 'Ex.: gluten',
                onAlterar: (novos) => setState(() => _alergenos = novos),
              ),
            ),
            const SizedBox(height: 24),
            if (_erroEnvio != null) ...[
              Text(_erroEnvio!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            if (_enviando)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calcular nota'),
                onPressed: _calcularNota,
              ),
          ],
        ),
      ),
    );
  }
}

class _SecaoCard extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;

  const _SecaoCard({required this.titulo, required this.child, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (subtitulo != null) ...[
              const SizedBox(height: 4),
              Text(subtitulo!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Lista de chips com um campo pra adicionar item novo e um X pra remover.
class _ListaEditavel extends StatefulWidget {
  final List<String> itens;
  final String dica;
  final ValueChanged<List<String>> onAlterar;

  const _ListaEditavel({required this.itens, required this.dica, required this.onAlterar});

  @override
  State<_ListaEditavel> createState() => _ListaEditavelState();
}

class _ListaEditavelState extends State<_ListaEditavel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adicionar() {
    final valor = _controller.text.trim();
    if (valor.isEmpty || widget.itens.contains(valor)) return;
    widget.onAlterar([...widget.itens, valor]);
    _controller.clear();
  }

  void _remover(String item) {
    widget.onAlterar(widget.itens.where((i) => i != item).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.itens.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.itens
                .map((item) => Chip(label: Text(item), onDeleted: () => _remover(item)))
                .toList(),
          ),
        if (widget.itens.isNotEmpty) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: widget.dica),
                onSubmitted: (_) => _adicionar(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(icon: const Icon(Icons.add), onPressed: _adicionar),
          ],
        ),
      ],
    );
  }
}

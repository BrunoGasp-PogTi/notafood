class HistoricoItem {
  final String codigo;
  final String nome;
  final int nota;
  final String classificacao;
  final DateTime ultimaConsulta;

  const HistoricoItem({
    required this.codigo,
    required this.nome,
    required this.nota,
    required this.classificacao,
    required this.ultimaConsulta,
  });

  factory HistoricoItem.fromJson(Map<String, dynamic> json) {
    return HistoricoItem(
      codigo: json['codigo'] as String,
      nome: json['nome'] as String? ?? 'Produto sem nome',
      nota: (json['nota'] as num?)?.toInt() ?? 0,
      classificacao: json['classificacao'] as String? ?? 'desconhecida',
      ultimaConsulta:
          DateTime.tryParse(json['ultima_consulta'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class Criterio {
  final String item;
  final String efeito;

  const Criterio({required this.item, required this.efeito});

  factory Criterio.fromJson(Map<String, dynamic> json) {
    return Criterio(
      item: json['item'] as String? ?? '',
      efeito: json['efeito'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'item': item, 'efeito': efeito};

  /// O backend expressa penalidades como "-15 pts" e bônus como "+10 pts".
  bool get isBonus => !efeito.trim().startsWith('-');
}

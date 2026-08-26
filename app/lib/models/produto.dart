import 'criterio.dart';

class Produto {
  final String codigo;
  final String origem;
  final String nome;
  final String marca;
  final String quantidade;
  final String imagem;
  final int nota;
  final String classificacao;
  final int nova;
  final String nutriscore;
  final String ingredientes;
  final List<String> alergenos;
  final List<String> aditivos;
  final List<Criterio> criterios;
  final Map<String, dynamic> nutrientes;

  const Produto({
    required this.codigo,
    required this.origem,
    required this.nome,
    required this.marca,
    required this.quantidade,
    required this.imagem,
    required this.nota,
    required this.classificacao,
    required this.nova,
    required this.nutriscore,
    required this.ingredientes,
    required this.alergenos,
    required this.aditivos,
    required this.criterios,
    this.nutrientes = const {},
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      codigo: json['codigo'] as String,
      origem: json['origem'] as String? ?? 'desconhecida',
      nome: json['nome'] as String? ?? 'Produto sem nome',
      marca: json['marca'] as String? ?? '',
      quantidade: json['quantidade'] as String? ?? '',
      imagem: json['imagem'] as String? ?? '',
      nota: (json['nota'] as num?)?.toInt() ?? 0,
      classificacao: json['classificacao'] as String? ?? 'desconhecida',
      nova: (json['nova'] as num?)?.toInt() ?? 0,
      nutriscore: json['nutriscore'] as String? ?? 'desconhecido',
      ingredientes: json['ingredientes'] as String? ?? '',
      alergenos:
          (json['alergenos'] as List<dynamic>? ?? const []).cast<String>(),
      aditivos: (json['aditivos'] as List<dynamic>? ?? const []).cast<String>(),
      criterios: (json['criterios'] as List<dynamic>? ?? const [])
          .map((item) => Criterio.fromJson(item as Map<String, dynamic>))
          .toList(),
      nutrientes: json['nutrientes'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'origem': origem,
        'nome': nome,
        'marca': marca,
        'quantidade': quantidade,
        'imagem': imagem,
        'nota': nota,
        'classificacao': classificacao,
        'nova': nova,
        'nutriscore': nutriscore,
        'ingredientes': ingredientes,
        'alergenos': alergenos,
        'aditivos': aditivos,
        'criterios': criterios.map((criterio) => criterio.toJson()).toList(),
        'nutrientes': nutrientes,
      };

  Produto copyWith({String? origem}) => Produto(
        codigo: codigo,
        origem: origem ?? this.origem,
        nome: nome,
        marca: marca,
        quantidade: quantidade,
        imagem: imagem,
        nota: nota,
        classificacao: classificacao,
        nova: nova,
        nutriscore: nutriscore,
        ingredientes: ingredientes,
        alergenos: alergenos,
        aditivos: aditivos,
        criterios: criterios,
        nutrientes: nutrientes,
      );
}

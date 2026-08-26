/// Modelo de Preferências e Restrições de Saúde do Usuário
class PerfilSaude {
  final bool alertaHipertensao;
  final bool alertaDiabetes;
  final bool semGluten;
  final bool semLactose;
  final bool vegano;
  final bool evitarAditivosPreocupantes;

  const PerfilSaude({
    this.alertaHipertensao = false,
    this.alertaDiabetes = false,
    this.semGluten = false,
    this.semLactose = false,
    this.vegano = false,
    this.evitarAditivosPreocupantes = true,
  });

  bool get temAlgumFiltroAtivo =>
      alertaHipertensao ||
      alertaDiabetes ||
      semGluten ||
      semLactose ||
      vegano;

  PerfilSaude copyWith({
    bool? alertaHipertensao,
    bool? alertaDiabetes,
    bool? semGluten,
    bool? semLactose,
    bool? vegano,
    bool? evitarAditivosPreocupantes,
  }) {
    return PerfilSaude(
      alertaHipertensao: alertaHipertensao ?? this.alertaHipertensao,
      alertaDiabetes: alertaDiabetes ?? this.alertaDiabetes,
      semGluten: semGluten ?? this.semGluten,
      semLactose: semLactose ?? this.semLactose,
      vegano: vegano ?? this.vegano,
      evitarAditivosPreocupantes:
          evitarAditivosPreocupantes ?? this.evitarAditivosPreocupantes,
    );
  }
}

class AlertaPerfilItem {
  final String titulo;
  final String motivo;
  final bool isCritico;

  const AlertaPerfilItem({
    required this.titulo,
    required this.motivo,
    this.isCritico = true,
  });
}

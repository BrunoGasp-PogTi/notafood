import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/perfil_saude.dart';
import '../models/produto.dart';

/// Serviço de persistência do perfil de saúde no SharedPreferences
class PerfilService {
  static const _kHipertensao = 'perfil_hipertensao';
  static const _kDiabetes = 'perfil_diabetes';
  static const _kSemGluten = 'perfil_sem_gluten';
  static const _kSemLactose = 'perfil_sem_lactose';
  static const _kVegano = 'perfil_vegano';
  static const _kAditivos = 'perfil_aditivos';

  Future<PerfilSaude> carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    return PerfilSaude(
      alertaHipertensao: prefs.getBool(_kHipertensao) ?? false,
      alertaDiabetes: prefs.getBool(_kDiabetes) ?? false,
      semGluten: prefs.getBool(_kSemGluten) ?? false,
      semLactose: prefs.getBool(_kSemLactose) ?? false,
      vegano: prefs.getBool(_kVegano) ?? false,
      evitarAditivosPreocupantes: prefs.getBool(_kAditivos) ?? true,
    );
  }

  Future<void> salvarPerfil(PerfilSaude perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHipertensao, perfil.alertaHipertensao);
    await prefs.setBool(_kDiabetes, perfil.alertaDiabetes);
    await prefs.setBool(_kSemGluten, perfil.semGluten);
    await prefs.setBool(_kSemLactose, perfil.semLactose);
    await prefs.setBool(_kVegano, perfil.vegano);
    await prefs.setBool(_kAditivos, perfil.evitarAditivosPreocupantes);
  }

  /// Avalia um produto contra o perfil do usuário e retorna a lista de alertas
  List<AlertaPerfilItem> avaliarProduto(Produto produto, PerfilSaude perfil) {
    final alertas = <AlertaPerfilItem>[];
    final ingr = produto.ingredientes.toLowerCase();
    final alergenos = produto.alergenos.map((a) => a.toLowerCase()).toSet();
    final nutri = produto.nutrientes;

    final sal = (nutri['sal_100g'] as num?)?.toDouble();
    final acucar = (nutri['acucar_100g'] as num?)?.toDouble();

    // 1. Hipertensão (Sódio > 0.4g / 400mg)
    if (perfil.alertaHipertensao && sal != null && sal > 1.0) {
      alertas.add(
        AlertaPerfilItem(
          titulo: 'Alerta de Sódio (Hipertensão)',
          motivo: 'Contém ${sal.toStringAsFixed(2)}g de sal por 100g. Limite recomendado para hipertensos é baixo teor de sódio.',
          isCritico: true,
        ),
      );
    }

    // 2. Diabetes (Açúcar > 5g ou ingredientes como xarope/maltodextrina)
    if (perfil.alertaDiabetes) {
      if (acucar != null && acucar > 5.0) {
        alertas.add(
          AlertaPerfilItem(
            titulo: 'Alerta de Açúcar (Diabetes)',
            motivo: 'Contém ${acucar.toStringAsFixed(1)}g de açúcares por 100g.',
            isCritico: true,
          ),
        );
      } else if (ingr.contains('xarope de glicose') ||
          ingr.contains('maltodextrina') ||
          ingr.contains('açúcar') ||
          ingr.contains('acucar')) {
        alertas.add(
          const AlertaPerfilItem(
            titulo: 'Alerta de Carboidrato Simples (Diabetes)',
            motivo: 'Identificado açúcar ou xarope adicionado na lista de ingredientes.',
            isCritico: false,
          ),
        );
      }
    }

    // 3. Glúten (Doença Celíaca)
    if (perfil.semGluten) {
      final contemGluten = alergenos.contains('gluten') ||
          alergenos.contains('wheat') ||
          alergenos.contains('trigo') ||
          alergenos.contains('centeio') ||
          alergenos.contains('cevada') ||
          ingr.contains('trigo') ||
          ingr.contains('glúten') ||
          ingr.contains('gluten') ||
          ingr.contains('cevada') ||
          ingr.contains('centeio');

      if (contemGluten) {
        alertas.add(
          const AlertaPerfilItem(
            titulo: 'Contém Glúten',
            motivo: 'Incompatível com o perfil Sem Glúten / Celíaco.',
            isCritico: true,
          ),
        );
      }
    }

    // 4. Lactose
    if (perfil.semLactose) {
      final contemLactose = alergenos.contains('milk') ||
          alergenos.contains('leite') ||
          alergenos.contains('lactose') ||
          ingr.contains('leite') ||
          ingr.contains('soro de leite') ||
          ingr.contains('lactose') ||
          ingr.contains('manteiga');

      if (contemLactose) {
        alertas.add(
          const AlertaPerfilItem(
            titulo: 'Contém Lactose / Leite',
            motivo: 'Incompatível com o perfil Sem Lactose.',
            isCritico: true,
          ),
        );
      }
    }

    // 5. Vegano
    if (perfil.vegano) {
      final contemAnimal = alergenos.contains('milk') ||
          alergenos.contains('leite') ||
          alergenos.contains('eggs') ||
          alergenos.contains('ovos') ||
          alergenos.contains('ovo') ||
          alergenos.contains('fish') ||
          alergenos.contains('peixe') ||
          alergenos.contains('crustaceans') ||
          ingr.contains('carne') ||
          ingr.contains('leite') ||
          ingr.contains('ovo') ||
          ingr.contains('gelatina') ||
          ingr.contains('mel') ||
          ingr.contains('cochonilha');

      if (contemAnimal) {
        alertas.add(
          const AlertaPerfilItem(
            titulo: 'Ingredientes de Origem Animal',
            motivo: 'Incompatível com o perfil Vegano.',
            isCritico: true,
          ),
        );
      }
    }

    return alertas;
  }
}

final perfilServiceProvider = Provider<PerfilService>((ref) => PerfilService());

final perfilSaudeNotifierProvider =
    NotifierProvider<PerfilSaudeNotifier, PerfilSaude>(
  PerfilSaudeNotifier.new,
);

class PerfilSaudeNotifier extends Notifier<PerfilSaude> {
  @override
  PerfilSaude build() {
    _carregar();
    return const PerfilSaude();
  }

  Future<void> _carregar() async {
    final service = ref.read(perfilServiceProvider);
    final p = await service.carregarPerfil();
    state = p;
  }

  Future<void> atualizar(PerfilSaude novoPerfil) async {
    state = novoPerfil;
    final service = ref.read(perfilServiceProvider);
    await service.salvarPerfil(novoPerfil);
  }
}

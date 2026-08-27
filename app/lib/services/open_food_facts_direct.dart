import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/produto.dart';
import 'nutricao_calculator.dart';

class OpenFoodFactsDirectService {
  final http.Client _client;

  OpenFoodFactsDirectService({http.Client? client}) : _client = client ?? http.Client();

  Future<Produto?> buscarProduto(String codigo) async {
    final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$codigo.json');
    http.Response resp;
    try {
      resp = await _client.get(
        uri,
        headers: {
          'User-Agent': 'NotaFood/1.0 (Android Mobile App; https://github.com/BrunoGasp-PogTi/notafood)',
        },
      ).timeout(const Duration(milliseconds: 3000));
    } catch (_) {
      return null;
    }

    if (resp.statusCode != 200) {
      return null;
    }

    final dados = jsonDecode(resp.body) as Map<String, dynamic>;
    if (dados['status'] != 1 || dados['product'] == null) {
      return null;
    }

    final p = dados['product'] as Map<String, dynamic>;

    // Extrai aditivos
    final rawAditivos = (p['additives_tags'] as List<dynamic>?) ?? [];
    final aditivos = rawAditivos
        .map((tag) => tag.toString().split(':').last.toUpperCase())
        .toList();

    // Extrai alérgenos
    final rawAlergenos = (p['allergens_tags'] as List<dynamic>?) ?? [];
    final alergenos = rawAlergenos
        .map((tag) => tag.toString().split(':').last.toLowerCase())
        .toList();

    final nova = p['nova_group'] as int?;
    final nutrimentos = (p['nutriments'] as Map<String, dynamic>?) ?? {};

    final nutrientes = {
      'acucar_100g': nutrimentos['sugars_100g'],
      'gordura_saturada_100g': nutrimentos['saturated-fat_100g'],
      'sal_100g': nutrimentos['salt_100g'],
      'fibra_100g': nutrimentos['fiber_100g'],
      'proteina_100g': nutrimentos['proteins_100g'],
    };

    final nome = (p['product_name_pt'] ?? p['product_name'] ?? 'Produto sem nome').toString();
    final ingredientes = (p['ingredients_text_pt'] ?? p['ingredients_text'] ?? '').toString();

    final resultadoNota = NutricaoCalculator.calcularNota(
      nova: nova,
      nutrientes: nutrientes,
      aditivos: aditivos,
      nomeProduto: nome,
      ingredientes: ingredientes,
    );

    final novaFinal = (nova != null && nova > 0)
        ? nova
        : NutricaoCalculator.inferirNova(nome: nome, ingredientes: ingredientes);

    return Produto(
      codigo: codigo,
      nome: nome,
      marca: p['brands'] ?? '',
      quantidade: p['quantity'] ?? '',
      imagem: p['image_url'] ?? p['image_front_url'] ?? '',
      nota: resultadoNota.nota,
      classificacao: resultadoNota.classificacao,
      nova: novaFinal,
      nutriscore: (p['nutriscore_grade'] ?? 'desconhecido').toString().toLowerCase(),
      ingredientes: ingredientes,
      alergenos: alergenos,
      aditivos: aditivos,
      criterios: resultadoNota.criterios,
      origem: 'openfoodfacts',
      nutrientes: nutrientes,
    );
  }

  void dispose() => _client.close();
}

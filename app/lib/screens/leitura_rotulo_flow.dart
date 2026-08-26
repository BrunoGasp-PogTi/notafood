import 'package:flutter/material.dart';

import '../services/rotulo_parser.dart';
import 'foto_rotulo_screen.dart';
import 'revisao_rotulo_screen.dart';

/// Ponto de entrada do fluxo "analisar rótulo com IA":
/// Abre a tela de foto para análise com Gemini Vision, com opção de preenchimento manual.
void iniciarLeituraRotulo(BuildContext context, String codigo) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => FotoRotuloScreen(
        codigo: codigo,
        onManual: () => _abrirRevisaoManual(context, codigo),
      ),
    ),
  );
}

void _abrirRevisaoManual(BuildContext context, String codigo) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => RevisaoRotuloScreen(
        codigo: codigo,
        ingredientesTexto: '',
        aditivosIniciais: const [],
        alergenosIniciais: const [],
        valoresRotulo: const ValoresRotulo(),
      ),
    ),
  );
}

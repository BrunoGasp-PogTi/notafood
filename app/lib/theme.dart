import 'package:flutter/material.dart';

/// Design System do NotaFood: Paleta moderna Emerald/Slate, cantos suaves,
/// tipografia expressiva e cores semânticas de saúde.
class AppColors {
  // Cores de Identidade
  static const primary = Color(0xFF059669); // Emerald 600
  static const primaryLight = Color(0xFF10B981); // Emerald 500
  static const primaryDark = Color(0xFF047857); // Emerald 700
  static const primaryContainer = Color(0xFFECFDF5); // Emerald 50
  static const onPrimaryContainer = Color(0xFF065F46);

  // Superfícies e Fundos
  static const background = Color(0xFFF8FAFC); // Slate 50
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF1F5F9); // Slate 100
  static const border = Color(0xFFE2E8F0); // Slate 200

  // Textos
  static const textPrimary = Color(0xFF0F172A); // Slate 900
  static const textSecondary = Color(0xFF64748B); // Slate 500
  static const textMuted = Color(0xFF94A3B8); // Slate 400

  // Semântica de Saúde (Notas de 0 a 100)
  static const healthExcellent = Color(0xFF10B981); // >= 75 (Verde)
  static const healthExcellentBg = Color(0xFFECFDF5);
  static const healthGood = healthExcellent;
  static const healthGoodBg = healthExcellentBg;
  
  static const healthModerate = Color(0xFFF59E0B); // 50-74 (Âmbar)
  static const healthModerateBg = Color(0xFFFFFBEB);
  
  static const healthBad = Color(0xFFF43F5E); // < 50 (Coral/Vermelho)
  static const healthBadBg = Color(0xFFFFF1F2);

  // Classificação NOVA
  static const nova1 = Color(0xFF10B981); // In natura
  static const nova2 = Color(0xFF84CC16); // Ingredientes culinários
  static const nova3 = Color(0xFFF59E0B); // Processados
  static const nova4 = Color(0xFFE11D48); // Ultraprocessados

  // Nutri-Score
  static const nutriscoreA = Color(0xFF059669);
  static const nutriscoreB = Color(0xFF84CC16);
  static const nutriscoreC = Color(0xFFF59E0B);
  static const nutriscoreD = Color(0xFFEA580C);
  static const nutriscoreE = Color(0xFFDC2626);

  // Retorna a cor principal baseada na nota
  static Color forScore(int score) {
    if (score >= 75) return healthExcellent;
    if (score >= 50) return healthModerate;
    return healthBad;
  }

  // Retorna a cor de fundo com opacidade suave baseada na nota
  static Color forScoreBg(int score) {
    if (score >= 75) return healthExcellentBg;
    if (score >= 50) return healthModerateBg;
    return healthBadBg;
  }
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    outline: AppColors.border,
    outlineVariant: Color(0xFFCBD5E1),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: null,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
      color: AppColors.border,
    ),
  );
}


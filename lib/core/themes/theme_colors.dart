import 'package:flutter/material.dart';

class MedievalColors {
  MedievalColors._();

  static const Color parchment = Color(0xFFF4E4C1);
  static const Color parchmentLight = Color(0xFFFDFAED);
  static const Color parchmentDark = Color(0xFFEBDEB8);
  static const Color parchmentMuted = Color(0xFFD4C4A0);

  static const Color sepiaInk = Color(0xFF2C1810);
  static const Color sepiaSecondary = Color(0xFF5C3D2E);
  static const Color sepiaMuted = Color(0xFF8B7355);

  static const Color goldLeaf = Color(0xFFC9A14B);
  static const Color goldBright = Color(0xFFD4AF37);
  static const Color goldPale = Color(0xFFE0CF8A);

  static const Color vermillion = Color(0xFF8B1A1A);
  static const Color vermillionBright = Color(0xFFB22222);
  static const Color vermillionDark = Color(0xFF5C0E0E);

  static const Color ultramarine = Color(0xFF1F3A5C);
  static const Color verdigris = Color(0xFF3B5E2B);

  static const Color leatherDark = Color(0xFF1C0F08);
  static const Color leather = Color(0xFF3A2210);
  static const Color leatherLight = Color(0xFF5C3D2E);
}

class MedievalColorScheme {
  MedievalColorScheme._();

  static const ColorScheme light = ColorScheme.light(
    primary: MedievalColors.vermillion,
    onPrimary: MedievalColors.parchmentLight,
    primaryContainer: MedievalColors.vermillionDark,
    onPrimaryContainer: MedievalColors.goldPale,
    secondary: MedievalColors.goldLeaf,
    onSecondary: MedievalColors.sepiaInk,
    secondaryContainer: MedievalColors.goldPale,
    onSecondaryContainer: MedievalColors.sepiaInk,
    tertiary: MedievalColors.ultramarine,
    onTertiary: MedievalColors.parchmentLight,
    error: MedievalColors.vermillionBright,
    onError: MedievalColors.parchmentLight,
    surface: MedievalColors.parchmentLight,
    onSurface: MedievalColors.sepiaInk,
    surfaceContainerHighest: MedievalColors.parchmentMuted,
    onSurfaceVariant: MedievalColors.sepiaSecondary,
    outline: MedievalColors.goldPale,
    outlineVariant: MedievalColors.parchmentMuted,
    shadow: MedievalColors.sepiaInk,
  );
}

class MainThemeColors extends ThemeExtension<MainThemeColors> {
  final Color gpGold;
  final Color upgradeBronze;
  final Color constructionBrown;
  final Color rankColor;
  final Color costRed;
  final Color disabledBastion;
  final Color noImageBastion;

  const MainThemeColors({
    required this.gpGold,
    required this.upgradeBronze,
    required this.constructionBrown,
    required this.rankColor,
    required this.costRed,
    required this.disabledBastion,
    required this.noImageBastion,
  });

  static const MainThemeColors standard = MainThemeColors(
    gpGold: MedievalColors.goldLeaf,
    upgradeBronze: Color(0xFFCD7F32),
    constructionBrown: Color(0xFF8B5A2B),
    rankColor: Color(0xFFB87333),
    costRed: MedievalColors.vermillionBright,
    disabledBastion: Color(0xFFC4B89A),
    noImageBastion: Color(0xFF5C4A3A),
  );

  @override
  ThemeExtension<MainThemeColors> copyWith({
    Color? gpGold,
    Color? upgradeBronze,
    Color? constructionBrown,
    Color? rankColor,
    Color? costRed,
    Color? disabledBastion,
    Color? noImageBastion,
  }) {
    return MainThemeColors(
      gpGold: gpGold ?? this.gpGold,
      upgradeBronze: upgradeBronze ?? this.upgradeBronze,
      constructionBrown: constructionBrown ?? this.constructionBrown,
      rankColor: rankColor ?? this.rankColor,
      costRed: costRed ?? this.costRed,
      disabledBastion: disabledBastion ?? this.disabledBastion,
      noImageBastion: noImageBastion ?? this.noImageBastion,
    );
  }

  @override
  ThemeExtension<MainThemeColors> lerp(
      covariant ThemeExtension<MainThemeColors>? other, double t) {
    if (other is! MainThemeColors) return this;
    return MainThemeColors(
      gpGold: Color.lerp(gpGold, other.gpGold, t)!,
      upgradeBronze: Color.lerp(upgradeBronze, other.upgradeBronze, t)!,
      constructionBrown: Color.lerp(constructionBrown, other.constructionBrown, t)!,
      rankColor: Color.lerp(rankColor, other.rankColor, t)!,
      costRed: Color.lerp(costRed, other.costRed, t)!,
      disabledBastion: Color.lerp(disabledBastion, other.disabledBastion, t)!,
      noImageBastion: Color.lerp(noImageBastion, other.noImageBastion, t)!,
    );
  }
}

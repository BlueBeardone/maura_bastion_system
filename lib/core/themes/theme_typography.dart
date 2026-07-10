import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_colors.dart';

class MedievalTypography {
  MedievalTypography._();

  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.unifrakturCook(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: MedievalColors.sepiaInk,
    ),
    displayMedium: GoogleFonts.unifrakturCook(
      fontSize: 30,
      fontWeight: FontWeight.w400,
      color: MedievalColors.sepiaInk,
    ),
    displaySmall: GoogleFonts.unifrakturCook(
      fontSize: 26,
      fontWeight: FontWeight.w400,
      color: MedievalColors.sepiaInk,
    ),
    headlineLarge: GoogleFonts.cinzel(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: MedievalColors.vermillion,
    ),
    headlineMedium: GoogleFonts.cinzel(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: MedievalColors.vermillion,
    ),
    headlineSmall: GoogleFonts.cinzel(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: MedievalColors.vermillion,
    ),
    titleLarge: GoogleFonts.cinzelDecorative(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: MedievalColors.vermillion,
    ),
    titleMedium: GoogleFonts.imFellEnglish(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: MedievalColors.sepiaInk,
    ),
    titleSmall: GoogleFonts.imFellEnglish(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: MedievalColors.sepiaSecondary,
    ),
    bodyLarge: GoogleFonts.imFellEnglish(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: MedievalColors.sepiaInk,
    ),
    bodyMedium: GoogleFonts.imFellEnglish(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: MedievalColors.sepiaInk,
    ),
    bodySmall: GoogleFonts.imFellEnglish(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: MedievalColors.sepiaSecondary,
    ),
    labelLarge: GoogleFonts.cinzel(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: MedievalColors.goldBright,
    ),
    labelMedium: GoogleFonts.imFellEnglish(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: MedievalColors.sepiaInk,
    ),
    labelSmall: GoogleFonts.imFellEnglish(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: MedievalColors.sepiaSecondary,
    ),
  );
}

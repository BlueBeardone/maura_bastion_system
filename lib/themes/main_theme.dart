import 'package:flutter/material.dart';

final ThemeData mainTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  
  // Color scheme inspired by dark parchment, wood, and gold accents
  colorScheme: const ColorScheme.dark(
    primary: Color.fromARGB(255, 255, 248, 187),      // Warm leather/wood brown
    secondary: Color.fromARGB(255, 163, 57, 25),    // Rich gold for GP costs / upgrades
    tertiary: Color(0xFF6A4E2E),     // Darker wood tone
    surface: Color(0xFF2C2418),      // Dark parchment surface
    error: Color(0xFFCF6679),
    onPrimary: Color(0xFF1F1A12),
    onSecondary: Color(0xFF1F1A12),
    onSurface: Color(0xFFE9E2C7),    // Light text for readability
    onError: Color(0xFF1F1A12),
  ),
  
  // Scaffold background
  scaffoldBackgroundColor: const Color(0xFF1F1A12),
  
  // App bar – grounded, matte look
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 124, 96, 54),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Cinzel', // Fantasy / serif feel; fallback included
      fontWeight: FontWeight.bold,
      fontSize: 22,
      color: Color(0xFFE6B422),
      letterSpacing: 1.2,
    ),
    iconTheme: IconThemeData(color: Color(0xFFE6B422)),
  ),
  
  // Card style for facility panels
  cardTheme: CardThemeData(
    color: const Color(0xFF2C2418),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color.fromARGB(255, 255, 0, 0), width: 0.5),
    ),
    margin: const EdgeInsets.all(8),
  ),
  
  // Typography – consistent with a fantasy/tabletop guide
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Cinzel',
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE6B422),
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Cinzel',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE6B422),
    ),
    titleLarge: TextStyle(
      fontFamily: 'Cinzel',
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: Color.fromARGB(255, 71, 22, 9),
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: Color(0xFFE9E2C7),
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Color(0xFFD4CCB0),
    ),
    labelLarge: TextStyle(
      fontFamily: 'Cinzel',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFFE6B422),
    ),
  ),
  
  // Buttons – upgrade actions feel tangible
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE6B422),
      foregroundColor: const Color(0xFF1F1A12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'Cinzel',
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 0.8,
      ),
    ),
  ),
  
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE6B422),
      side: const BorderSide(color: Color(0xFFE6B422), width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  
  // Data table for upgrade costs and construction times
  dataTableTheme: DataTableThemeData(
    headingRowColor: WidgetStateColor.resolveWith(
      (states) => const Color(0xFF4A3724),
    ),
    dataRowColor: WidgetStateColor.resolveWith(
      (states) => const Color(0xFF2C2418),
    ),
    headingTextStyle: const TextStyle(
      fontFamily: 'Cinzel',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE6B422),
    ),
    dataTextStyle: const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Color(0xFFE9E2C7),
    ),
    dividerThickness: 0.5,
    columnSpacing: 24,
    horizontalMargin: 16,
  ),
  
  // Dialog style – used for upgrade confirmations
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF2C2418),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE6B422), width: 1),
    ),
    titleTextStyle: const TextStyle(
      fontFamily: 'Cinzel',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE6B422),
    ),
    contentTextStyle: const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: Color(0xFFE9E2C7),
    ),
  ),
  
  // Tooltips – for clarifying upgrade effects
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: const Color(0xFF4A3724),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE6B422), width: 0.5),
    ),
    textStyle: const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      color: Color(0xFFE9E2C7),
    ),
  ),
);
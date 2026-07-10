import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_typography.dart';
import 'theme_components.dart';

final ThemeData medievalTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  colorScheme: MedievalColorScheme.light,

  scaffoldBackgroundColor: MedievalColors.parchmentDark,
  canvasColor: MedievalColors.parchmentLight,
  cardColor: MedievalColors.parchmentLight,
  disabledColor: MedievalColors.parchmentMuted,
  dividerColor: MedievalColors.goldPale,
  highlightColor: MedievalColors.goldLeaf.withValues(alpha: 0.12),
  focusColor: MedievalColors.goldLeaf.withValues(alpha: 0.24),
  hoverColor: MedievalColors.goldLeaf.withValues(alpha: 0.08),
  unselectedWidgetColor: MedievalColors.sepiaMuted,
  splashFactory: InkRipple.splashFactory,

  textTheme: MedievalTypography.textTheme,
  primaryTextTheme: MedievalTypography.textTheme,

  appBarTheme: MedievalComponents.appBarTheme,
  bottomAppBarTheme: MedievalComponents.bottomAppBarTheme,
  bottomNavigationBarTheme: MedievalComponents.bottomNavigationBarTheme,
  navigationBarTheme: MedievalComponents.navigationBarTheme,
  navigationRailTheme: MedievalComponents.navigationRailTheme,
  tabBarTheme: MedievalComponents.tabBarTheme,

  elevatedButtonTheme: MedievalComponents.elevatedButtonTheme,
  outlinedButtonTheme: MedievalComponents.outlinedButtonTheme,
  textButtonTheme: MedievalComponents.textButtonTheme,
  floatingActionButtonTheme: MedievalComponents.floatingActionButtonTheme,

  cardTheme: MedievalComponents.cardTheme,
  chipTheme: MedievalComponents.chipTheme,
  dialogTheme: MedievalComponents.dialogTheme,
  dividerTheme: MedievalComponents.dividerTheme,
  inputDecorationTheme: MedievalComponents.inputDecorationTheme,

  checkboxTheme: MedievalComponents.checkboxTheme,
  radioTheme: MedievalComponents.radioTheme,
  switchTheme: MedievalComponents.switchTheme,
  sliderTheme: MedievalComponents.sliderTheme,
  progressIndicatorTheme: MedievalComponents.progressIndicatorTheme,

  scrollbarTheme: MedievalComponents.scrollbarTheme,
  tooltipTheme: MedievalComponents.tooltipTheme,
  popupMenuTheme: MedievalComponents.popupMenuTheme,
  snackBarTheme: MedievalComponents.snackBarTheme,
  bottomSheetTheme: MedievalComponents.bottomSheetTheme,

  datePickerTheme: MedievalComponents.datePickerTheme,
  timePickerTheme: MedievalComponents.timePickerTheme,
  textSelectionTheme: MedievalComponents.textSelectionTheme,
  pageTransitionsTheme: MedievalComponents.pageTransitionsTheme,

  iconTheme: const IconThemeData(
    color: MedievalColors.goldLeaf,
    size: 24,
  ),
  primaryIconTheme: const IconThemeData(color: MedievalColors.goldLeaf),

  visualDensity: VisualDensity.adaptivePlatformDensity,

  extensions: const <ThemeExtension<dynamic>>[
    MainThemeColors.standard,
  ],
);

import 'package:flutter/material.dart';

// === Custom Theme Extension for game‑specific colors ===
class MainThemeColors extends ThemeExtension<MainThemeColors> {
  final Color gpGold;          // primary gold for GP values
  final Color upgradeBronze;   // for upgrade buttons / highlights
  final Color constructionBrown; // for construction turns / wood
  final Color rankColor;       // for facility ranks (D, C, B, A, S)
  final Color costRed;         // for negative costs or warnings
  final Color disabledBastion; // for disabled bastion cards
  final Color noImageBastion;  // for bastions missing an image

  const MainThemeColors({
    required this.gpGold,
    required this.upgradeBronze,
    required this.constructionBrown,
    required this.rankColor,
    required this.costRed,
    required this.disabledBastion,
    required this.noImageBastion,
  });

  static const MainThemeColors light = MainThemeColors(
    gpGold: Color(0xFFE6B422),
    upgradeBronze: Color(0xFFCD7F32),
    constructionBrown: Color(0xFF8B5A2B),
    rankColor: Color(0xFFB87333),
    costRed: Color(0xFFE57373),
    disabledBastion: Color(0xFF7A6A52),
    noImageBastion: Color(0xFF3F3428),
  );

  static const MainThemeColors dark = MainThemeColors(
    gpGold: Color(0xFFE6B422),
    upgradeBronze: Color(0xFFCD7F32),
    constructionBrown: Color(0xFF8B5A2B),
    rankColor: Color(0xFFB87333),
    costRed: Color(0xFFE57373),
    disabledBastion: Color(0xFF7A6A52),
    noImageBastion: Color(0xFF3F3428),
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

// === Main ThemeData ===
final ThemeData mainThemeTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  // --- Core colors ---
  colorScheme: const ColorScheme.dark(
    primary: Color.fromARGB(255, 241, 181, 134),
    secondary: Color(0xFFE6B422),
    tertiary: Color(0xFF6A4E2E),
    surface: Color(0xFF2C2418),
    error: Color(0xFFCF6679),
    onPrimary: Color(0xFF1F1A12),
    onSecondary: Color(0xFF1F1A12),
    onSurface: Color(0xFFE9E2C7),
    onError: Color(0xFF1F1A12),
  ),

  // --- General colors (non‑ColorScheme) ---
  primaryColor: const Color(0xFFB87C4F),
  primaryColorLight: const Color(0xFFD9A066),
  primaryColorDark: const Color(0xFF5A3E22),
  secondaryHeaderColor: const Color(0xFF4A3724),
  canvasColor: const Color(0xFF1F1A12),
  scaffoldBackgroundColor: const Color.fromARGB(255, 241, 233, 210),
  cardColor: const Color(0xFF2C2418),
  disabledColor: const Color(0xFF6B5A44),
  highlightColor: const Color(0xFFE6B422).withValues(alpha: 0.12),
  focusColor: const Color(0xFFE6B422).withValues(alpha:0.24),
  hoverColor: const Color.fromARGB(255, 150, 114, 6).withValues(alpha:0.08),
  splashFactory: InkRipple.splashFactory,

  // --- Typography ---
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE6B422)),
    displayMedium: TextStyle(fontFamily: 'Cinzel', fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE6B422)),
    displaySmall: TextStyle(fontFamily: 'Cinzel', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE6B422)),
    headlineLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFE6B422)),
    headlineMedium: TextStyle(fontFamily: 'Cinzel', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFE6B422)),
    headlineSmall: TextStyle(fontFamily: 'Cinzel', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE6B422)),
    titleLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 32, fontWeight: FontWeight.w600, color: Color.fromARGB(255, 104, 18, 18)),
    titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 104, 18, 18)),
    titleSmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFD4CCB0)),
    bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
    bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
    bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
    labelLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE6B422)),
    labelMedium: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFE9E2C7)),
    labelSmall: TextStyle(fontFamily: 'Roboto', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFD4CCB0)),
  ),
  primaryTextTheme: const TextTheme(
    bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
    bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
    // ... similarly copy from main textTheme for consistency
  ),

  // --- AppBar ---
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 255, 204, 127),
    foregroundColor: Color.fromARGB(255, 58, 18, 18),
    elevation: 4,
    centerTitle: true,
    shadowColor: Color.fromARGB(255, 109, 66, 2),
    titleTextStyle: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 22, color: Color.fromARGB(255, 104, 18, 18), letterSpacing: 1.2),
    iconTheme: IconThemeData(color: Color.fromARGB(255, 104, 18, 18)),
    actionsIconTheme: IconThemeData(color: Color.fromARGB(255, 104, 18, 18)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
  ),

  // --- BottomAppBar ---
  bottomAppBarTheme: const BottomAppBarThemeData(
    color: Color(0xFF2C2418),
    elevation: 0,
    shape: CircularNotchedRectangle(),
  ),

  // --- BottomNavigationBar ---
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF2C2418),
    selectedItemColor: Color(0xFFE6B422),
    unselectedItemColor: Color(0xFFD4CCB0),
    selectedLabelStyle: TextStyle(fontFamily: 'Cinzel', fontSize: 12, fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(fontFamily: 'Roboto', fontSize: 12),
    type: BottomNavigationBarType.fixed,
    elevation: 4,
  ),

  // --- NavigationBar (M3) ---
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF2C2418),
    indicatorColor: const Color(0xFFE6B422).withValues(alpha:0.2),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(fontFamily: 'Cinzel', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE6B422));
      }
      return const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFD4CCB0));
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(0xFFE6B422), size: 24);
      }
      return const IconThemeData(color: Color(0xFFD4CCB0), size: 24);
    }),
    elevation: 2,
    height: 64,
  ),

  // --- NavigationRail ---
  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: const Color(0xFF2C2418),
    selectedIconTheme: const IconThemeData(color: Color(0xFFE6B422)),
    unselectedIconTheme: const IconThemeData(color: Color(0xFFD4CCB0)),
    selectedLabelTextStyle: const TextStyle(fontFamily: 'Cinzel', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE6B422)),
    unselectedLabelTextStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFD4CCB0)),
    groupAlignment: -1,
    elevation: 2,
  ),

  // --- TabBar ---
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFE6B422),
    unselectedLabelColor: Color(0xFFD4CCB0),
    indicatorColor: Color(0xFFE6B422),
    dividerColor: Color(0xFF4A3724),
    labelStyle: TextStyle(fontFamily: 'Cinzel', fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontFamily: 'Roboto', fontSize: 14),
    indicatorSize: TabBarIndicatorSize.tab,
  ),

  // --- Buttons ---
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE6B422),
      foregroundColor: const Color(0xFF1F1A12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
      disabledBackgroundColor: const Color(0xFF6B5A44),
      disabledForegroundColor: const Color(0xFFB8AA8A),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color.fromARGB(255, 104, 18, 18),
      side: const BorderSide(color: Color(0xFFE6B422), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontFamily: 'Cinzel', fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color.fromARGB(255, 104, 18, 18),
      textStyle: const TextStyle(fontFamily: 'Cinzel', fontSize: 14, fontWeight: FontWeight.w500),
    ),
  ),

  // --- FloatingActionButton ---
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color.fromARGB(255, 104, 18, 18),
    foregroundColor: Color(0xFF1F1A12),
    elevation: 4,
    shape: CircleBorder(),
    extendedTextStyle: TextStyle(fontFamily: 'Cinzel', fontSize: 14, fontWeight: FontWeight.bold),
  ),

  // --- Card ---
  cardTheme: CardThemeData(
    color: const Color(0xFF2C2418),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF4A3724), width: 0.5)),
    margin: const EdgeInsets.all(8),
    clipBehavior: Clip.antiAlias,
  ),

  // --- Chip ---
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF4A3724),
    disabledColor: const Color(0xFF3A2A1C),
    selectedColor: const Color(0xFFE6B422),
    secondarySelectedColor: const Color(0xFFB87C4F),
    labelStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFE9E2C7)),
    secondaryLabelStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFF1F1A12)),
    brightness: Brightness.dark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6B422), width: 0.5)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    deleteIconColor: const Color(0xFFE6B422),
    checkmarkColor: const Color(0xFF1F1A12),
  ),

  // --- Dialog ---
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF2C2418),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6B422), width: 1)),
    titleTextStyle: const TextStyle(fontFamily: 'Cinzel', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE6B422)),
    contentTextStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color(0xFFE9E2C7)),
    elevation: 8,
  ),

  // --- Divider ---
  dividerTheme: const DividerThemeData(
    color: Color(0xFF4A3724),
    thickness: 1,
    space: 16,
    indent: 16,
    endIndent: 16,
  ),

  // --- Input fields ---
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2418),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4A3724))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4A3724))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6B422), width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCF6679))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2)),
    labelStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color(0xFFD4CCB0)),
    hintStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color(0xFF8B7A62)),
    prefixIconColor: const Color(0xFFE6B422),
    suffixIconColor: const Color(0xFFE6B422),
    floatingLabelStyle: const TextStyle(fontFamily: 'Cinzel', color: Color(0xFFE6B422)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),

  // --- Checkbox, Radio, Switch ---
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFE6B422);
      return const Color(0xFF4A3724);
    }),
    checkColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF1F1A12);
      return const Color(0xFFE9E2C7);
    }),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    side: const BorderSide(color: Color(0xFFE6B422), width: 1.5),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFE6B422);
      return const Color(0xFF4A3724);
    }),
    visualDensity: VisualDensity.compact,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFE6B422);
      return const Color(0xFF4A3724);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFE6B422).withValues(alpha:0.5);
      return const Color(0xFF4A3724);
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFE6B422).withValues(alpha:0.12)),
  ),

  // --- Slider ---
  sliderTheme: SliderThemeData(
    activeTrackColor: const Color(0xFFE6B422),
    inactiveTrackColor: const Color(0xFF4A3724),
    thumbColor: const Color(0xFFE6B422),
    overlayColor: const Color(0xFFE6B422).withValues(alpha:0.2),
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
    valueIndicatorColor: const Color(0xFFE6B422),
    valueIndicatorTextStyle: const TextStyle(fontFamily: 'Cinzel', color: Color(0xFF1F1A12)),
  ),

  // --- Progress indicators ---
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFFE6B422),
    circularTrackColor: Color(0xFF4A3724),
    linearTrackColor: Color(0xFF4A3724),
  ),

  // --- Scrollbar ---
  scrollbarTheme: ScrollbarThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFE6B422)),
    trackColor: WidgetStateProperty.resolveWith((states) => const Color(0xFF4A3724)),
    thickness: WidgetStateProperty.all(8),
    radius: const Radius.circular(4),
  ),

  // --- Tooltip ---
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: const Color(0xFF4A3724),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE6B422), width: 0.5),
    ),
    textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFFE9E2C7)),
    preferBelow: true,
    verticalOffset: 8,
  ),

  // --- PopupMenu ---
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF2C2418),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE6B422), width: 0.5)),
    textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color(0xFFE9E2C7)),
  ),

  // --- SnackBar ---
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2C2418),
    contentTextStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color(0xFFE9E2C7)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
    actionTextColor: const Color(0xFFE6B422),
  ),

  // --- BottomSheet ---
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF2C2418),
    modalBackgroundColor: Color(0xFF2C2418),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    elevation: 4,
    modalElevation: 8,
  ),

  // --- DatePicker / TimePicker ---
  datePickerTheme: DatePickerThemeData(
    backgroundColor: const Color(0xFF2C2418),
    headerBackgroundColor: const Color(0xFF4A3724),
    headerForegroundColor: const Color(0xFFE6B422),
    dayStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Color(0xFFE9E2C7)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6B422), width: 1)),
  ),
  timePickerTheme: TimePickerThemeData(
    backgroundColor: const Color(0xFF2C2418),
    hourMinuteTextColor: const Color(0xFFE9E2C7),
    dialHandColor: const Color(0xFFE6B422),
    dialBackgroundColor: const Color(0xFF4A3724),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6B422), width: 1)),
  ),

  // --- TextSelection ---
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: const Color(0xFFE6B422),
    selectionColor: const Color(0xFFE6B422).withValues(alpha:0.4),
    selectionHandleColor: const Color(0xFFE6B422),
  ),

  // --- PageTransitions (optional) ---
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  ),

  // --- IconTheme ---
  iconTheme: const IconThemeData(
    color: Color(0xFFE6B422),
    size: 24,
  ),
  primaryIconTheme: const IconThemeData(color: Color(0xFFE6B422)),

  // --- Typography (overall) ---
  typography: Typography.material2021(
    platform: TargetPlatform.android,
    black: const TextTheme(
      // Not needed, but we can override defaults if desired
    ),
    white: const TextTheme(
      // Not needed
    ),
  ),

  // --- Visual Density ---
  visualDensity: VisualDensity.adaptivePlatformDensity,

  // --- MaterialState properties for unselected widgets (like InkWell) ---
  unselectedWidgetColor: const Color(0xFFD4CCB0),
  extensions: const <ThemeExtension<dynamic>>[
    MainThemeColors.dark,
  ],
);
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_colors.dart';

class MedievalComponents {
  MedievalComponents._();

  static AppBarTheme get appBarTheme => AppBarTheme(
        backgroundColor: MedievalColors.leatherDark,
        foregroundColor: MedievalColors.goldBright,
        elevation: 3,
        centerTitle: true,
        shadowColor: MedievalColors.sepiaInk,
        titleTextStyle: GoogleFonts.cinzelDecorative(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: MedievalColors.goldBright,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: MedievalColors.goldPale),
        actionsIconTheme: const IconThemeData(color: MedievalColors.goldPale),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
        ),
      );

  static BottomAppBarThemeData get bottomAppBarTheme => const BottomAppBarThemeData(
        color: MedievalColors.leatherDark,
        elevation: 0,
        shape: CircularNotchedRectangle(),
      );

  static BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        backgroundColor: MedievalColors.leatherDark,
        selectedItemColor: MedievalColors.goldBright,
        unselectedItemColor: MedievalColors.sepiaMuted,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'IMFellEnglish',
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      );

  static NavigationBarThemeData get navigationBarTheme => NavigationBarThemeData(
        backgroundColor: MedievalColors.leatherDark,
        indicatorColor: MedievalColors.goldLeaf.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: MedievalColors.goldBright,
            );
          }
          return GoogleFonts.imFellEnglish(
            fontSize: 12,
            color: MedievalColors.sepiaMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: MedievalColors.goldBright,
              size: 24,
            );
          }
          return const IconThemeData(
            color: MedievalColors.sepiaMuted,
            size: 24,
          );
        }),
        elevation: 2,
        height: 64,
      );

  static NavigationRailThemeData get navigationRailTheme =>
      NavigationRailThemeData(
        backgroundColor: MedievalColors.leatherDark,
        selectedIconTheme:
            const IconThemeData(color: MedievalColors.goldBright),
        unselectedIconTheme:
            const IconThemeData(color: MedievalColors.sepiaMuted),
        selectedLabelTextStyle: GoogleFonts.cinzel(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: MedievalColors.goldBright,
        ),
        unselectedLabelTextStyle: GoogleFonts.imFellEnglish(
          fontSize: 12,
          color: MedievalColors.sepiaMuted,
        ),
        groupAlignment: -1,
        elevation: 2,
      );

  static TabBarThemeData get tabBarTheme => const TabBarThemeData(
        labelColor: MedievalColors.vermillion,
        unselectedLabelColor: MedievalColors.sepiaMuted,
        indicatorColor: MedievalColors.goldLeaf,
        dividerColor: MedievalColors.parchmentMuted,
        labelStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'IMFellEnglish',
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      );

  static ElevatedButtonThemeData get elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MedievalColors.goldLeaf,
          foregroundColor: MedievalColors.sepiaInk,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
          disabledBackgroundColor: MedievalColors.parchmentMuted,
          disabledForegroundColor: MedievalColors.sepiaMuted,
        ),
      );

  static OutlinedButtonThemeData get outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MedievalColors.vermillion,
          side: const BorderSide(
            color: MedievalColors.goldLeaf,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  static TextButtonThemeData get textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MedievalColors.vermillion,
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  static FloatingActionButtonThemeData get floatingActionButtonTheme =>
      const FloatingActionButtonThemeData(
        backgroundColor: MedievalColors.vermillion,
        foregroundColor: MedievalColors.parchmentLight,
        elevation: 4,
        shape: CircleBorder(),
        extendedTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

  static CardThemeData get cardTheme => CardThemeData(
        color: MedievalColors.parchmentLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: MedievalColors.goldLeaf,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
      );

  static ChipThemeData get chipTheme => ChipThemeData(
        backgroundColor: MedievalColors.parchmentMuted,
        disabledColor: MedievalColors.parchmentDark,
        selectedColor: MedievalColors.goldLeaf,
        secondarySelectedColor: MedievalColors.vermillion,
        labelStyle: GoogleFonts.imFellEnglish(
          fontSize: 12,
          color: MedievalColors.sepiaInk,
        ),
        secondaryLabelStyle: GoogleFonts.imFellEnglish(
          fontSize: 12,
          color: MedievalColors.parchmentLight,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: MedievalColors.goldPale,
            width: 0.5,
          ),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        deleteIconColor: MedievalColors.vermillionBright,
        checkmarkColor: MedievalColors.sepiaInk,
      );

  static DialogThemeData get dialogTheme => DialogThemeData(
        backgroundColor: MedievalColors.parchmentLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: MedievalColors.goldLeaf,
            width: 1.5,
          ),
        ),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: MedievalColors.vermillion,
        ),
        contentTextStyle: GoogleFonts.imFellEnglish(
          fontSize: 15,
          color: MedievalColors.sepiaInk,
        ),
        elevation: 8,
      );

  static DividerThemeData get dividerTheme => const DividerThemeData(
        color: MedievalColors.goldPale,
        thickness: 1,
        space: 16,
        indent: 16,
        endIndent: 16,
      );

  static InputDecorationTheme get inputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: MedievalColors.parchment,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: MedievalColors.parchmentMuted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: MedievalColors.parchmentMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: MedievalColors.goldLeaf,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: MedievalColors.vermillionBright),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: MedievalColors.vermillionBright,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.imFellEnglish(
          fontSize: 15,
          color: MedievalColors.sepiaSecondary,
        ),
        hintStyle: GoogleFonts.imFellEnglish(
          fontSize: 15,
          color: MedievalColors.sepiaMuted,
        ),
        prefixIconColor: MedievalColors.goldLeaf,
        suffixIconColor: MedievalColors.goldLeaf,
        floatingLabelStyle: GoogleFonts.cinzel(
          color: MedievalColors.vermillion,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  static CheckboxThemeData get checkboxTheme => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MedievalColors.goldLeaf;
          }
          return MedievalColors.parchmentMuted;
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MedievalColors.sepiaInk;
          }
          return MedievalColors.parchmentLight;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        side: const BorderSide(color: MedievalColors.goldLeaf, width: 1.5),
      );

  static RadioThemeData get radioTheme => RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MedievalColors.goldLeaf;
          }
          return MedievalColors.parchmentMuted;
        }),
        visualDensity: VisualDensity.compact,
      );

  static SwitchThemeData get switchTheme => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MedievalColors.goldLeaf;
          }
          return MedievalColors.parchmentMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MedievalColors.goldLeaf.withValues(alpha: 0.5);
          }
          return MedievalColors.parchmentMuted;
        }),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => MedievalColors.goldLeaf.withValues(alpha: 0.12),
        ),
      );

  static SliderThemeData get sliderTheme => SliderThemeData(
        activeTrackColor: MedievalColors.goldLeaf,
        inactiveTrackColor: MedievalColors.parchmentMuted,
        thumbColor: MedievalColors.goldLeaf,
        overlayColor: MedievalColors.goldLeaf.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape:
            const RoundSliderOverlayShape(overlayRadius: 20),
        valueIndicatorColor: MedievalColors.goldLeaf,
        valueIndicatorTextStyle: GoogleFonts.cinzel(
          color: MedievalColors.sepiaInk,
        ),
      );

  static ProgressIndicatorThemeData get progressIndicatorTheme =>
      const ProgressIndicatorThemeData(
        color: MedievalColors.goldLeaf,
        circularTrackColor: MedievalColors.parchmentMuted,
        linearTrackColor: MedievalColors.parchmentMuted,
      );

  static ScrollbarThemeData get scrollbarTheme => ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => MedievalColors.goldLeaf,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => MedievalColors.parchmentMuted,
        ),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(4),
      );

  static TooltipThemeData get tooltipTheme => TooltipThemeData(
        decoration: BoxDecoration(
          color: MedievalColors.leatherDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: MedievalColors.goldLeaf,
            width: 0.5,
          ),
        ),
        textStyle: GoogleFonts.imFellEnglish(
          fontSize: 12,
          color: MedievalColors.parchmentLight,
        ),
        preferBelow: true,
        verticalOffset: 8,
      );

  static PopupMenuThemeData get popupMenuTheme => PopupMenuThemeData(
        color: MedievalColors.parchmentLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: MedievalColors.goldLeaf,
            width: 0.5,
          ),
        ),
        textStyle: GoogleFonts.imFellEnglish(
          fontSize: 14,
          color: MedievalColors.sepiaInk,
        ),
      );

  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
        backgroundColor: MedievalColors.leatherDark,
        contentTextStyle: GoogleFonts.imFellEnglish(
          fontSize: 14,
          color: MedievalColors.parchmentLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        actionTextColor: MedievalColors.goldLeaf,
      );

  static BottomSheetThemeData get bottomSheetTheme =>
      const BottomSheetThemeData(
        backgroundColor: MedievalColors.parchmentLight,
        modalBackgroundColor: MedievalColors.parchmentLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 4,
        modalElevation: 8,
      );

  static DatePickerThemeData get datePickerTheme => DatePickerThemeData(
        backgroundColor: MedievalColors.parchmentLight,
        headerBackgroundColor: MedievalColors.leather,
        headerForegroundColor: MedievalColors.goldBright,
        dayStyle: GoogleFonts.imFellEnglish(
          fontSize: 14,
          color: MedievalColors.sepiaInk,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: MedievalColors.goldLeaf,
            width: 1,
          ),
        ),
      );

  static TimePickerThemeData get timePickerTheme => TimePickerThemeData(
        backgroundColor: MedievalColors.parchmentLight,
        hourMinuteTextColor: MedievalColors.sepiaInk,
        dialHandColor: MedievalColors.goldLeaf,
        dialBackgroundColor: MedievalColors.parchmentMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: MedievalColors.goldLeaf,
            width: 1,
          ),
        ),
      );

  static TextSelectionThemeData get textSelectionTheme =>
      TextSelectionThemeData(
        cursorColor: MedievalColors.goldLeaf,
        selectionColor: MedievalColors.goldLeaf.withValues(alpha: 0.3),
        selectionHandleColor: MedievalColors.goldLeaf,
      );

  static PageTransitionsTheme get pageTransitionsTheme =>
      PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      );
}

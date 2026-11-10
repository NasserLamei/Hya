import 'package:flutter/material.dart';

class HyaColors {
  static const ivory = Color(0xFFF7F1EB);
  static const blush = Color(0xFFF4E3DC);
  static const rose = Color(0xFFC56B76);
  static const roseDeep = Color(0xFF8C4450);
  static const ink = Color(0xFF2C2422);
  static const muted = Color(0xFF8A7A74);
  static const sage = Color(0xFF6E9178);
  static const sageDeep = Color(0xFF365744);
  static const sageSoft = Color(0xFFE4EFE6);
  static const gold = Color(0xFFC4A15B);
  static const goldDeep = Color(0xFF7A5B28);
  static const goldSoft = Color(0xFFF8F0DC);
  static const card = Color(0xFFFFFCF9);
  static const line = Color(0xFFE7DBD4);
  static const green = Color(0xFF2F8A66);
  static const greenSoft = Color(0xFFE5F5EC);
  static const amber = Color(0xFFC4893A);
  static const amberSoft = Color(0xFFFFF3E0);
  static const red = Color(0xFFC45050);
  static const redSoft = Color(0xFFFDECEC);
}

class HyaType {
  static TextStyle style({
    double size = 16,
    double weight = 440,
    Color color = HyaColors.ink,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: 'Cairo',
      fontSize: size,
      color: color,
      height: height,
      fontVariations: [FontVariation('wght', weight)],
    );
  }
}

ThemeData buildHyaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(seedColor: HyaColors.rose).copyWith(
      primary: HyaColors.rose,
      onPrimary: Colors.white,
      surface: HyaColors.card,
      onSurface: HyaColors.ink,
    ),
  );

  return base.copyWith(
    textTheme: TextTheme(
      headlineMedium: HyaType.style(size: 30, weight: 700, height: 1.25),
      headlineSmall: HyaType.style(size: 24, weight: 700, height: 1.3),
      titleLarge: HyaType.style(size: 20, weight: 680, height: 1.35),
      titleMedium: HyaType.style(size: 17, weight: 650, height: 1.35),
      bodyLarge: HyaType.style(size: 16, weight: 450),
      bodyMedium: HyaType.style(size: 15, weight: 440),
      bodySmall: HyaType.style(size: 13, weight: 440, color: HyaColors.muted, height: 1.4),
      labelLarge: HyaType.style(size: 15, weight: 650, color: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HyaColors.rose,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: HyaType.style(size: 16, weight: 680, color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HyaColors.roseDeep,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: HyaColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: HyaType.style(size: 15, weight: 640, color: HyaColors.roseDeep),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: HyaType.style(size: 15, weight: 420, color: HyaColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HyaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HyaColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HyaColors.rose, width: 1.4),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: HyaColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    datePickerTheme: DatePickerThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      headerBackgroundColor: HyaColors.rose,
      headerForegroundColor: Colors.white,
    ),
  );
}

Color accentForMode(String mode) {
  return switch (mode) {
    'ttc' => HyaColors.sage,
    'postpartum' => HyaColors.gold,
    _ => HyaColors.rose,
  };
}

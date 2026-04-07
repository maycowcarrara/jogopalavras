import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color midnight = Color(0xFF4A332C);
  static const Color electricBlue = Color(0xFF2E7D6F);
  static const Color coral = Color(0xFFB54C5C);
  static const Color amber = Color(0xFFE0A63B);
  static const Color mint = Color(0xFF8EAF72);
  static const Color cream = Color(0xFFF8ECD5);
  static const Color card = Color(0xFFFFFAF2);
  static const Color ink = Color(0xFF5A4538);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: electricBlue,
      brightness: Brightness.light,
      primary: electricBlue,
      secondary: coral,
      tertiary: amber,
      surface: card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      textTheme: Typography.blackMountainView.apply(
        bodyColor: ink,
        displayColor: midnight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: midnight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: midnight, size: 22),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: midnight,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: midnight.withValues(alpha: 0.06),
        selectedColor: mint.withValues(alpha: 0.18),
        labelStyle: const TextStyle(
          color: midnight,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: electricBlue,
        linearTrackColor: Color(0x264A332C),
      ),
    );
  }
}

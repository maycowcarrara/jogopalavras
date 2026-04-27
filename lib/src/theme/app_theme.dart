import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color midnight = Color(0xFF171717);
  static const Color electricBlue = Color(0xFF2F5368);
  static const Color coral = Color(0xFF9E2F2F);
  static const Color amber = Color(0xFFC49A4A);
  static const Color mint = Color(0xFF60735A);
  static const Color cream = Color(0xFFF3EFE5);
  static const Color card = Color(0xFFFFFCF5);
  static const Color ink = Color(0xFF2D2A25);
  static const Color newsprint = Color(0xFFE6DFD0);
  static const Color rule = Color(0xFFBDB4A3);
  static const Color pressBlue = Color(0xFF2F5368);
  static const Color pressRed = Color(0xFF9E2F2F);
  static const Color pressGold = Color(0xFFC49A4A);
  static const Color pressGreen = Color(0xFF60735A);

  static const List<String> serifFallback = <String>[
    'Georgia',
    'Times New Roman',
    'Times',
  ];

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: pressBlue,
      brightness: Brightness.light,
      primary: pressBlue,
      secondary: pressRed,
      tertiary: pressGold,
      surface: card,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      textTheme: Typography.blackMountainView
          .apply(
            bodyColor: ink,
            displayColor: midnight,
            fontFamily: 'Georgia',
            fontFamilyFallback: serifFallback,
          )
          .copyWith(
            labelLarge: const TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: serifFallback,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            titleMedium: const TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: serifFallback,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
      iconTheme: const IconThemeData(color: midnight),
      dividerTheme: const DividerThemeData(color: rule, thickness: 1, space: 1),
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: rule),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: midnight,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: serifFallback,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: midnight,
          textStyle: const TextStyle(
            fontFamily: 'Georgia',
            fontFamilyFallback: serifFallback,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: midnight.withValues(alpha: 0.06),
        selectedColor: mint.withValues(alpha: 0.18),
        labelStyle: const TextStyle(
          color: midnight,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: rule),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: pressRed,
        linearTrackColor: Color(0x26171717),
      ),
    );
  }
}

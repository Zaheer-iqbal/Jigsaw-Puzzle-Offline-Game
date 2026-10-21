import 'package:flutter/material.dart';

enum BoardBackgroundStyle {
  feltGreen('Felt Green', Color(0xFF1E3F20), Color(0xFF152C16)),
  classicWood('Classic Wood', Color(0xFF3E2723), Color(0xFF261715)),
  midnightSlate('Midnight Slate', Color(0xFF1E222A), Color(0xFF13161C)),
  deepOcean('Deep Ocean', Color(0xFF0D2538), Color(0xFF07141E)),
  warmCork('Warm Cork', Color(0xFF4A3B32), Color(0xFF332720));

  final String label;
  final Color primaryColor;
  final Color secondaryColor;
  const BoardBackgroundStyle(this.label, this.primaryColor, this.secondaryColor);
}

class AppTheme {
  AppTheme._();

  // Calm color palette
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color primaryTealDark = Color(0xFF004D40);
  static const Color accentAmber = Color(0xFFFFA000);
  static const Color surfaceLight = Color(0xFFF7F9FA);
  static const Color surfaceDark = Color(0xFF14171A);
  static const Color cardDark = Color(0xFF1F2429);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.light,
      surface: surfaceLight,
    ),
    scaffoldBackgroundColor: surfaceLight,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1F2429),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2429),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.dark,
      surface: surfaceDark,
    ),
    scaffoldBackgroundColor: surfaceDark,
    cardTheme: CardThemeData(
      color: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

enum BoardBackgroundStyle {
  teal('Teal', Color(0xFF00695C), Color(0xFF004D40)),
  midnightNavy('Deep Navy', Color(0xFF1E293B), Color(0xFF0F172A)),
  feltGreen('Felt Green', Color(0xFF2E7D32), Color(0xFF1B5E20)),
  classicWood('Classic Wood', Color(0xFF6D4C41), Color(0xFF4E342E)),
  royalPurple('Royal Purple', Color(0xFF5E35B1), Color(0xFF4527A0)),
  cleanLight('Clean Light', Color(0xFFD6DCE5), Color(0xFFC4CCD8)),
  midnightSlate('Midnight Slate', Color(0xFF37474F), Color(0xFF263238)),
  deepOcean('Deep Ocean', Color(0xFF1976D2), Color(0xFF0D47A1)),
  warmCork('Warm Cork', Color(0xFF8D6E63), Color(0xFF5D4037));

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

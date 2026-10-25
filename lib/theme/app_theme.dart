import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF00030E);
  static const secondaryBackground = Color(0xFF0B0E1A);
  static const card = Color(0xFF2C1B2F);
  static const secondaryCard = Color(0xFF5E3A5C);
  static const mauve = Color(0xFFB47A9A);
  static const blush = Color(0xFFF3E9EC);
  static const softBlush = Color(0xFFE5CAD6);
  static const primaryText = blush;
  static const secondaryText = Color(0xFFB9A9BE);
  static const green = Color(0xFF9ABFA7);
  static const amber = Color(0xFFD7B47D);
  static const pink = Color(0xFFE58AAE);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: mauve,
      brightness: Brightness.dark,
      surface: secondaryBackground,
      primary: mauve,
      secondary: blush,
      error: pink,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: primaryText,
        displayColor: primaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: const TextStyle(color: primaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

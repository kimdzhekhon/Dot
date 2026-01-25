import 'package:flutter/material.dart';

class AppTheme {
  // Colors (Vibe Coding Palette)
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color primary = Color(0xFFFFFFFF); // The Dot
  static const Color dangerous = Color(0xFFFF3B30); // Red
  static const Color safe = Color(0xFF34C759); // Green
  static const Color warning = Color(0xFFFF9500); // Orange
  static const Color analyzing = Color(0xFF0A84FF); // Blue

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);

  // Text Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 57,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 45,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    color: textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: analyzing,
        surface: surface,
        error: dangerous,
        background: background,
      ),
      useMaterial3: true,
      fontFamily: 'Inter',
    );
  }
}

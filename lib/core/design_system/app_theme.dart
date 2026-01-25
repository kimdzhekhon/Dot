import 'package:flutter/material.dart';

class AppTheme {
  // Colors (Vibe Coding Palette - Light Mode)
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color surface = Color(0xFFF2F2F7);
  static const Color primary = Color(0xFF000000); // The Dot (Black)
  static const Color dangerous = Color(0xFFFF3B30); // Red
  static const Color safe = Color(0xFF34C759); // Green
  static const Color warning = Color(0xFFFF9500); // Orange
  static const Color analyzing = Color(0xFF4A80FF); // Blue (User defined)

  static const Color textPrimary = Color(0xFF000000);
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
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
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

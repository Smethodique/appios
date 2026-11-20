import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFBD7F66);
  static const Color primarySoft = Color(0xFF0A0F1D);
  static const Color accent = Color(0xFF8E7F68);
  static const Color backgroundLight = Color(0xFFF5F1EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C2B22);
  static const Color textMuted = Color(0xFFA69D8F);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        brightness: Brightness.dark,
        surface: primarySoft,
      ),
      scaffoldBackgroundColor: primarySoft,
      fontFamily: 'Inter',
    );
  }
}
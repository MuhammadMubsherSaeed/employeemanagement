import 'package:flutter/material.dart';

/// Semantic colors for the HRMS foundation. Company branding can later
/// override [lightScheme] / [darkScheme] without changing widgets.
class AppColors {
  AppColors._();

  static const Color canvasLight = Color(0xFFF7F9FC);
  static const Color canvasDark = Color(0xFF0F1419);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1F27);
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1B4ED1);
  static const Color accent = Color(0xFF12B5A8);
  static const Color heading = Color(0xFF1C2434);
  static const Color body = Color(0xFF5B6578);
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A524);
  static const Color success = Color(0xFF30A46C);
  static const Color info = Color(0xFF2F6FED);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    error: danger,
    onError: Colors.white,
    surface: surfaceLight,
    onSurface: heading,
    outline: Color(0xFFD0D5DD),
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6B93F5),
    onPrimary: Color(0xFF0B1A3A),
    secondary: Color(0xFF3DD6CB),
    onSecondary: Color(0xFF003733),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF3B0000),
    surface: surfaceDark,
    onSurface: Color(0xFFE8ECF2),
    outline: Color(0xFF3E4754),
  );
}

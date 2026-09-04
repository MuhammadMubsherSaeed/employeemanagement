import 'package:flutter/material.dart';

/// Semantic colors for the HRMS. Widgets should prefer [ColorScheme]
/// and these named tokens over raw [Color] literals.
class AppColors {
  AppColors._();

  static const Color canvasLight = Color(0xFFF5F7FB);
  static const Color canvasDark = Color(0xFF0F1419);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1F27);
  static const Color surfaceMutedLight = Color(0xFFEEF2F8);
  static const Color surfaceMutedDark = Color(0xFF242B35);

  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1B4ED1);
  static const Color secondary = Color(0xFF12B5A8);
  static const Color accent = secondary;

  static const Color heading = Color(0xFF1C2434);
  static const Color body = Color(0xFF5B6578);
  static const Color muted = Color(0xFF8A93A6);
  static const Color headingDark = Color(0xFFE8ECF2);
  static const Color bodyDark = Color(0xFFB4BCC9);

  static const Color borderLight = Color(0xFFD8DEE8);
  static const Color borderDark = Color(0xFF3E4754);

  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A524);
  static const Color success = Color(0xFF30A46C);
  static const Color info = Color(0xFF2F6FED);

  static const Color disabledLight = Color(0xFFB8BFC9);
  static const Color disabledDark = Color(0xFF6B7380);

  static const Color background = canvasLight;
  static const Color card = surfaceLight;
  static const Color textPrimary = heading;
  static const Color textSecondary = body;
  static const Color textMuted = muted;
  static const Color border = borderLight;
  static const Color divider = borderLight;
  static const Color disabled = disabledLight;
  static const Color error = danger;

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: danger,
    onError: Colors.white,
    surface: surfaceLight,
    onSurface: heading,
    outline: borderLight,
    surfaceContainerHighest: surfaceMutedLight,
    onSurfaceVariant: body,
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
    onSurface: headingDark,
    outline: borderDark,
    surfaceContainerHighest: surfaceMutedDark,
    onSurfaceVariant: bodyDark,
  );

  static Color successOf(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF4CC38A) : success;

  static Color warningOf(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFFFC14A) : warning;

  static Color dangerOf(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFFF8A80) : danger;

  static Color infoOf(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF6B93F5) : info;

  static Color mutedOf(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF8B95A5) : muted;
}

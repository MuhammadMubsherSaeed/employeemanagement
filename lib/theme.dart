import 'package:flutter/material.dart';

const primaryColor = Color(0xFFFF7000);
const secondaryColor = Color(0xFFFFD5B4);
const textColor = Color(0xFF646464);
const skinColor = Color(0xFFFFD5B4);
const headingColor = Color(0xFF141414);

const colorPrimary2 = Color(0xFF74849E);
const colorPrimary3 = Color(0xFFF8F8F8);
const colorPrimary4 = Color(0xFFC4D5ED);
const colorPrimary5 = Color(0xFFE9E9E9);
const colorPrimary6 = Color(0xFFE4E4E4);
const colorPrimary7 = Color(0xFFDADADA);
const colorPrimary8 = Color(0xFF6CC4CC);
const colorPrimary9 = Color(0xFF28D763);
const colorPrimary10 = Color(0xFFF7F9FD);
const colorPrimary11 = Color(0xFFFDBF00);
const colorPrimary12 = Color(0xFFE8E8E8);
const colorPrimary13 = Color(0xFF424347);

const darkColorPrimary1 = Color(0xFF26292E);
const darkColorPrimary2 = Color(0xFF444444);
const offButtonColor = Color(0xFFC4C4C4);
const darkModeTextColor = Color(0xFF9B9B9B);
const darkColorPrimary3 = Color(0xFF1E2024);

TextTheme _buildTextTheme(TextTheme base) {
  return base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontFamily: "assets/fonts/lato/Lato-Regular.ttf",
      color: headingColor,
      fontSize: 38,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w400,
      fontFamily: "assets/fonts/inter/Inter-Regular.ttf",
      color: headingColor,
      fontSize: 30,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w300,
      fontFamily: "assets/fonts/inter/Inter-Regular.ttf",
      color: headingColor,
      fontSize: 22,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontFamily: "assets/fonts/lato/Lato-Regular.ttf",
      fontWeight: FontWeight.w400,
      fontSize: 18,
      color: textColor,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontFamily: "assets/fonts/inter/Inter-Regular.ttf",
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: textColor,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontFamily: "assets/fonts/inter/Inter-Regular.ttf",
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: textColor,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: "assets/fonts/inter/Inter-Regular.ttf",
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: "assets/fonts/inter/Inter-Regular.ttf",
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: "assets/fonts/inter/Inter-Regular.ttf",
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
  );
}

final ThemeData darkThemeData = _buildDarkTheme();

final ThemeData lightThemeData = _buildLightTheme();

ThemeData _buildDarkTheme() {
  const Color secondaryColor = primaryColor;
  final ColorScheme colorScheme = const ColorScheme.dark().copyWith(
    primary: primaryColor,
    secondary: secondaryColor,
    background: Colors.black,
    error: Colors.red,
  );
  final ThemeData base = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    primaryColorDark: secondaryColor,
    // primaryColorLight: secondaryColor,
    buttonBarTheme: ButtonBarThemeData(
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
    ),
    indicatorColor: primaryColor,
    hintColor: secondaryColor,
    snackBarTheme: SnackBarThemeData().copyWith(
      backgroundColor: primaryColor,
    ),
    scaffoldBackgroundColor: Color(0xFF1E2024),
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    buttonTheme: ButtonThemeData(
      colorScheme: colorScheme,
      textTheme: ButtonTextTheme.primary,
    ),
  );
  return base.copyWith(
    textTheme: _buildTextTheme(base.textTheme),
    primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
  );
}

ThemeData _buildLightTheme() {
  const Color secondaryColor = primaryColor;
  final ColorScheme colorScheme = const ColorScheme.light().copyWith(
    primary: primaryColor,
    secondary: secondaryColor,
    background: Colors.white,
    error: Colors.red,
  );
  final ThemeData base = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    primaryColorLight: secondaryColor,
    indicatorColor: primaryColor,
    hintColor: secondaryColor,
    buttonBarTheme: ButtonBarThemeData(
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
    ),
    snackBarTheme: SnackBarThemeData().copyWith(
      backgroundColor: primaryColor,
    ),
    scaffoldBackgroundColor: colorPrimary3,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    buttonTheme: ButtonThemeData(
      colorScheme: colorScheme,
      textTheme: ButtonTextTheme.primary,
    ),
  );
  return base.copyWith(
    textTheme: _buildTextTheme(base.textTheme),
    primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
  );
}

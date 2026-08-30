import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(ColorScheme scheme) {
    final Typography platform = Typography.material2021(
      platform: TargetPlatform.android,
    );
    final TextTheme base =
        (scheme.brightness == Brightness.dark ? platform.white : platform.black)
            .apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge,
      bodyMedium: base.bodyMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.78),
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.64),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall,
    );
  }
}

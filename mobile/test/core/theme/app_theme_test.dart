import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/theme/app_typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes use Material 3', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('typography exposes display through caption roles', () {
    final TextTheme theme = AppTypography.textTheme(AppTheme.light.colorScheme);
    expect(theme.displayLarge, isNotNull);
    expect(theme.headlineMedium, isNotNull);
    expect(theme.titleLarge, isNotNull);
    expect(theme.bodyMedium, isNotNull);
    expect(theme.labelLarge, isNotNull);
    expect(theme.bodySmall, isNotNull);
  });
}

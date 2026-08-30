import 'package:flutter/material.dart';
import 'package:flutter_base/core/storage/shared_prefs_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.watch(sharedPrefsServiceProvider).themeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(sharedPrefsServiceProvider).setThemeMode(mode);
    state = mode;
  }

  Future<void> cycle() {
    switch (state) {
      case ThemeMode.system:
        return setThemeMode(ThemeMode.light);
      case ThemeMode.light:
        return setThemeMode(ThemeMode.dark);
      case ThemeMode.dark:
        return setThemeMode(ThemeMode.system);
    }
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

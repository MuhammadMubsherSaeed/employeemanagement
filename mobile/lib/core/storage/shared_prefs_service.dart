import 'package:flutter/material.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap.',
  );
});

class SharedPrefsService {
  const SharedPrefsService(this._prefs);

  final SharedPreferences _prefs;

  ThemeMode get themeMode {
    switch (_prefs.getString(StorageKeys.themeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) {
    return _prefs.setString(StorageKeys.themeMode, mode.name);
  }

  bool get onboardingComplete {
    return _prefs.getBool(StorageKeys.onboardingComplete) ?? false;
  }

  Future<bool> setOnboardingComplete({required bool complete}) {
    return _prefs.setBool(StorageKeys.onboardingComplete, complete);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);
}

final sharedPrefsServiceProvider = Provider<SharedPrefsService>((Ref ref) {
  return SharedPrefsService(ref.watch(sharedPreferencesProvider));
});

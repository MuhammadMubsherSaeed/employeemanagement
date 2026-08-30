import 'package:flutter/material.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/shared_prefs_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsService', () {
    test('theme mode and onboarding flags round-trip', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final SharedPrefsService service = SharedPrefsService(prefs);

      expect(service.themeMode, ThemeMode.system);
      expect(service.onboardingComplete, isFalse);

      await service.setThemeMode(ThemeMode.dark);
      await service.setOnboardingComplete(complete: true);

      expect(service.themeMode, ThemeMode.dark);
      expect(service.onboardingComplete, isTrue);
    });
  });

  group('SecureStorageService', () {
    test('writes and clears tokens without storing passwords', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      const SecureStorageService service = SecureStorageService(
        FlutterSecureStorage(),
      );

      await service.saveAccessToken('token-1');
      await service.saveRefreshToken('token-2');
      expect(await service.readAccessToken(), 'token-1');
      expect(await service.readRefreshToken(), 'token-2');

      await service.clearSession();
      expect(await service.readAccessToken(), isNull);
      expect(await service.readRefreshToken(), isNull);
    });
  });
}

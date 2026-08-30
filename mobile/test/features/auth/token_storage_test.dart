import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TokenStorage writes and clears only secure token keys', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final TokenStorage storage = SecureTokenStorage(
      const SecureStorageService(FlutterSecureStorage()),
    );

    await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
    expect(await storage.getAccessToken(), 'a');
    expect(await storage.getRefreshToken(), 'r');
    expect(await storage.hasTokens(), isTrue);
    expect(await storage.hasRefreshToken(), isTrue);

    await storage.saveTokens(accessToken: 'a2');
    expect(await storage.getAccessToken(), 'a2');
    expect(await storage.getRefreshToken(), 'r');

    await storage.clearTokens();
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.hasTokens(), isFalse);
  });

  test('storage key names stay out of SharedPreferences', () {
    expect(StorageKeys.accessToken, 'access_token');
    expect(StorageKeys.refreshToken, 'refresh_token');
  });
}

import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Secure persistence for JWT access/refresh tokens. Never use SharedPreferences.
abstract class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();

  Future<bool> hasTokens();

  Future<bool> hasRefreshToken();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._secure);

  final SecureStorageService _secure;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secure.saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secure.saveRefreshToken(refreshToken);
    }
  }

  @override
  Future<String?> getAccessToken() => _secure.readAccessToken();

  @override
  Future<String?> getRefreshToken() => _secure.readRefreshToken();

  @override
  Future<void> clearTokens() => _secure.clearSession();

  @override
  Future<bool> hasTokens() async {
    final String? access = await getAccessToken();
    final String? refresh = await getRefreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }

  @override
  Future<bool> hasRefreshToken() async {
    final String? refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((Ref ref) {
  return SecureTokenStorage(ref.watch(secureStorageServiceProvider));
});

import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((Ref ref) {
  throw UnimplementedError(
    'flutterSecureStorageProvider must be overridden in bootstrap.',
  );
});

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> saveSessionJson(String json) {
    return _storage.write(key: StorageKeys.session, value: json);
  }

  Future<String?> readSessionJson() {
    return _storage.read(key: StorageKeys.session);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.session);
  }

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((Ref ref) {
  return SecureStorageService(ref.watch(flutterSecureStorageProvider));
});

import 'dart:convert';

import 'package:flutter_base/core/session/user_session.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persistence for an authenticated session. Auth will call this later.
/// The store never fabricates a user or company.
class SessionStore {
  const SessionStore(this._storage);

  final SecureStorageService _storage;

  Future<UserSession?> read() async {
    final String? raw = await _storage.readSessionJson();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final UserSession session = UserSession.fromJson(decoded);
      return session.hasTenantContext ? session : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UserSession session) {
    return _storage.saveSessionJson(jsonEncode(session.toJson()));
  }

  Future<void> clear() {
    return _storage.clearSession();
  }
}

final sessionStoreProvider = Provider<SessionStore>((Ref ref) {
  return SessionStore(ref.watch(secureStorageServiceProvider));
});

/// Always null until the auth feature persists a backend-issued session.
final currentSessionProvider = FutureProvider<UserSession?>((Ref ref) {
  return ref.watch(sessionStoreProvider).read();
});

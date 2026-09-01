import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Work that must run while the JWT is still valid, immediately before logout.
class LogoutSideEffects {
  final List<Future<void> Function()> _effects = <Future<void> Function()>[];

  void register(Future<void> Function() effect) {
    if (!_effects.contains(effect)) {
      _effects.add(effect);
    }
  }

  void unregister(Future<void> Function() effect) {
    _effects.remove(effect);
  }

  Future<void> run() async {
    final List<Future<void> Function()> snapshot =
        List<Future<void> Function()>.from(_effects);
    for (final Future<void> Function() effect in snapshot) {
      try {
        await effect();
      } catch (_) {
        // Logout must continue even if a side effect fails.
      }
    }
  }
}

final logoutSideEffectsProvider = Provider<LogoutSideEffects>((Ref ref) {
  return LogoutSideEffects();
});

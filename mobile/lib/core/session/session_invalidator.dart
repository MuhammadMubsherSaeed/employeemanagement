import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the Dio layer tell auth state that the session can no longer be recovered.
class SessionInvalidator {
  VoidCallback? _listener;

  void register(VoidCallback listener) {
    _listener = listener;
  }

  void unregister(VoidCallback listener) {
    if (identical(_listener, listener)) {
      _listener = null;
    }
  }

  void invalidate() {
    _listener?.call();
  }
}

final sessionInvalidatorProvider = Provider<SessionInvalidator>((Ref ref) {
  return SessionInvalidator();
});

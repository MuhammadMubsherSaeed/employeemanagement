import 'package:flutter_base/core/network/auth_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ensures concurrent 401s share a single refresh request.
class TokenRefreshCoordinator {
  Future<TokenPair?>? _inFlight;

  bool get isRefreshing => _inFlight != null;

  Future<TokenPair?> run(Future<TokenPair?> Function() refresh) {
    final Future<TokenPair?>? existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    final Future<TokenPair?> future = refresh().whenComplete(() {
      _inFlight = null;
    });
    _inFlight = future;
    return future;
  }
}

final tokenRefreshCoordinatorProvider = Provider<TokenRefreshCoordinator>(
  (Ref ref) => TokenRefreshCoordinator(),
);

import 'package:flutter_base/core/config/app_config_provider.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/token_refresh_coordinator.dart';
import 'package:flutter_base/core/session/session_invalidator.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    storage: ref.watch(secureStorageServiceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    refreshCoordinator: ref.watch(tokenRefreshCoordinatorProvider),
    onSessionInvalidated: () {
      ref.read(sessionInvalidatorProvider).invalidate();
    },
  );
});

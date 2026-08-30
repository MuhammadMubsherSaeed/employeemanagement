import 'package:flutter_base/core/config/env_config_provider.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(
    env: ref.watch(envConfigProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
});

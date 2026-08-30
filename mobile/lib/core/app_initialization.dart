import 'package:flutter_base/core/config/app_config_provider.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/shared_prefs_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppInitialization extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final config = ref.watch(appConfigProvider);
    if (config.apiBaseUrl.trim().isEmpty) {
      throw const UnknownException(
        'The application is not configured. Please try again.',
      );
    }

    ref.read(sharedPrefsServiceProvider);
    ref.read(secureStorageServiceProvider);
  }
}

final appInitializationProvider =
    AsyncNotifierProvider<AppInitialization, void>(AppInitialization.new);

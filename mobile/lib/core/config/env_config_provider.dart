import 'package:flutter_base/core/config/env_config.dart';
import 'package:flutter_base/env/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final envConfigProvider = Provider<EnvConfig>((Ref ref) {
  final bool isProduction =
      Env.appEnv.toLowerCase() == 'production' || Env.appEnv.toLowerCase() == 'live';

  if (isProduction) {
    return const EnvConfig(
      flavor: AppFlavor.production,
      apiBaseUrl: Env.baseApiUrlLive,
      appBaseUrl: Env.baseUrlLive,
      apiKey: Env.apiKeyLive,
      appKey: Env.appKeyLive,
    );
  }

  return const EnvConfig(
    flavor: AppFlavor.development,
    apiBaseUrl: Env.baseApiUrlDev,
    appBaseUrl: Env.baseUrlDev,
    apiKey: Env.apiKey,
    appKey: Env.appKey,
  );
});

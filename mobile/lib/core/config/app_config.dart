import 'package:flutter_base/core/config/app_environment.dart';

/// Public client configuration. Values shipped in the app are not secrets.
///
/// Override at build/run time with `--dart-define`:
/// `--dart-define=APP_ENV=staging`
/// `--dart-define=API_BASE_URL_STAGING=https://staging.example.com/api/v1/`
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableVerboseLogging,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableVerboseLogging;

  String get environmentName => environment.displayName;

  bool get isDebug => environment != AppEnvironment.production;

  factory AppConfig.fromEnvironment() {
    const String flavorName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const String devUrl = String.fromEnvironment(
      'API_BASE_URL_DEV',
      defaultValue: 'http://127.0.0.1:8000/api/v1/',
    );
    const String stagingUrl = String.fromEnvironment(
      'API_BASE_URL_STAGING',
      defaultValue: 'https://staging.example.com/api/v1/',
    );
    const String productionUrl = String.fromEnvironment(
      'API_BASE_URL_PROD',
      defaultValue: 'https://api.example.com/api/v1/',
    );

    final AppEnvironment environment = AppEnvironmentX.parse(flavorName);
    final String apiBaseUrl = switch (environment) {
      AppEnvironment.development => devUrl,
      AppEnvironment.staging => stagingUrl,
      AppEnvironment.production => productionUrl,
    };

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      enableVerboseLogging: environment == AppEnvironment.development,
    );
  }
}

import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment', () {
    test('parses known names', () {
      expect(AppEnvironmentX.parse('development'), AppEnvironment.development);
      expect(AppEnvironmentX.parse('staging'), AppEnvironment.staging);
      expect(AppEnvironmentX.parse('stage'), AppEnvironment.staging);
      expect(AppEnvironmentX.parse('production'), AppEnvironment.production);
      expect(AppEnvironmentX.parse('live'), AppEnvironment.production);
      expect(AppEnvironmentX.parse(null), AppEnvironment.development);
    });
  });

  group('AppConfig', () {
    test('defaults to development with a local API URL', () {
      final AppConfig config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.development);
      expect(config.apiBaseUrl, contains('api/v1'));
      expect(config.enableVerboseLogging, isTrue);
      expect(config.isDebug, isTrue);
    });

    test('staging and production can be constructed without dart-define', () {
      const AppConfig staging = AppConfig(
        environment: AppEnvironment.staging,
        apiBaseUrl: 'https://staging.example.com/api/v1/',
        enableVerboseLogging: false,
      );
      const AppConfig production = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://api.example.com/api/v1/',
        enableVerboseLogging: false,
      );

      expect(staging.environmentName, 'staging');
      expect(production.isDebug, isFalse);
      expect(production.enableVerboseLogging, isFalse);
    });
  });
}

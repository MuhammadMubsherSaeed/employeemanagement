enum AppEnvironment {
  development,
  staging,
  production,
}

extension AppEnvironmentX on AppEnvironment {
  String get displayName => name;

  bool get isProduction => this == AppEnvironment.production;

  bool get isDevelopment => this == AppEnvironment.development;

  static AppEnvironment parse(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
      case 'live':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }
}

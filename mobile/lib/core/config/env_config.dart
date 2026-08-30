/// Flavor and base URLs come from `.env` via [Env]. Never hardcode hosts here.
enum AppFlavor {
  development,
  production,
}

class EnvConfig {
  const EnvConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.appBaseUrl,
    required this.apiKey,
    required this.appKey,
  });

  final AppFlavor flavor;
  final String apiBaseUrl;
  final String appBaseUrl;
  final String apiKey;
  final String appKey;

  bool get isProduction => flavor == AppFlavor.production;
  bool get isDevelopment => flavor == AppFlavor.development;
}

class AppConstants {
  AppConstants._();

  static const String appName = 'HRMS';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const int dioTimeoutMs = 20000;
}

class ApiPaths {
  ApiPaths._();

  static const String health = '/api/health/';
  static const String apiV1Root = '';
}

class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String themeMode = 'theme_mode';
}

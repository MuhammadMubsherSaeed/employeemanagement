class AppConstants {
  AppConstants._();

  static const String appName = 'HRMS';
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
  static const int dioTimeoutMs = 20000;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int maxTextFieldLength = 500;
}

class ApiPaths {
  ApiPaths._();

  static const String health = '/api/health/';
  static const String v1 = '/api/v1';
  static const String authLogin = 'auth/login/';
  static const String authRefresh = 'auth/refresh/';
  static const String authLogout = 'auth/logout/';
  static const String authMe = 'auth/me/';
  static const String authForgotPassword = 'auth/forgot-password/';
  static const String authResetPassword = 'auth/reset-password/';
}

class ApiHeaders {
  ApiHeaders._();

  static const String accept = 'Accept';
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String requestId = 'X-Request-ID';
  static const String json = 'application/json';
}

class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String session = 'user_session';
  static const String themeMode = 'theme_mode';
  static const String onboardingComplete = 'onboarding_complete';
}

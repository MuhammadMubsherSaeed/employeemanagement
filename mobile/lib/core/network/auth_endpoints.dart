/// Paths relative to `AppConfig.apiBaseUrl` (`.../api/v1/`).
class AuthEndpoints {
  AuthEndpoints._();

  static const String login = 'auth/login/';
  static const String refresh = 'auth/refresh/';
  static const String logout = 'auth/logout/';
  static const String me = 'auth/me/';
  static const String forgotPassword = 'auth/forgot-password/';
  static const String resetPassword = 'auth/reset-password/';

  static const List<String> public = <String>[
    login,
    refresh,
    forgotPassword,
    resetPassword,
  ];

  static bool isPublic(String path) {
    final String normalized = Uri.tryParse(path)?.path.toLowerCase() ??
        path.toLowerCase();
    return public.any(
      (String suffix) =>
          normalized.endsWith(suffix) || normalized.contains('/$suffix'),
    );
  }
}

class AuthRequestExtra {
  AuthRequestExtra._();

  static const String skipAuthHeader = 'skipAuthHeader';
  static const String skipAuthRefresh = 'skipAuthRefresh';
  static const String authRetried = 'authRetried';
}

class TokenPair {
  const TokenPair({required this.access, this.refresh});

  final String access;
  final String? refresh;
}

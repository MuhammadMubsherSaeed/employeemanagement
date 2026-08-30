import 'package:flutter/foundation.dart';

/// Replaceable logging facade. Wire Crashlytics/Sentry later by swapping
/// the [AppLog] implementation — do not log secrets or employee PII.
abstract interface class AppLog {
  void debug(String message);

  void info(String message);

  void warning(String message);

  void error(String message, [Object? error, StackTrace? stackTrace]);
}

class ConsoleAppLogger implements AppLog {
  ConsoleAppLogger({required this.enableVerbose});

  final bool enableVerbose;

  @override
  void debug(String message) {
    if (enableVerbose && kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  @override
  void info(String message) {
    if (enableVerbose && kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  @override
  void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('$error');
      }
      if (stackTrace != null) {
        debugPrint('$stackTrace');
      }
    }
  }
}

/// Static entry point for bootstrap and interceptors.
class AppLogger {
  AppLogger._();

  static AppLog _instance = ConsoleAppLogger(enableVerbose: kDebugMode);

  static AppLog get instance => _instance;

  static void configure(AppLog logger) {
    _instance = logger;
  }

  static void debug(String message) => _instance.debug(message);

  static void info(String message) => _instance.info(message);

  static void warning(String message) => _instance.warning(message);

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _instance.error(message, error, stackTrace);
  }
}

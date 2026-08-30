import 'package:dio/dio.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/utils/app_logger.dart';

class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(
      ApiHeaders.requestId,
      () => '${DateTime.now().microsecondsSinceEpoch}-${options.hashCode}',
    );
    handler.next(options);
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SecureStorageService storage}) : _storage = storage;

  final SecureStorageService _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiHeaders.authorization] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Extension point for refresh-token. Auth will implement retry here later.
class TokenRefreshInterceptor extends Interceptor {
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.enabled});

  final bool enabled;

  static const Set<String> _sensitiveHeaderKeys = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-app-key',
  };

  static const Set<String> _sensitiveBodyKeys = <String>{
    'password',
    'access',
    'access_token',
    'refresh',
    'refresh_token',
    'token',
    'secret',
    'otp',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      final String? requestId =
          options.headers[ApiHeaders.requestId]?.toString();
      AppLogger.debug(
        '[API] ${options.method} ${options.uri}'
        '${requestId == null ? '' : ' [$requestId]'}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enabled) {
      AppLogger.debug(
        '[API] ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (enabled) {
      AppLogger.debug(
        '[API] ERROR ${err.response?.statusCode} ${err.requestOptions.uri}',
      );
    }
    handler.next(err);
  }

  /// Kept for future verbose body logging. Never call with raw maps in prod.
  static Map<String, dynamic> redact(Map<String, dynamic> input) {
    return input.map((String key, dynamic value) {
      if (_sensitiveHeaderKeys.contains(key.toLowerCase()) ||
          _sensitiveBodyKeys.contains(key.toLowerCase())) {
        return MapEntry<String, dynamic>(key, '***');
      }
      return MapEntry<String, dynamic>(key, value);
    });
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioError(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ErrorMapper.mapDio(err),
      ),
    );
  }
}

class DioInterceptorFactory {
  DioInterceptorFactory._();

  static List<Interceptor> build({
    required SecureStorageService storage,
    required bool enableLogging,
  }) {
    return <Interceptor>[
      RequestIdInterceptor(),
      AuthInterceptor(storage: storage),
      TokenRefreshInterceptor(),
      LoggingInterceptor(enabled: enableLogging),
      ErrorInterceptor(),
    ];
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/utils/app_logger.dart';

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
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
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

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.enabled});

  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      AppLogger.debug('[API] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
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
}

class DioInterceptorFactory {
  DioInterceptorFactory._();

  static List<Interceptor> build({
    required SecureStorageService storage,
    required bool enableLogging,
  }) {
    return <Interceptor>[
      AuthInterceptor(storage: storage),
      LoggingInterceptor(enabled: enableLogging),
      ErrorInterceptor(),
    ];
  }
}

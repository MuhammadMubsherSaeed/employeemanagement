import 'package:dio/dio.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/network/auth_endpoints.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/core/network/token_refresh_coordinator.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
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
    if (_shouldSkip(options)) {
      options.headers.remove(ApiHeaders.authorization);
      handler.next(options);
      return;
    }

    final String? token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiHeaders.authorization] = 'Bearer $token';
    }
    handler.next(options);
  }

  bool _shouldSkip(RequestOptions options) {
    if (options.extra[AuthRequestExtra.skipAuthHeader] == true) {
      return true;
    }
    return AuthEndpoints.isPublic(options.path) ||
        AuthEndpoints.isPublic(options.uri.path);
  }
}

/// Refreshes once per 401 wave, persists rotated tokens, retries the request.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required TokenRefreshCoordinator coordinator,
    void Function()? onSessionInvalidated,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _coordinator = coordinator,
        _onSessionInvalidated = onSessionInvalidated;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final TokenRefreshCoordinator _coordinator;
  final void Function()? _onSessionInvalidated;

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    if (_isRetriedUnauthorized(err)) {
      await _invalidateSession();
      handler.next(err);
      return;
    }

    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    try {
      final TokenPair? tokens = await _coordinator.run(_refreshTokens);
      if (tokens == null || tokens.access.isEmpty) {
        await _invalidateSession();
        handler.next(err);
        return;
      }

      final RequestOptions retry = err.requestOptions;
      retry.extra[AuthRequestExtra.authRetried] = true;
      retry.headers[ApiHeaders.authorization] = 'Bearer ${tokens.access}';
      final Response<dynamic> response = await _dio.fetch<dynamic>(retry);
      handler.resolve(response);
    } catch (_) {
      await _invalidateSession();
      handler.next(err);
    }
  }

  bool _shouldRefresh(DioError err) {
    if (err.response?.statusCode != 401) {
      return false;
    }
    if (err.requestOptions.extra[AuthRequestExtra.skipAuthRefresh] == true) {
      return false;
    }
    if (err.requestOptions.extra[AuthRequestExtra.authRetried] == true) {
      return false;
    }
    final String path = err.requestOptions.path;
    final String uriPath = err.requestOptions.uri.path;
    if (AuthEndpoints.isPublic(path) || AuthEndpoints.isPublic(uriPath)) {
      return false;
    }
    return true;
  }

  bool _isRetriedUnauthorized(DioError err) {
    return err.response?.statusCode == 401 &&
        err.requestOptions.extra[AuthRequestExtra.authRetried] == true;
  }

  Future<TokenPair?> _refreshTokens() async {
    final String? refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return null;
    }

    final Response<dynamic> response = await _dio.post<dynamic>(
      AuthEndpoints.refresh,
      data: <String, dynamic>{'refresh': refresh},
      options: Options(
        extra: <String, dynamic>{
          AuthRequestExtra.skipAuthHeader: true,
          AuthRequestExtra.skipAuthRefresh: true,
        },
      ),
    );

    final Map<String, dynamic> data =
        ApiEnvelope.parse(response.data).requireDataMap();
    final Object? accessRaw = data['access'];
    if (accessRaw is! String || accessRaw.isEmpty) {
      return null;
    }
    final Object? refreshRaw = data['refresh'];
    final String? nextRefresh =
        refreshRaw is String && refreshRaw.isNotEmpty ? refreshRaw : null;

    await _tokenStorage.saveTokens(
      accessToken: accessRaw,
      refreshToken: nextRefresh,
    );
    return TokenPair(access: accessRaw, refresh: nextRefresh);
  }

  Future<void> _invalidateSession() async {
    await _tokenStorage.clearTokens();
    _onSessionInvalidated?.call();
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
    required Dio dio,
    required TokenStorage tokenStorage,
    required TokenRefreshCoordinator coordinator,
    void Function()? onSessionInvalidated,
  }) {
    return <Interceptor>[
      RequestIdInterceptor(),
      AuthInterceptor(storage: storage),
      LoggingInterceptor(enabled: enableLogging),
      TokenRefreshInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        coordinator: coordinator,
        onSessionInvalidated: onSessionInvalidated,
      ),
      ErrorInterceptor(),
    ];
  }
}

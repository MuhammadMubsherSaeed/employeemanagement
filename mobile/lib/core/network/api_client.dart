import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/network/interceptors/dio_interceptors.dart';
import 'package:flutter_base/core/network/token_refresh_coordinator.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/token_storage.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureStorageService storage,
    TokenStorage? tokenStorage,
    TokenRefreshCoordinator? refreshCoordinator,
    void Function()? onSessionInvalidated,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.apiBaseUrl,
                connectTimeout: AppConstants.dioTimeoutMs,
                receiveTimeout: AppConstants.dioTimeoutMs,
                sendTimeout: AppConstants.dioTimeoutMs,
                headers: <String, dynamic>{
                  ApiHeaders.accept: ApiHeaders.json,
                  ApiHeaders.contentType: ApiHeaders.json,
                },
              ),
            ) {
    if (dio == null) {
      _dio.interceptors.addAll(
        DioInterceptorFactory.build(
          storage: storage,
          enableLogging: config.enableVerboseLogging,
          dio: _dio,
          tokenStorage: tokenStorage ?? SecureTokenStorage(storage),
          coordinator: refreshCoordinator ?? TokenRefreshCoordinator(),
          onSessionInvalidated: onSessionInvalidated,
        ),
      );
    }
  }

  final Dio _dio;

  Dio get engine => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on AppException {
      rethrow;
    } on DioError catch (error) {
      throw ErrorMapper.mapDio(error);
    } catch (_) {
      throw const UnknownException();
    }
  }
}

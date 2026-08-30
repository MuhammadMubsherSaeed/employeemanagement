import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/env_config.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/interceptors/dio_interceptors.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';

class ApiClient {
  ApiClient({
    required EnvConfig env,
    required SecureStorageService storage,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: env.apiBaseUrl,
                connectTimeout: AppConstants.dioTimeoutMs,
                receiveTimeout: AppConstants.dioTimeoutMs,
                headers: <String, dynamic>{
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  if (env.apiKey.isNotEmpty) 'X-API-KEY': env.apiKey,
                  if (env.appKey.isNotEmpty) 'X-APP-KEY': env.appKey,
                },
              ),
            ) {
    if (dio == null) {
      _dio.interceptors.addAll(
        DioInterceptorFactory.build(
          storage: storage,
          enableLogging: env.isDevelopment,
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
  }) {
    return _guard(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioError catch (error) {
      final Object? mapped = error.error;
      if (mapped is AppException) {
        throw mapped;
      }
      throw UnknownException(error.message);
    }
  }
}

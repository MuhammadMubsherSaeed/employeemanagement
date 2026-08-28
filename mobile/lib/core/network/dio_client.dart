import 'package:dio/dio.dart';

/// Target HTTP client for feature data sources.
/// Existing screens still use [networkRepositoryProvider] until they migrate.
class DioClient {
  DioClient({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: 20000,
                receiveTimeout: 20000,
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            );

  final Dio _dio;

  Dio get engine => _dio;
}

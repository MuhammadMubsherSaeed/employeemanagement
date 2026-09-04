import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hits the real Django health endpoint when `HRMS_LIVE_API_BASE_URL` is set.
///
/// Example:
/// `HRMS_LIVE_API_BASE_URL=http://127.0.0.1:8000/api/v1/ flutter test test/integration/live_django_health_test.dart`
///
/// Never put credentials in this file. Authenticated live checks belong in a
/// private local env, not source control.
void main() {
  final String base = (Platform.environment['HRMS_LIVE_API_BASE_URL'] ?? '')
      .trim();

  test(
    'GET /api/v1/health/ from the configured Django API',
    () async {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: base.endsWith('/') ? base : '$base/',
          connectTimeout: 8000,
          receiveTimeout: 8000,
        ),
      );
      final Response<dynamic> response = await dio.get<dynamic>('health/');
      expect(response.statusCode, 200);
      final Object? data = response.data;
      final Map<String, dynamic> body = data is Map<String, dynamic>
          ? data
          : jsonDecode(data.toString()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['message'], 'API is healthy.');
    },
    skip: base.isEmpty
        ? 'Set HRMS_LIVE_API_BASE_URL to run live Django API checks.'
        : false,
  );
}

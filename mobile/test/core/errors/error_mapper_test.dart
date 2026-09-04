import 'package:dio/dio.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/network/models/api_error_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RequestOptions options() => RequestOptions(path: '/sample');

  group('ApiErrorBody', () {
    test('parses the documented error shape', () {
      final ApiErrorBody body = ApiErrorBody.fromJson(<String, dynamic>{
        'success': false,
        'message': 'Invalid payload',
        'code': 'VALIDATION',
        'errors': <String, dynamic>{
          'email': <String>['Required'],
        },
      });

      expect(body.success, isFalse);
      expect(body.displayMessage, 'Invalid payload');
      expect(body.code, 'VALIDATION');
      expect(body.errors, isNotNull);
    });

    test('is defensive when the payload is unexpected', () {
      expect(ApiErrorBody.fromJson(null).displayMessage, isNull);
      expect(ApiErrorBody.fromJson(<String, dynamic>{}).code, isNull);
      expect(
        ApiErrorBody.fromJson('<html>oops</html>').displayMessage,
        isNull,
      );
      expect(
          ApiErrorBody.fromJson('Plain error').displayMessage, 'Plain error');
    });
  });

  group('ErrorMapper', () {
    test('maps timeouts', () {
      expect(
        ErrorMapper.mapDio(
          DioError(
              requestOptions: options(), type: DioErrorType.connectTimeout),
        ),
        isA<TimeoutException>(),
      );
    });

    test('maps connectivity failures', () {
      expect(
        ErrorMapper.mapDio(
          DioError(requestOptions: options(), type: DioErrorType.other),
        ),
        isA<NetworkException>(),
      );
    });

    test('maps 401 with backend message and code', () {
      final AppException exception = ErrorMapper.mapDio(
        DioError(
          requestOptions: options(),
          type: DioErrorType.response,
          response: Response<dynamic>(
            requestOptions: options(),
            statusCode: 401,
            data: <String, dynamic>{
              'success': false,
              'message': 'Token expired',
              'code': 'UNAUTHENTICATED',
            },
          ),
        ),
      );

      expect(exception, isA<UnauthorizedException>());
      expect(exception.message, 'Token expired');
      expect(exception.code, 'UNAUTHENTICATED');
    });

    test('maps 404, 403, 500', () {
      expect(
        ErrorMapper.fromResponse(
          Response<dynamic>(requestOptions: options(), statusCode: 404),
        ),
        isA<NotFoundException>(),
      );
      expect(
        ErrorMapper.fromResponse(
          Response<dynamic>(requestOptions: options(), statusCode: 403),
        ),
        isA<ForbiddenException>(),
      );
      expect(
        ErrorMapper.fromResponse(
          Response<dynamic>(requestOptions: options(), statusCode: 502),
        ),
        isA<ServerException>(),
      );
    });

    test('maps 409 conflicts and 429 rate limits', () {
      expect(
        ErrorMapper.fromResponse(
          Response<dynamic>(requestOptions: options(), statusCode: 409),
        ),
        isA<ConflictException>(),
      );
      expect(
        ErrorMapper.fromResponse(
          Response<dynamic>(
            requestOptions: options(),
            statusCode: 429,
            data: <String, dynamic>{'message': 'Slow down'},
          ),
        ),
        isA<RateLimitException>(),
      );
      expect(
        ErrorMapper.fromResponse(
          Response<dynamic>(
            requestOptions: options(),
            statusCode: 429,
            data: <String, dynamic>{'message': 'Slow down'},
          ),
        ).message,
        'Slow down',
      );
    });

    test('maps validation errors', () {
      final AppException exception = ErrorMapper.fromResponse(
        Response<dynamic>(
          requestOptions: options(),
          statusCode: 422,
          data: <String, dynamic>{
            'message': 'Check the form',
            'errors': <String, dynamic>{
              'name': <String>['Too short'],
            },
          },
        ),
      );

      expect(exception, isA<ValidationException>());
      expect(
        (exception as ValidationException).fieldErrors?['name'],
        <String>['Too short'],
      );
    });
  });
}

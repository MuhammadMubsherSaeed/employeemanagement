import 'package:dio/dio.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/models/api_error_body.dart';

class ErrorMapper {
  ErrorMapper._();

  static AppException map(Object error) {
    if (error is AppException) {
      return error;
    }
    if (error is DioError) {
      return mapDio(error);
    }
    return const UnknownException();
  }

  static AppException mapDio(DioError error) {
    final Object? mapped = error.error;
    if (mapped is AppException) {
      return mapped;
    }

    switch (error.type) {
      case DioErrorType.connectTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        return const TimeoutException();
      case DioErrorType.cancel:
        return const CancelledException();
      case DioErrorType.other:
        return const NetworkException();
      case DioErrorType.response:
        return fromResponse(error.response);
    }
  }

  static AppException fromResponse(Response<dynamic>? response) {
    final int status = response?.statusCode ?? 0;
    final ApiErrorBody body = ApiErrorBody.fromJson(response?.data);
    final String message = body.displayMessage ?? _fallback(status);

    switch (status) {
      case 400:
      case 422:
        return ValidationException(
          message,
          fieldErrors: _fieldErrors(body.errors, response?.data),
          code: body.code,
        );
      case 401:
        return UnauthorizedException(message, body.code);
      case 403:
        return ForbiddenException(message, body.code);
      case 404:
        return NotFoundException(message, body.code);
      default:
        if (status >= 500) {
          return ServerException(message, status, body.code);
        }
        return UnknownException(message, body.code);
    }
  }

  static Map<String, List<String>>? _fieldErrors(
    Map<String, dynamic>? errors,
    dynamic data,
  ) {
    final Map<String, dynamic>? source =
        errors ?? (data is Map ? Map<String, dynamic>.from(data) : null);
    if (source == null) {
      return null;
    }

    final Map<String, List<String>> mapped = <String, List<String>>{};
    source.forEach((String key, dynamic value) {
      if (key == 'detail' ||
          key == 'message' ||
          key == 'success' ||
          key == 'code') {
        return;
      }
      if (value is List) {
        mapped[key] = value.map((dynamic item) => item.toString()).toList();
      } else if (value is String && value.trim().isNotEmpty) {
        mapped[key] = <String>[value];
      } else if (value is Map) {
        mapped[key] =
            value.values.map((dynamic item) => item.toString()).toList();
      }
    });
    return mapped.isEmpty ? null : mapped;
  }

  static String _fallback(int status) {
    if (status >= 500) {
      return 'Something went wrong on the server.';
    }
    if (status == 0) {
      return 'Something went wrong.';
    }
    return 'Request failed ($status).';
  }
}

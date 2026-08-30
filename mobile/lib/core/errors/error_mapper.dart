import 'package:dio/dio.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/models/api_error_body.dart';

class ErrorMapper {
  ErrorMapper._();

  static AppException mapDio(DioError error) {
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
        return _fromResponse(error.response);
    }
  }

  static AppException _fromResponse(Response<dynamic>? response) {
    final int status = response?.statusCode ?? 0;
    final String message = _messageFromBody(response?.data) ?? _fallback(status);

    switch (status) {
      case 400:
      case 422:
        return ValidationException(message, fieldErrors: _fieldErrors(response?.data));
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      default:
        if (status >= 500) {
          return ServerException(message, status);
        }
        return UnknownException(message);
    }
  }

  static String? _messageFromBody(dynamic data) {
    if (data is String && data.trim().isNotEmpty && !data.contains('<html')) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      try {
        final ApiErrorBody body = ApiErrorBody.fromJson(data);
        if (body.detail != null && body.detail!.isNotEmpty) {
          return body.detail;
        }
        if (body.message != null && body.message!.isNotEmpty) {
          return body.message;
        }
      } catch (_) {
        final dynamic detail = data['detail'] ?? data['message'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    }
    return null;
  }

  static Map<String, List<String>>? _fieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final Map<String, List<String>> errors = <String, List<String>>{};
    data.forEach((String key, dynamic value) {
      if (key == 'detail' || key == 'message') {
        return;
      }
      if (value is List) {
        errors[key] = value.map((dynamic e) => e.toString()).toList();
      } else if (value is String) {
        errors[key] = <String>[value];
      }
    });
    return errors.isEmpty ? null : errors;
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

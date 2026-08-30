import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';

class AuthErrorMapper {
  AuthErrorMapper._();

  static const String invalidCredentials = 'Invalid email or password.';
  static const String accountInactive =
      'Your account is inactive. Please contact your administrator.';
  static const String network =
      'Unable to connect to the server. Please check your internet connection.';
  static const String sessionExpired =
      'Your session has expired. Please log in again.';
  static const String generic = 'Something went wrong. Please try again.';

  static String message(Object error) {
    final AppException exception = ErrorMapper.map(error);
    switch (exception.code) {
      case 'INVALID_CREDENTIALS':
        return invalidCredentials;
      case 'ACCOUNT_INACTIVE':
        return accountInactive;
      case 'TOKEN_EXPIRED':
      case 'TOKEN_INVALID':
      case 'TOKEN_BLACKLISTED':
      case 'UNAUTHORIZED':
        return sessionExpired;
      case 'PASSWORD_RESET_FAILED':
        return 'This reset link is invalid or has expired.';
    }

    if (exception is NetworkException) {
      return network;
    }
    if (exception is TimeoutException) {
      return 'The request timed out. Please try again.';
    }
    if (exception is UnauthorizedException) {
      return invalidCredentials;
    }
    if (exception is ForbiddenException) {
      return accountInactive;
    }
    if (exception is ValidationException) {
      return _validationMessage(exception);
    }
    final String trimmed = exception.message.trim();
    return trimmed.isEmpty ? generic : trimmed;
  }

  static String _validationMessage(ValidationException exception) {
    final Map<String, List<String>>? fields = exception.fieldErrors;
    if (fields != null && fields.isNotEmpty) {
      final List<String> first = fields.values.first;
      if (first.isNotEmpty && first.first.trim().isNotEmpty) {
        return first.first.trim();
      }
    }
    final String trimmed = exception.message.trim();
    return trimmed.isEmpty ? 'Please check the form and try again.' : trimmed;
  }
}

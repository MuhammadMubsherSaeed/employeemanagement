import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';

class AttendanceErrorMapper {
  AttendanceErrorMapper._();

  static const String generic = 'Something went wrong. Please try again.';
  static const String forbidden = 'You do not have access to this attendance.';
  static const String notFound = 'This attendance record could not be found.';
  static const String network =
      'Unable to connect to the server. Please check your internet connection.';

  static String message(Object error) {
    final AppException exception = ErrorMapper.map(error);
    if (exception is NetworkException) {
      return network;
    }
    if (exception is TimeoutException) {
      return 'The request timed out. Please try again.';
    }
    if (exception is ForbiddenException) {
      return forbidden;
    }
    if (exception is NotFoundException) {
      return notFound;
    }
    if (exception is UnauthorizedException) {
      return 'Please sign in again.';
    }
    if (exception is ValidationException) {
      final String trimmed = exception.message.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
      final Map<String, List<String>>? fields = exception.fieldErrors;
      if (fields != null && fields.isNotEmpty && fields.values.first.isNotEmpty) {
        return fields.values.first.first;
      }
    }
    final String trimmed = exception.message.trim();
    return trimmed.isEmpty ? generic : trimmed;
  }
}

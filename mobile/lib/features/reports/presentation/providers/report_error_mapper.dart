import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';

class ReportErrorMapper {
  ReportErrorMapper._();

  static const String generic = 'Something went wrong. Please try again.';
  static const String forbidden = 'You do not have access to this report.';
  static const String exportForbidden =
      'You do not have permission to export this report.';
  static const String notFound = 'The report could not be found.';
  static const String network =
      'Unable to connect to the server. Please check your internet connection.';
  static const String invalidRange = 'Start date cannot be after end date.';

  static String message(Object error, {bool export = false}) {
    final AppException exception = ErrorMapper.map(error);
    if (exception is NetworkException) {
      return network;
    }
    if (exception is TimeoutException) {
      return 'The request timed out. Please try again.';
    }
    if (exception is ForbiddenException) {
      return export ? exportForbidden : forbidden;
    }
    if (exception is NotFoundException) {
      return notFound;
    }
    if (exception is UnauthorizedException) {
      return 'Please sign in again.';
    }
    if (exception is ValidationException) {
      final String trimmed = exception.message.trim();
      if (trimmed.isNotEmpty && trimmed != 'Validation failed.') {
        return trimmed;
      }
      final List<String>? dateFrom = exception.fieldErrors?['date_from'];
      if (dateFrom != null && dateFrom.isNotEmpty) {
        return dateFrom.first;
      }
      final List<String>? format = exception.fieldErrors?['format'];
      if (format != null && format.isNotEmpty) {
        return format.first;
      }
    }
    final String trimmed = exception.message.trim();
    return trimmed.isEmpty ? generic : trimmed;
  }
}

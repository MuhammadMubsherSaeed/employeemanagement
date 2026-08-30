sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'The request timed out.']);
}

class CancelledException extends AppException {
  const CancelledException([super.message = 'The request was cancelled.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'Please sign in again.'])
      : super(message, statusCode: 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException([String message = 'You do not have access.'])
      : super(message, statusCode: 403);
}

class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'The requested resource was not found.',
  ]) : super(message, statusCode: 404);
}

class ValidationException extends AppException {
  const ValidationException(String message, {this.fieldErrors})
      : super(message, statusCode: 400);

  final Map<String, List<String>>? fieldErrors;
}

class ServerException extends AppException {
  const ServerException([
    String message = 'Something went wrong on the server.',
    int statusCode = 500,
  ]) : super(message, statusCode: statusCode);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong.']);
}

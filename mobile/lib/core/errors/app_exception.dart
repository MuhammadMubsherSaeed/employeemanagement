// ignore_for_file: use_super_parameters

sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    String message = 'No internet connection.',
    String? code,
  ]) : super(message, code: code);
}

class TimeoutException extends AppException {
  const TimeoutException([
    String message = 'The request timed out.',
    String? code,
  ]) : super(message, code: code);
}

class CancelledException extends AppException {
  const CancelledException([super.message = 'The request was cancelled.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    String message = 'Please sign in again.',
    String? code,
  ]) : super(message, statusCode: 401, code: code);
}

class ForbiddenException extends AppException {
  const ForbiddenException([
    String message = 'You do not have access.',
    String? code,
  ]) : super(message, statusCode: 403, code: code);
}

class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'The requested resource was not found.',
    String? code,
  ]) : super(message, statusCode: 404, code: code);
}

class ValidationException extends AppException {
  const ValidationException(
    String message, {
    this.fieldErrors,
    String? code,
  }) : super(message, statusCode: 400, code: code);

  final Map<String, List<String>>? fieldErrors;
}

class ConflictException extends AppException {
  const ConflictException([
    String message = 'This action conflicts with the current state.',
    String? code,
  ]) : super(message, statusCode: 409, code: code);
}

class RateLimitException extends AppException {
  const RateLimitException([
    String message = 'Too many requests. Please wait and try again.',
    String? code,
  ]) : super(message, statusCode: 429, code: code);
}

class ServerException extends AppException {
  const ServerException([
    String message = 'Something went wrong on the server.',
    int statusCode = 500,
    String? code,
  ]) : super(message, statusCode: statusCode, code: code);
}

class UnknownException extends AppException {
  const UnknownException([
    String message = 'Something went wrong.',
    String? code,
  ]) : super(message, code: code);
}

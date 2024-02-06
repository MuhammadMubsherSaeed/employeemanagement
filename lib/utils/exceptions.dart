import 'package:dio/dio.dart';

import 'constants.dart';

class DataException implements Exception {
  DataException({required this.message});

  DataException.fromDioError(DioError dioError) {
    switch (dioError.type) {
      case DioErrorType.cancel:
        message = Constants.errorRequestCancelled;
        break;
      case DioErrorType.connectTimeout:
        message = Constants.errorConnectionTimeout;
        break;
      case DioErrorType.receiveTimeout:
        message = Constants.errorReceiveTimeout;
        break;
      case DioErrorType.response:
        message = _handleError(
            dioError.response!.statusCode!, dioError.response!.statusMessage!);
        break;
      case DioErrorType.sendTimeout:
        message = Constants.errorSendTimeout;
        break;
      default:
        message = Constants.errorInternetConnection;
        break;
    }
  }

  String message = "";

  String _handleError(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return Constants.errorBadRequest;
      case 403:
        return message;
      case 401:
        return message;
      case 404:
        return Constants.errorRequestNotFound;
      case 500:
        return Constants.errorInternalServer;
      default:
        return Constants.errorSomethingWentWrong;
    }
  }

  @override
  String toString() => message;
}

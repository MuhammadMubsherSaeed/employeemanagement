import 'dart:io';

class Constants {
  static const dbName = 'QuaidReceptionDB';
  static const attendanceTypeManual = 'Manually';
  static const attendanceTypeAuto = 'Auto';
  static const entryTypeIn = 'In';
  static const entryTypeOut = 'Out';
  static bool isFakeLocationAllowed = Platform.isAndroid ? true : true;
  static const markAttendanceFromRadius = true;
  static const errorRequestCancelled = 'errorRequestCancelled';
  static const errorConnectionTimeout = 'Connection Timeout';
  static const errorInternetConnection =
      'Please check your Internet Connection';
  static const errorReceiveTimeout = 'errorReceiveTimeout';
  static const errorSendTimeout = 'errorSendTimeout';
  static const errorBadRequest = 'Bad Request';
  static const errorRequestNotFound = 'Request Not Found';

  static const errorInternalServer = 'Internal Server Error';
  static const errorSomethingWentWrong = 'Error Something Went Wrong';
  static int showLogs = 1;
  static int connectionTimeOut = 60000;

  static const String PUBLIC_KEY = "your_public_key_here";
}

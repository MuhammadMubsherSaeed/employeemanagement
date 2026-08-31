/// Paths relative to `AppConfig.apiBaseUrl` (`.../api/v1/`).
class AttendanceEndpoints {
  AttendanceEndpoints._();

  static const String attendance = 'attendance/';
  static const String me = 'attendance/me/';
  static const String checkIn = 'attendance/check-in/';
  static const String checkOut = 'attendance/check-out/';
  static const String summary = 'attendance/summary/';

  static String detail(String id) => 'attendance/$id/';
}

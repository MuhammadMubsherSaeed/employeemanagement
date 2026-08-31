class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String splash = '/splash';
  static const String home = '/home';
  static const String error = '/error';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  /// Future routes — names only. Do not add screens until those features exist.
  static const String dashboard = '/dashboard';
  static const String employees = '/employees';
  static const String employeesAdd = '/employees/add';
  static const String employeesMe = '/employees/me';
  static const String attendance = '/attendance';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceCalendar = '/attendance/calendar';
  static const String leaves = '/leaves';
  static const String devices = '/devices';
  static const String reports = '/reports';
  static const String ai = '/ai';
  static const String settings = '/settings';

  static String employee(String id) => '/employees/$id';

  static String employeeEdit(String id) => '/employees/$id/edit';

  static String attendanceDetail(String id) => '/attendance/$id';
}

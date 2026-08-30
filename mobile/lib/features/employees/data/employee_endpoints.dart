/// Paths relative to `AppConfig.apiBaseUrl` (`.../api/v1/`).
class EmployeeEndpoints {
  EmployeeEndpoints._();

  static const String employees = 'employees/';
  static const String me = 'employees/me/';
  static const String departments = 'departments/';
  static const String positions = 'positions/';

  static String employee(String id) => 'employees/$id/';
}

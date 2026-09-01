/// Paths relative to `AppConfig.apiBaseUrl` (`.../api/v1/`).
class LeaveEndpoints {
  LeaveEndpoints._();

  static const String types = 'leave/types/';
  static const String balances = 'leave/balances/';
  static const String requests = 'leave/requests/';

  static String type(String id) => 'leave/types/$id/';

  static String balance(String id) => 'leave/balances/$id/';

  static String request(String id) => 'leave/requests/$id/';

  static String approve(String id) => 'leave/requests/$id/approve/';

  static String reject(String id) => 'leave/requests/$id/reject/';

  static String cancel(String id) => 'leave/requests/$id/cancel/';

  static String attachment(String id) => 'leave/requests/$id/attachment/';
}

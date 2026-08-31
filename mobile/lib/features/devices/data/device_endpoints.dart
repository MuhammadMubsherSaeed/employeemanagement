/// Paths relative to `AppConfig.apiBaseUrl` (`.../api/v1/`).
class DeviceEndpoints {
  DeviceEndpoints._();

  static const String devices = 'devices/';

  static String device(String id) => 'devices/$id/';

  static String assign(String id) => 'devices/$id/assign/';

  static String returnDevice(String id) => 'devices/$id/return/';

  static String history(String id) => 'devices/$id/history/';
}

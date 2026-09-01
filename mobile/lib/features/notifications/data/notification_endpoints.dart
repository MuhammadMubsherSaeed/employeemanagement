/// Paths relative to `AppConfig.apiBaseUrl` (`.../api/v1/`).
class NotificationEndpoints {
  NotificationEndpoints._();

  static const String notifications = 'notifications/';
  static const String unreadCount = 'notifications/unread-count/';
  static const String markAllRead = 'notifications/mark-all-read/';
  static const String deviceTokens = 'notifications/device-tokens/';

  static String notification(String id) => 'notifications/$id/';

  static String markRead(String id) => 'notifications/$id/mark-read/';

  static String deviceToken(String id) => 'notifications/device-tokens/$id/';
}

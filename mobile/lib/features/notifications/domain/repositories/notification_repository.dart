import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';

abstract class NotificationRepository {
  Future<NotificationPage<AppNotification>> getNotifications(
    NotificationQuery query,
  );

  Future<AppNotification> getNotificationDetail(String id);

  Future<int> getUnreadCount();

  Future<AppNotification> markAsRead(String id);

  Future<int> markAllAsRead();

  Future<DeviceTokenRegistration> registerDeviceToken(
    RegisterDeviceTokenBody body,
  );

  Future<DeviceTokenRegistration> updateDeviceToken(
    String id,
    UpdateDeviceTokenBody body,
  );

  Future<void> removeDeviceToken(String id);
}

import 'package:flutter_base/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<NotificationPage<AppNotification>> getNotifications(
    NotificationQuery query,
  ) {
    return _remote.getNotifications(query);
  }

  @override
  Future<AppNotification> getNotificationDetail(String id) {
    return _remote.getNotification(id);
  }

  @override
  Future<int> getUnreadCount() {
    return _remote.getUnreadCount();
  }

  @override
  Future<AppNotification> markAsRead(String id) {
    return _remote.markAsRead(id);
  }

  @override
  Future<int> markAllAsRead() {
    return _remote.markAllAsRead();
  }

  @override
  Future<DeviceTokenRegistration> registerDeviceToken(
    RegisterDeviceTokenBody body,
  ) {
    return _remote.registerDeviceToken(body);
  }

  @override
  Future<DeviceTokenRegistration> updateDeviceToken(
    String id,
    UpdateDeviceTokenBody body,
  ) {
    return _remote.updateDeviceToken(id, body);
  }

  @override
  Future<void> removeDeviceToken(String id) {
    return _remote.removeDeviceToken(id);
  }
}

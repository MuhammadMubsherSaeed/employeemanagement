import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/domain/repositories/notification_repository.dart';

class GetNotifications {
  const GetNotifications(this._repository);

  final NotificationRepository _repository;

  Future<NotificationPage<AppNotification>> call(NotificationQuery query) {
    return _repository.getNotifications(query);
  }
}

class GetNotificationDetail {
  const GetNotificationDetail(this._repository);

  final NotificationRepository _repository;

  Future<AppNotification> call(String id) {
    return _repository.getNotificationDetail(id);
  }
}

class GetUnreadNotificationCount {
  const GetUnreadNotificationCount(this._repository);

  final NotificationRepository _repository;

  Future<int> call() {
    return _repository.getUnreadCount();
  }
}

class MarkNotificationAsRead {
  const MarkNotificationAsRead(this._repository);

  final NotificationRepository _repository;

  Future<AppNotification> call(String id) {
    return _repository.markAsRead(id);
  }
}

class MarkAllNotificationsAsRead {
  const MarkAllNotificationsAsRead(this._repository);

  final NotificationRepository _repository;

  Future<int> call() {
    return _repository.markAllAsRead();
  }
}

class RegisterDeviceToken {
  const RegisterDeviceToken(this._repository);

  final NotificationRepository _repository;

  Future<DeviceTokenRegistration> call(RegisterDeviceTokenBody body) {
    return _repository.registerDeviceToken(body);
  }
}

class UpdateDeviceToken {
  const UpdateDeviceToken(this._repository);

  final NotificationRepository _repository;

  Future<DeviceTokenRegistration> call(
    String id,
    UpdateDeviceTokenBody body,
  ) {
    return _repository.updateDeviceToken(id, body);
  }
}

class RemoveDeviceToken {
  const RemoveDeviceToken(this._repository);

  final NotificationRepository _repository;

  Future<void> call(String id) {
    return _repository.removeDeviceToken(id);
  }
}

import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/domain/services/push_payload.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/notification_fakes.dart';

void main() {
  test('parses list JSON and keeps updatedAt optional', () {
    final AppNotification item =
        AppNotification.fromJson(sampleNotificationJson());
    expect(item.id, 'n-1');
    expect(item.type, AppNotificationType.system);
    expect(item.title, 'System notice');
    expect(item.isRead, isFalse);
    expect(item.updatedAt, isNull);
    expect(item.metadata['leave_status'], 'APPROVED');
    expect(item.createdAt, isNotNull);
  });

  test('parses detail JSON including updated_at', () {
    final AppNotification item = AppNotification.fromJson(
      sampleNotificationJson(detail: true, isRead: true),
    );
    expect(item.isRead, isTrue);
    expect(item.readAt, isNotNull);
    expect(item.updatedAt, isNotNull);
  });

  test('unknown notification types do not crash', () {
    expect(
      AppNotificationType.fromApi('FUTURE_EVENT'),
      AppNotificationType.unknown,
    );
    expect(AppNotificationType.fromApi(null), AppNotificationType.unknown);
    expect(
      AppNotificationType.fromApi('leave_approved'),
      AppNotificationType.leaveApproved,
    );
    expect(
      NotificationEntityType.fromApi('leave_request'),
      NotificationEntityType.leaveRequest,
    );
    expect(
      NotificationEntityType.fromApi('mystery'),
      NotificationEntityType.unknown,
    );
  });

  test('nullable entity and metadata handling', () {
    final AppNotification item = AppNotification.fromJson(
      const <String, dynamic>{
        'id': 'n-2',
        'type': 'ATTENDANCE_REMINDER',
        'title': 'Check in',
        'message': 'Please check in',
        'entity_type': '',
        'entity_id': '',
        'metadata': null,
        'is_read': false,
        'created_at': '2026-03-01T10:00:00Z',
      },
    );
    expect(item.hasEntity, isFalse);
    expect(item.entityId, isNull);
    expect(item.metadata, isEmpty);
    expect(item.type, AppNotificationType.attendanceReminder);
  });

  test('query parameters match the Django notification filter contract', () {
    final DateTime after = DateTime.utc(2026, 1, 1);
    final NotificationQuery query = NotificationQuery(
      isRead: false,
      type: AppNotificationType.leaveApproved,
      createdAtAfter: after,
      page: 2,
    );
    expect(
      query.toQueryParameters(),
      <String, dynamic>{
        'is_read': false,
        'type': 'LEAVE_APPROVED',
        'created_at_after': after.toIso8601String(),
        'page': 2,
        'page_size': 20,
      },
    );
    expect(
      const NotificationQuery(type: AppNotificationType.unknown)
          .toQueryParameters(),
      <String, dynamic>{'page': 1, 'page_size': 20},
    );
  });

  test('device token register body omits user_id and company_id', () {
    const RegisterDeviceTokenBody body = RegisterDeviceTokenBody(
      token: 'fcm-token-12345678',
      platform: DeviceTokenPlatform.android,
      deviceName: 'Pixel',
    );
    expect(
      body.toJson(),
      <String, dynamic>{
        'token': 'fcm-token-12345678',
        'platform': 'ANDROID',
        'device_name': 'Pixel',
      },
    );
    expect(body.toJson().containsKey('user_id'), isFalse);
    expect(body.toJson().containsKey('company_id'), isFalse);
  });

  test('push payload prefers backend snake_case keys', () {
    final PushPayload payload = PushPayload.fromData(
      const <String, dynamic>{
        'notification_id': 'n-9',
        'notification_type': 'DEVICE_ASSIGNED',
        'entity_type': 'device',
        'entity_id': 'dev-1',
      },
      title: 'Assigned',
    );
    expect(payload.notificationId, 'n-9');
    expect(payload.notificationType, AppNotificationType.deviceAssigned);
    expect(payload.entityType, NotificationEntityType.device);
    expect(payload.entityId, 'dev-1');
    expect(payload.hasNotificationId, isTrue);
  });
}

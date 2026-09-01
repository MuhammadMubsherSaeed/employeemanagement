import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';

class PushPayload extends Equatable {
  const PushPayload({
    this.notificationId,
    this.notificationType = AppNotificationType.unknown,
    this.entityType = NotificationEntityType.unknown,
    this.entityId,
    this.title,
    this.body,
    this.messageId,
  });

  final String? notificationId;
  final AppNotificationType notificationType;
  final NotificationEntityType entityType;
  final String? entityId;
  final String? title;
  final String? body;
  final String? messageId;

  bool get hasNotificationId =>
      notificationId != null && notificationId!.trim().isNotEmpty;

  factory PushPayload.fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
    String? messageId,
  }) {
    final Map<String, String> normalized = <String, String>{};
    data.forEach((String key, dynamic value) {
      if (value == null) {
        return;
      }
      normalized[key] = value.toString();
    });
    return PushPayload(
      notificationId: _first(normalized, const <String>[
        'notification_id',
        'notificationId',
      ]),
      notificationType: AppNotificationType.fromApi(
        _first(normalized, const <String>[
          'notification_type',
          'notificationType',
          'type',
        ]),
      ),
      entityType: NotificationEntityType.fromApi(
        _first(normalized, const <String>['entity_type', 'entityType']),
      ),
      entityId: _first(normalized, const <String>['entity_id', 'entityId']),
      title: title,
      body: body,
      messageId: messageId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        notificationId,
        notificationType,
        entityType,
        entityId,
        title,
        body,
        messageId,
      ];
}

String? _first(Map<String, String> data, List<String> keys) {
  for (final String key in keys) {
    final String? value = data[key];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

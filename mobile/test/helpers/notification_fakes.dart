import 'dart:async';

import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flutter_base/features/notifications/domain/services/fcm_gateway.dart';
import 'package:flutter_base/features/notifications/domain/services/push_payload.dart';

AppNotification sampleNotification({
  String id = 'n-1',
  AppNotificationType type = AppNotificationType.system,
  String title = 'System notice',
  String message = 'Hello',
  NotificationEntityType entityType = NotificationEntityType.unknown,
  String? entityId,
  bool isRead = false,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? readAt,
  Map<String, dynamic> metadata = const <String, dynamic>{},
}) {
  return AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    entityType: entityType,
    entityId: entityId,
    metadata: metadata,
    isRead: isRead,
    readAt: readAt,
    createdAt: createdAt ?? DateTime.parse('2026-03-01T10:00:00Z'),
    updatedAt: updatedAt,
  );
}

Map<String, dynamic> sampleNotificationJson({
  String id = 'n-1',
  String type = 'SYSTEM',
  String title = 'System notice',
  String message = 'Hello',
  String entityType = '',
  String entityId = '',
  bool isRead = false,
  bool detail = false,
}) {
  final Map<String, dynamic> json = <String, dynamic>{
    'id': id,
    'type': type,
    'title': title,
    'message': message,
    'entity_type': entityType,
    'entity_id': entityId,
    'metadata': <String, dynamic>{'leave_status': 'APPROVED'},
    'is_read': isRead,
    'read_at': isRead ? '2026-03-01T11:00:00Z' : null,
    'created_at': '2026-03-01T10:00:00Z',
  };
  if (detail) {
    json['updated_at'] = '2026-03-01T11:00:00Z';
  }
  return json;
}

Map<String, dynamic> sampleDeviceTokenJson({
  String id = 'tok-1',
  String platform = 'ANDROID',
}) {
  return <String, dynamic>{
    'id': id,
    'platform': platform,
    'device_name': 'Android',
    'is_active': true,
    'last_seen_at': '2026-03-01T10:00:00Z',
    'created_at': '2026-03-01T10:00:00Z',
    'updated_at': '2026-03-01T10:00:00Z',
  };
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    List<AppNotification>? items,
    this.unreadCount = 2,
  }) : items = items ?? <AppNotification>[sampleNotification()];

  List<AppNotification> items;
  int unreadCount;
  Duration delay = Duration.zero;
  Object? listError;
  Object? detailError;
  Object? unreadError;
  Object? markError;
  Object? markAllError;
  Object? registerError;
  Object? updateError;
  Object? removeError;
  int listCalls = 0;
  int detailCalls = 0;
  int unreadCalls = 0;
  int markCalls = 0;
  int markAllCalls = 0;
  int registerCalls = 0;
  int updateCalls = 0;
  int removeCalls = 0;
  final List<NotificationQuery> listQueries = <NotificationQuery>[];
  String? lastId;
  RegisterDeviceTokenBody? lastRegister;
  UpdateDeviceTokenBody? lastUpdate;
  NotificationPage<AppNotification> Function(NotificationQuery query)?
      pageBuilder;

  Future<void> _wait() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  @override
  Future<NotificationPage<AppNotification>> getNotifications(
    NotificationQuery query,
  ) async {
    listCalls += 1;
    listQueries.add(query);
    await _wait();
    if (listError != null) {
      throw listError!;
    }
    if (pageBuilder != null) {
      return pageBuilder!(query);
    }
    return NotificationPage<AppNotification>(
      results: items,
      count: items.length,
    );
  }

  @override
  Future<AppNotification> getNotificationDetail(String id) async {
    detailCalls += 1;
    lastId = id;
    await _wait();
    if (detailError != null) {
      throw detailError!;
    }
    return items.firstWhere(
      (AppNotification item) => item.id == id,
      orElse: () => sampleNotification(id: id),
    );
  }

  @override
  Future<int> getUnreadCount() async {
    unreadCalls += 1;
    await _wait();
    if (unreadError != null) {
      throw unreadError!;
    }
    return unreadCount;
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    markCalls += 1;
    lastId = id;
    await _wait();
    if (markError != null) {
      throw markError!;
    }
    return sampleNotification(id: id, isRead: true, title: 'System notice');
  }

  @override
  Future<int> markAllAsRead() async {
    markAllCalls += 1;
    await _wait();
    if (markAllError != null) {
      throw markAllError!;
    }
    return items.where((AppNotification item) => !item.isRead).length;
  }

  @override
  Future<DeviceTokenRegistration> registerDeviceToken(
    RegisterDeviceTokenBody body,
  ) async {
    registerCalls += 1;
    lastRegister = body;
    await _wait();
    if (registerError != null) {
      throw registerError!;
    }
    return DeviceTokenRegistration(
      id: 'tok-1',
      platform: body.platform,
      deviceName: body.deviceName,
    );
  }

  @override
  Future<DeviceTokenRegistration> updateDeviceToken(
    String id,
    UpdateDeviceTokenBody body,
  ) async {
    updateCalls += 1;
    lastId = id;
    lastUpdate = body;
    await _wait();
    if (updateError != null) {
      throw updateError!;
    }
    return DeviceTokenRegistration(
      id: id,
      platform: body.platform ?? DeviceTokenPlatform.android,
    );
  }

  @override
  Future<void> removeDeviceToken(String id) async {
    removeCalls += 1;
    lastId = id;
    await _wait();
    if (removeError != null) {
      throw removeError!;
    }
  }
}

class FakeNotificationRemote implements NotificationRemoteDataSource {
  FakeNotificationRemote({
    NotificationPage<AppNotification>? page,
    this.detail,
    this.unreadCount = 2,
    this.updated = 3,
    this.token,
  }) : page = page ??
            NotificationPage<AppNotification>(
              results: <AppNotification>[sampleNotification()],
              count: 1,
            );

  NotificationPage<AppNotification> page;
  AppNotification? detail;
  int unreadCount;
  int updated;
  DeviceTokenRegistration? token;
  NotificationQuery? lastQuery;
  String? lastId;
  RegisterDeviceTokenBody? lastRegister;
  UpdateDeviceTokenBody? lastUpdate;

  @override
  Future<NotificationPage<AppNotification>> getNotifications(
    NotificationQuery query,
  ) async {
    lastQuery = query;
    return page;
  }

  @override
  Future<AppNotification> getNotification(String id) async {
    lastId = id;
    return detail ?? sampleNotification(id: id);
  }

  @override
  Future<int> getUnreadCount() async => unreadCount;

  @override
  Future<AppNotification> markAsRead(String id) async {
    lastId = id;
    return sampleNotification(id: id, isRead: true);
  }

  @override
  Future<int> markAllAsRead() async => updated;

  @override
  Future<DeviceTokenRegistration> registerDeviceToken(
    RegisterDeviceTokenBody body,
  ) async {
    lastRegister = body;
    return token ??
        DeviceTokenRegistration(id: 'tok-1', platform: body.platform);
  }

  @override
  Future<DeviceTokenRegistration> updateDeviceToken(
    String id,
    UpdateDeviceTokenBody body,
  ) async {
    lastId = id;
    lastUpdate = body;
    return token ??
        DeviceTokenRegistration(
          id: id,
          platform: body.platform ?? DeviceTokenPlatform.android,
        );
  }

  @override
  Future<void> removeDeviceToken(String id) async {
    lastId = id;
  }
}

class FakeFcmGateway implements FcmGateway {
  FakeFcmGateway({
    this.available = true,
    this.token = 'fcm-token-12345678',
    this.initial,
  });

  bool available;
  String? token;
  PushMessage? initial;
  int permissionCalls = 0;
  final StreamController<String> tokenRefresh = StreamController<String>.broadcast();
  final StreamController<PushMessage> foreground =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> opened =
      StreamController<PushMessage>.broadcast();

  @override
  bool get isAvailable => available;

  @override
  Future<void> requestPermission() async {
    permissionCalls += 1;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initial;
}

PushMessage samplePushMessage({
  String notificationId = 'n-1',
  String? messageId = 'msg-1',
  String title = 'Hello',
  String body = 'World',
}) {
  return PushMessage(
    payload: PushPayload(
      notificationId: notificationId,
      title: title,
      body: body,
      messageId: messageId,
    ),
    title: title,
    body: body,
    messageId: messageId,
  );
}

const NetworkException sampleNetworkError = NetworkException();

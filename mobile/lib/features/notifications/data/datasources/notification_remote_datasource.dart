import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/notifications/data/notification_endpoints.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPage<AppNotification>> getNotifications(
    NotificationQuery query,
  );

  Future<AppNotification> getNotification(String id);

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

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<NotificationPage<AppNotification>> getNotifications(
    NotificationQuery query,
  ) async {
    final response = await _client.get<dynamic>(
      NotificationEndpoints.notifications,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, AppNotification.fromJson);
  }

  @override
  Future<AppNotification> getNotification(String id) async {
    final response = await _client.get<dynamic>(
      NotificationEndpoints.notification(id),
    );
    return AppNotification.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get<dynamic>(
      NotificationEndpoints.unreadCount,
    );
    return _readInt(_data(_envelope(response.data))['count']);
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    final response = await _client.post<dynamic>(
      NotificationEndpoints.markRead(id),
    );
    return AppNotification.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _client.post<dynamic>(
      NotificationEndpoints.markAllRead,
    );
    return _readInt(_data(_envelope(response.data))['updated']);
  }

  @override
  Future<DeviceTokenRegistration> registerDeviceToken(
    RegisterDeviceTokenBody body,
  ) async {
    final response = await _client.post<dynamic>(
      NotificationEndpoints.deviceTokens,
      data: body.toJson(),
    );
    return DeviceTokenRegistration.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<DeviceTokenRegistration> updateDeviceToken(
    String id,
    UpdateDeviceTokenBody body,
  ) async {
    final response = await _client.patch<dynamic>(
      NotificationEndpoints.deviceToken(id),
      data: body.toJson(),
    );
    return DeviceTokenRegistration.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<void> removeDeviceToken(String id) async {
    await _client.delete<dynamic>(NotificationEndpoints.deviceToken(id));
  }

  NotificationPage<T> _page<T>(
    dynamic raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final Map<String, dynamic> data = _data(_envelope(raw));
    final Object? results = data['results'];
    final List<T> items = <T>[];
    if (results is List) {
      for (final Object? row in results) {
        if (row is Map) {
          items.add(parse(Map<String, dynamic>.from(row)));
        }
      }
    }
    return NotificationPage<T>(
      results: items,
      count: _readInt(data['count'], fallback: items.length),
      next: data['next']?.toString(),
      previous: data['previous']?.toString(),
    );
  }

  Map<String, dynamic> _data(ApiEnvelope envelope) {
    try {
      return envelope.requireDataMap();
    } on FormatException {
      throw const UnknownException();
    }
  }

  ApiEnvelope _envelope(dynamic data) {
    try {
      final ApiEnvelope envelope = ApiEnvelope.parse(data);
      if (!envelope.success && envelope.data == null) {
        throw UnknownException(envelope.message ?? 'Request failed.');
      }
      return envelope;
    } on FormatException {
      throw const UnknownException();
    }
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

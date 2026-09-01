import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.entityType = NotificationEntityType.unknown,
    this.entityId,
    this.metadata = const <String, dynamic>{},
    this.isRead = false,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final NotificationEntityType entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasEntity =>
      entityType != NotificationEntityType.unknown &&
      entityId != null &&
      entityId!.trim().isNotEmpty;

  String get displayTitle => title.trim().isEmpty ? type.label : title;

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
    DateTime? updatedAt,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _readString(json['id']),
      type: AppNotificationType.fromApi(_readString(json['type'])),
      title: _readString(json['title']),
      message: _readString(json['message']),
      entityType: NotificationEntityType.fromApi(
        _readOptionalString(json['entity_type']),
      ),
      entityId: _readOptionalString(json['entity_id']),
      metadata: _readMetadata(json['metadata']),
      isRead: json['is_read'] == true,
      readAt: _readDateTime(json['read_at']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        type,
        title,
        message,
        entityType,
        entityId,
        metadata,
        isRead,
        readAt,
        createdAt,
        updatedAt,
      ];
}

class DeviceTokenRegistration extends Equatable {
  const DeviceTokenRegistration({
    required this.id,
    required this.platform,
    this.deviceName = '',
    this.isActive = true,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DeviceTokenPlatform platform;
  final String deviceName;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeviceTokenRegistration.fromJson(Map<String, dynamic> json) {
    return DeviceTokenRegistration(
      id: _readString(json['id']),
      platform: DeviceTokenPlatform.fromApi(_readString(json['platform'])),
      deviceName: _readString(json['device_name']),
      isActive: json['is_active'] != false,
      lastSeenAt: _readDateTime(json['last_seen_at']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        platform,
        deviceName,
        isActive,
        lastSeenAt,
        createdAt,
        updatedAt,
      ];
}

class RegisterDeviceTokenBody extends Equatable {
  const RegisterDeviceTokenBody({
    required this.token,
    this.platform = DeviceTokenPlatform.unknown,
    this.deviceName = '',
  });

  final String token;
  final DeviceTokenPlatform platform;
  final String deviceName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token.trim(),
      'platform': platform.apiValue,
      if (deviceName.trim().isNotEmpty) 'device_name': deviceName.trim(),
    };
  }

  @override
  List<Object?> get props => <Object?>[token, platform, deviceName];
}

class UpdateDeviceTokenBody extends Equatable {
  const UpdateDeviceTokenBody({
    this.token,
    this.platform,
    this.deviceName,
  });

  final String? token;
  final DeviceTokenPlatform? platform;
  final String? deviceName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (token != null && token!.trim().isNotEmpty) 'token': token!.trim(),
      if (platform != null) 'platform': platform!.apiValue,
      if (deviceName != null) 'device_name': deviceName!.trim(),
    };
  }

  @override
  List<Object?> get props => <Object?>[token, platform, deviceName];
}

String _readString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? _readOptionalString(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic> _readMetadata(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

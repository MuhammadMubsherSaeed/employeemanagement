import 'package:equatable/equatable.dart';

class AuditLogPage<T> {
  const AuditLogPage({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.isNotEmpty;
}

class AuditLogActor extends Equatable {
  const AuditLogActor({required this.id, required this.name});

  final int id;
  final String name;

  factory AuditLogActor.fromJson(Map<String, dynamic> json) {
    return AuditLogActor(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name];
}

class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.user,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final AuditLogActor? user;
  final Object? oldValue;
  final Object? newValue;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final Object? userRaw = json['user'];
    return AuditLogEntry(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString(),
      user: userRaw is Map
          ? AuditLogActor.fromJson(Map<String, dynamic>.from(userRaw))
          : null,
      oldValue: json['old_value'],
      newValue: json['new_value'],
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        action,
        entityType,
        entityId,
        user,
        oldValue,
        newValue,
        ipAddress,
        userAgent,
        createdAt,
      ];
}

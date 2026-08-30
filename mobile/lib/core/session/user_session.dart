import 'package:flutter/foundation.dart';

/// Backend-owned tenant context for a signed-in user.
///
/// Flutter must not invent or switch [companyId]. Auth will populate this
/// from the API; until then there is no session.
@immutable
class UserSession {
  const UserSession({
    required this.userId,
    required this.companyId,
    required this.role,
    this.permissions = const <String>[],
  });

  final String userId;
  final String companyId;
  final String role;
  final List<String> permissions;

  bool get hasTenantContext => userId.isNotEmpty && companyId.isNotEmpty;

  bool hasPermission(String permission) => permissions.contains(permission);

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: _string(json['userId'] ?? json['user_id'] ?? json['id']),
      companyId: _string(json['companyId'] ?? json['company_id']),
      role: _string(json['role']),
      permissions: _stringList(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'companyId': companyId,
      'role': role,
      'permissions': permissions,
    };
  }

  static String _string(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

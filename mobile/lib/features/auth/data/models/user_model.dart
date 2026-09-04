import 'package:flutter_base/features/auth/domain/entities/user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    this.isActive,
    this.companyId,
    this.permissions = const <String>[],
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role;
  final bool? isActive;
  final String? companyId;
  final List<String> permissions;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _readId(json['id']),
      email: _readString(json['email']),
      firstName: _readString(json['first_name']),
      lastName: _readString(json['last_name']),
      fullName: _readString(json['full_name']),
      role: _readString(json['role']),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : null,
      companyId: _readCompanyId(json['company']),
      permissions: _readPermissions(json['permissions']),
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      fullName: fullName.isNotEmpty
          ? fullName
          : '$firstName $lastName'.trim(),
      role: UserRole.fromApi(role),
      roleValue: role.isEmpty ? UserRole.unknown.apiValue : role,
      isActive: isActive,
      companyId: companyId,
      permissions: permissions,
    );
  }

  static int _readId(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static String? _readCompanyId(dynamic value) {
    if (value is Map) {
      final Object? id = value['id'];
      if (id == null) {
        return null;
      }
      final String parsed = id.toString().trim();
      return parsed.isEmpty ? null : parsed;
    }
    return null;
  }

  static List<String> _readPermissions(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

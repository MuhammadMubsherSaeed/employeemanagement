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
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role;
  final bool? isActive;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _readId(json['id']),
      email: _readString(json['email']),
      firstName: _readString(json['first_name']),
      lastName: _readString(json['last_name']),
      fullName: _readString(json['full_name']),
      role: _readString(json['role']),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : null,
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
}

import 'package:equatable/equatable.dart';

/// Backend `UserRole` values. Unknown future roles do not crash the app.
enum UserRole {
  superAdmin('SUPER_ADMIN'),
  companyAdmin('COMPANY_ADMIN'),
  manager('MANAGER'),
  employee('EMPLOYEE'),
  unknown('UNKNOWN');

  const UserRole(this.apiValue);

  final String apiValue;

  bool get isKnown => this != UserRole.unknown;

  static UserRole fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final UserRole role in UserRole.values) {
      if (role != UserRole.unknown && role.apiValue == value) {
        return role;
      }
    }
    return UserRole.unknown;
  }
}

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    required this.roleValue,
    this.isActive,
    this.companyId,
    this.permissions = const <String>[],
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final UserRole role;
  final String roleValue;
  final bool? isActive;
  final String? companyId;
  final List<String> permissions;

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    UserRole? role,
    String? roleValue,
    bool? isActive,
    String? companyId,
    List<String>? permissions,
    bool clearCompanyId = false,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      roleValue: roleValue ?? this.roleValue,
      isActive: isActive ?? this.isActive,
      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        email,
        firstName,
        lastName,
        fullName,
        role,
        roleValue,
        isActive,
        companyId,
        permissions,
      ];
}

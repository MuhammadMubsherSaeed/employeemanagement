import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates derived from [User.role] and the default RBAC seed.
/// The Django API remains the security boundary.
class EmployeeAccess {
  const EmployeeAccess(this.role);

  final UserRole role;

  bool get canViewDirectory =>
      role == UserRole.companyAdmin ||
      role == UserRole.manager ||
      role == UserRole.superAdmin;

  bool get isSelfService => role == UserRole.employee;

  bool get canCreate => role == UserRole.companyAdmin;

  bool get canUpdate =>
      role == UserRole.companyAdmin ||
      role == UserRole.manager ||
      role == UserRole.superAdmin;

  bool get canDelete =>
      role == UserRole.companyAdmin || role == UserRole.superAdmin;
}

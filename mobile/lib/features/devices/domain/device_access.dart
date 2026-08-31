import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from [User.role] and the default RBAC catalog.
/// Django remains the security boundary.
class DeviceAccess {
  const DeviceAccess(this.role);

  final UserRole role;

  bool get canView =>
      role == UserRole.employee ||
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canCreate =>
      role == UserRole.companyAdmin || role == UserRole.superAdmin;

  bool get canUpdate => canCreate;

  bool get canDelete => canCreate;

  bool get canAssign =>
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canReturn => canAssign;

  bool get canSeeSensitive =>
      role == UserRole.companyAdmin || role == UserRole.superAdmin;

  bool get canFilterByEmployee => canAssign;

  bool get isSelfService => role == UserRole.employee;

  bool get canManageInventory => canCreate;
}

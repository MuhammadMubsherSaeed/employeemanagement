import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from [User.role] and the default RBAC catalog.
/// Django remains the security boundary.
class LeaveAccess {
  const LeaveAccess(this.role);

  final UserRole role;

  bool get canView =>
      role == UserRole.employee ||
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canCreate =>
      role == UserRole.employee || role == UserRole.companyAdmin;

  bool get canApprove =>
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canReject => canApprove;

  bool get canManage =>
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canViewTeam =>
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canFilterByEmployee => canViewTeam;

  bool get isSelfService => role == UserRole.employee;
}

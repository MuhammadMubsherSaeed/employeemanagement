import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from [User.role] and the default RBAC catalog.
/// Django remains the security boundary.
class AttendanceAccess {
  const AttendanceAccess(this.role);

  final UserRole role;

  bool get canView =>
      role == UserRole.employee ||
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canCheckIn =>
      role == UserRole.employee || role == UserRole.companyAdmin;

  bool get canCheckOut => canCheckIn;

  bool get canViewTeam =>
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canFilterByEmployee => canViewTeam;

  bool get canManage =>
      role == UserRole.manager || role == UserRole.companyAdmin;

  bool get isSelfService => role == UserRole.employee;
}

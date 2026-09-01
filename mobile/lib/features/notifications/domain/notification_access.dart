import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from [User.role] and the default RBAC catalog.
/// Django remains the security boundary. Inbox is always recipient-specific.
class NotificationAccess {
  const NotificationAccess(this.role);

  final UserRole role;

  bool get canView =>
      role == UserRole.employee ||
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canMarkRead => canView;

  bool get canManage =>
      role == UserRole.companyAdmin || role == UserRole.superAdmin;

  bool get canOpenLeaveRequest => canView;

  bool get canOpenDevice => canView;

  bool get canOpenAttendance => canView;
}

import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from backend permission codes. Django remains the security boundary.
class LeaveAccess {
  const LeaveAccess(this.auth);

  factory LeaveAccess.of(User? user) =>
      LeaveAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView => auth.hasPermission(Permissions.leaveView);

  bool get canCreate =>
      auth.hasPermission(Permissions.leaveCreate) && auth.hasTenant;

  bool get canApprove =>
      auth.hasPermission(Permissions.leaveApprove) && auth.hasTenant;

  bool get canReject =>
      auth.hasPermission(Permissions.leaveReject) && auth.hasTenant;

  bool get canManage =>
      auth.hasPermission(Permissions.leaveManage) && auth.hasTenant;

  bool get canViewTeam => canApprove || canManage;

  bool get canFilterByEmployee => canViewTeam;

  bool get isSelfService => canView && !canApprove && !canManage;
}

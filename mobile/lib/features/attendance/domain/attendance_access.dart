import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from backend permission codes. Django remains the security boundary.
class AttendanceAccess {
  const AttendanceAccess(this.auth);

  factory AttendanceAccess.of(User? user) =>
      AttendanceAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView => auth.hasPermission(Permissions.attendanceView);

  bool get canCheckIn =>
      auth.hasPermission(Permissions.attendanceCheckIn) && auth.hasTenant;

  bool get canCheckOut =>
      auth.hasPermission(Permissions.attendanceCheckOut) && auth.hasTenant;

  bool get canManage =>
      auth.hasPermission(Permissions.attendanceManage) && auth.hasTenant;

  bool get canViewTeam => canManage;

  bool get canFilterByEmployee => canViewTeam;

  bool get isSelfService => canView && !canManage;
}

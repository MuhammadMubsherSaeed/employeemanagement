import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from notification codes. Inbox remains recipient-specific on the API.
class NotificationAccess {
  const NotificationAccess(this.auth);

  factory NotificationAccess.of(User? user) =>
      NotificationAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView => auth.hasPermission(Permissions.notificationsView);

  bool get canMarkRead =>
      auth.hasPermission(Permissions.notificationsMarkRead);

  bool get canManage => auth.hasPermission(Permissions.notificationsManage);

  bool get canOpenLeaveRequest => canView;

  bool get canOpenDevice =>
      canView && auth.hasPermission(Permissions.devicesView);

  bool get canOpenAttendance =>
      canView && auth.hasPermission(Permissions.attendanceView);
}

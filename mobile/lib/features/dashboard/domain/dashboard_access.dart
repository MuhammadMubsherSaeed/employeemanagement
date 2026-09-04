import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from `dashboard.*.view`. Django remains the security boundary.
class DashboardAccess {
  const DashboardAccess(this.auth);

  factory DashboardAccess.of(User? user) =>
      DashboardAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canViewAdmin =>
      auth.hasPermission(Permissions.dashboardAdminView) && auth.hasTenant;

  bool get canViewManager =>
      auth.hasPermission(Permissions.dashboardManagerView) && auth.hasTenant;

  bool get canViewEmployee =>
      auth.hasPermission(Permissions.dashboardEmployeeView) && auth.hasTenant;

  /// Prefer the most specific dashboard the session is allowed to open.
  DashboardKind? get primaryKind {
    if (!auth.hasTenant) {
      return null;
    }
    if (canViewAdmin) {
      return DashboardKind.admin;
    }
    if (canViewManager) {
      return DashboardKind.manager;
    }
    if (canViewEmployee) {
      return DashboardKind.employee;
    }
    return null;
  }
}

enum DashboardKind { admin, manager, employee }

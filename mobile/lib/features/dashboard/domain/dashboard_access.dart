import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from [User.role] and the default RBAC catalog.
/// Django remains the security boundary.
class DashboardAccess {
  const DashboardAccess(this.role);

  final UserRole role;

  bool get canViewAdmin =>
      role == UserRole.companyAdmin || role == UserRole.superAdmin;

  bool get canViewManager =>
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  bool get canViewEmployee =>
      role == UserRole.employee ||
      role == UserRole.manager ||
      role == UserRole.companyAdmin ||
      role == UserRole.superAdmin;

  /// Primary dashboard for this role. Super-admin and unknown roles
  /// have no company dashboard.
  DashboardKind? get primaryKind {
    switch (role) {
      case UserRole.companyAdmin:
        return DashboardKind.admin;
      case UserRole.manager:
        return DashboardKind.manager;
      case UserRole.employee:
        return DashboardKind.employee;
      case UserRole.superAdmin:
      case UserRole.unknown:
        return null;
    }
  }
}

enum DashboardKind { admin, manager, employee }

import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from backend permission codes. Django remains the security boundary.
class EmployeeAccess {
  const EmployeeAccess(this.auth);

  factory EmployeeAccess.of(User? user) =>
      EmployeeAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView => auth.hasPermission(Permissions.employeesView);

  bool get isSelfService =>
      canView &&
      !auth.hasPermission(Permissions.employeesCreate) &&
      !auth.hasPermission(Permissions.employeesUpdate) &&
      !auth.hasPermission(Permissions.employeesDelete);

  bool get canViewDirectory => canView && !isSelfService;

  bool get canCreate =>
      auth.hasPermission(Permissions.employeesCreate) && auth.hasTenant;

  bool get canUpdate => auth.hasPermission(Permissions.employeesUpdate);

  bool get canDelete => auth.hasPermission(Permissions.employeesDelete);
}

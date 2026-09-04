import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';

/// UI gates from `reports.view` / `reports.export`. Django remains authoritative.
class ReportAccess {
  const ReportAccess(this.auth);

  factory ReportAccess.of(User? user) =>
      ReportAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView =>
      auth.hasPermission(Permissions.reportsView) && auth.hasTenant;

  bool get canExport =>
      auth.hasPermission(Permissions.reportsExport) && auth.hasTenant;

  bool get canFilterByEmployee => canView;

  bool get canFilterByDepartment => canView;

  bool canOpen(ReportKind kind) {
    if (!canView) {
      return false;
    }
    switch (kind) {
      case ReportKind.attendance:
      case ReportKind.leaves:
      case ReportKind.employees:
      case ReportKind.devices:
        return true;
    }
  }
}

import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';

/// UI gates from [User.role] and the default RBAC catalog
/// (`reports.view`, `reports.export`). Django remains the security boundary.
class ReportAccess {
  const ReportAccess(this.role);

  final UserRole role;

  bool get canView =>
      role == UserRole.companyAdmin || role == UserRole.manager;

  bool get canExport => role == UserRole.companyAdmin;

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

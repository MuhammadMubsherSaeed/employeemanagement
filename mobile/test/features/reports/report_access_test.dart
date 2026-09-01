import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/report_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('company admin can view and export every report', () {
    const ReportAccess access = ReportAccess(UserRole.companyAdmin);
    expect(access.canView, isTrue);
    expect(access.canExport, isTrue);
    expect(access.canOpen(ReportKind.attendance), isTrue);
    expect(access.canOpen(ReportKind.employees), isTrue);
    expect(access.canOpen(ReportKind.devices), isTrue);
    expect(
      policy.canAccess(role: UserRole.companyAdmin, path: AppRoutes.reports),
      isTrue,
    );
    expect(
      policy.canAccess(
        role: UserRole.companyAdmin,
        path: AppRoutes.reportsDevices,
      ),
      isTrue,
    );
  });

  test('manager can view scoped reports but cannot export in the default catalog',
      () {
    const ReportAccess access = ReportAccess(UserRole.manager);
    expect(access.canView, isTrue);
    expect(access.canExport, isFalse);
    expect(access.canOpen(ReportKind.leaves), isTrue);
    expect(
      policy.canAccess(role: UserRole.manager, path: AppRoutes.reportsAttendance),
      isTrue,
    );
  });

  test('employee and super-admin cannot open administrative reports', () {
    const ReportAccess employee = ReportAccess(UserRole.employee);
    const ReportAccess superAdmin = ReportAccess(UserRole.superAdmin);
    expect(employee.canView, isFalse);
    expect(employee.canOpen(ReportKind.employees), isFalse);
    expect(superAdmin.canView, isFalse);
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.reports),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.reportsEmployees,
      ),
      isFalse,
    );
    expect(
      policy.canAccess(role: UserRole.unknown, path: AppRoutes.reports),
      isFalse,
    );
  });
}

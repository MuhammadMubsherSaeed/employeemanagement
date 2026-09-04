import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/report_access.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('company admin can view and export every report', () {
    final ReportAccess access = ReportAccess.of(companyAdminUser);
    expect(access.canView, isTrue);
    expect(access.canExport, isTrue);
    expect(access.canOpen(ReportKind.attendance), isTrue);
    expect(access.canOpen(ReportKind.employees), isTrue);
    expect(access.canOpen(ReportKind.devices), isTrue);
    expect(
      policy.canAccess(auth: authOf(companyAdminUser), path: AppRoutes.reports),
      isTrue,
    );
    expect(
      policy.canAccess(
        auth: authOf(companyAdminUser),
        path: AppRoutes.reportsDevices,
      ),
      isTrue,
    );
  });

  test('manager can view scoped reports but cannot export in the default catalog',
      () {
    final ReportAccess access = ReportAccess.of(managerUser);
    expect(access.canView, isTrue);
    expect(access.canExport, isFalse);
    expect(access.canOpen(ReportKind.leaves), isTrue);
    expect(
      policy.canAccess(
        auth: authOf(managerUser),
        path: AppRoutes.reportsAttendance,
      ),
      isTrue,
    );
  });

  test('employee and super-admin cannot open administrative reports', () {
    final ReportAccess employee = ReportAccess.of(sampleUser);
    final ReportAccess superAdmin = ReportAccess.of(superAdminUser);
    expect(employee.canView, isFalse);
    expect(employee.canOpen(ReportKind.employees), isFalse);
    expect(superAdmin.canView, isFalse);
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.reports),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.reportsEmployees,
      ),
      isFalse,
    );
    expect(
      policy.canAccess(auth: anonymousAuth(), path: AppRoutes.reports),
      isFalse,
    );
  });
}

import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view and punch, but cannot filter by employee', () {
    final AttendanceAccess access = AttendanceAccess.of(sampleUser);
    expect(access.canView, isTrue);
    expect(access.canCheckIn, isTrue);
    expect(access.canCheckOut, isTrue);
    expect(access.canFilterByEmployee, isFalse);
    expect(access.canViewTeam, isFalse);
    expect(access.isSelfService, isTrue);
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.attendance),
      isTrue,
    );
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.attendanceDetail('other-id'),
      ),
      isTrue,
    );
  });

  test('MANAGER can view team attendance but cannot punch', () {
    final AttendanceAccess access = AttendanceAccess.of(managerUser);
    expect(access.canView, isTrue);
    expect(access.canViewTeam, isTrue);
    expect(access.canManage, isTrue);
    expect(access.canCheckIn, isFalse);
    expect(access.canCheckOut, isFalse);
    expect(
      policy.canAccess(
        auth: authOf(managerUser),
        path: AppRoutes.attendanceHistory,
      ),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can view, manage, and punch', () {
    final AttendanceAccess access = AttendanceAccess.of(companyAdminUser);
    expect(access.canView, isTrue);
    expect(access.canManage, isTrue);
    expect(access.canCheckIn, isTrue);
    expect(access.canFilterByEmployee, isTrue);
  });

  test('SUPER_ADMIN can view but cannot punch without company context', () {
    final AttendanceAccess access = AttendanceAccess.of(superAdminUser);
    expect(access.canView, isTrue);
    expect(access.canCheckIn, isFalse);
    expect(access.canManage, isFalse);
  });

  test('unknown roles cannot open attendance routes', () {
    expect(
      policy.canAccess(auth: anonymousAuth(), path: AppRoutes.attendance),
      isFalse,
    );
  });
}

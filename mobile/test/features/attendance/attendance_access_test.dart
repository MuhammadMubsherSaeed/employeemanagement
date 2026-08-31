import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view and punch, but cannot filter by employee', () {
    const AttendanceAccess access = AttendanceAccess(UserRole.employee);
    expect(access.canView, isTrue);
    expect(access.canCheckIn, isTrue);
    expect(access.canCheckOut, isTrue);
    expect(access.canFilterByEmployee, isFalse);
    expect(access.canViewTeam, isFalse);
    expect(access.isSelfService, isTrue);
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.attendance),
      isTrue,
    );
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.attendanceDetail('other-id'),
      ),
      isTrue,
    );
  });

  test('MANAGER can view team attendance but cannot punch', () {
    const AttendanceAccess access = AttendanceAccess(UserRole.manager);
    expect(access.canView, isTrue);
    expect(access.canViewTeam, isTrue);
    expect(access.canManage, isTrue);
    expect(access.canCheckIn, isFalse);
    expect(access.canCheckOut, isFalse);
    expect(
      policy.canAccess(
        role: UserRole.manager,
        path: AppRoutes.attendanceHistory,
      ),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can view, manage, and punch', () {
    const AttendanceAccess access = AttendanceAccess(UserRole.companyAdmin);
    expect(access.canView, isTrue);
    expect(access.canManage, isTrue);
    expect(access.canCheckIn, isTrue);
    expect(access.canFilterByEmployee, isTrue);
  });

  test('SUPER_ADMIN can view but cannot punch without company context', () {
    const AttendanceAccess access = AttendanceAccess(UserRole.superAdmin);
    expect(access.canView, isTrue);
    expect(access.canCheckIn, isFalse);
    expect(access.canManage, isFalse);
  });

  test('unknown roles cannot open attendance routes', () {
    expect(
      policy.canAccess(role: UserRole.unknown, path: AppRoutes.attendance),
      isFalse,
    );
  });
}

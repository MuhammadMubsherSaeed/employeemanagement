import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view and create, but cannot approve or manage', () {
    const LeaveAccess access = LeaveAccess(UserRole.employee);
    expect(access.canView, isTrue);
    expect(access.canCreate, isTrue);
    expect(access.canApprove, isFalse);
    expect(access.canReject, isFalse);
    expect(access.canManage, isFalse);
    expect(access.canFilterByEmployee, isFalse);
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.leaves),
      isTrue,
    );
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.leavesApply),
      isTrue,
    );
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.leavesTypes),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.leaveApproval('req-1'),
      ),
      isFalse,
    );
  });

  test('MANAGER can approve but cannot apply', () {
    const LeaveAccess access = LeaveAccess(UserRole.manager);
    expect(access.canApprove, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canManage, isTrue);
    expect(
      policy.canAccess(role: UserRole.manager, path: AppRoutes.leavesApply),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.manager,
        path: AppRoutes.leaveApproval('req-1'),
      ),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can apply, approve, and manage types', () {
    const LeaveAccess access = LeaveAccess(UserRole.companyAdmin);
    expect(access.canCreate, isTrue);
    expect(access.canApprove, isTrue);
    expect(access.canManage, isTrue);
    expect(
      policy.canAccess(role: UserRole.companyAdmin, path: AppRoutes.leavesTypes),
      isTrue,
    );
  });

  test('unknown roles cannot open leave routes', () {
    expect(
      policy.canAccess(role: UserRole.unknown, path: AppRoutes.leaves),
      isFalse,
    );
  });
}

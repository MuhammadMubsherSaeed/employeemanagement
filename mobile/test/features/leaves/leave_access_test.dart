import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view and create, but cannot approve or manage', () {
    final LeaveAccess access = LeaveAccess.of(sampleUser);
    expect(access.canView, isTrue);
    expect(access.canCreate, isTrue);
    expect(access.canApprove, isFalse);
    expect(access.canReject, isFalse);
    expect(access.canManage, isFalse);
    expect(access.canFilterByEmployee, isFalse);
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.leaves),
      isTrue,
    );
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.leavesApply),
      isTrue,
    );
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.leavesTypes),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.leaveApproval('req-1'),
      ),
      isFalse,
    );
  });

  test('MANAGER can approve but cannot apply', () {
    final LeaveAccess access = LeaveAccess.of(managerUser);
    expect(access.canApprove, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canManage, isTrue);
    expect(
      policy.canAccess(auth: authOf(managerUser), path: AppRoutes.leavesApply),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(managerUser),
        path: AppRoutes.leaveApproval('req-1'),
      ),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can apply, approve, and manage types', () {
    final LeaveAccess access = LeaveAccess.of(companyAdminUser);
    expect(access.canCreate, isTrue);
    expect(access.canApprove, isTrue);
    expect(access.canManage, isTrue);
    expect(
      policy.canAccess(
        auth: authOf(companyAdminUser),
        path: AppRoutes.leavesTypes,
      ),
      isTrue,
    );
  });

  test('unknown roles cannot open leave routes', () {
    expect(
      policy.canAccess(auth: anonymousAuth(), path: AppRoutes.leaves),
      isFalse,
    );
  });
}

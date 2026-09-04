import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('COMPANY_ADMIN can view, create, update, and delete', () {
    final EmployeeAccess access = EmployeeAccess.of(companyAdminUser);
    expect(access.canViewDirectory, isTrue);
    expect(access.canCreate, isTrue);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isTrue);
    expect(
      policy.canAccess(
        auth: authOf(companyAdminUser),
        path: AppRoutes.employeesAdd,
      ),
      isTrue,
    );
  });

  test('MANAGER can view and update but cannot create or delete', () {
    final EmployeeAccess access = EmployeeAccess.of(managerUser);
    expect(access.canViewDirectory, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isFalse);
    expect(
      policy.canAccess(auth: authOf(managerUser), path: AppRoutes.employeesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(managerUser),
        path: AppRoutes.employeeEdit('id-1'),
      ),
      isTrue,
    );
  });

  test('EMPLOYEE is self-service only', () {
    final EmployeeAccess access = EmployeeAccess.of(sampleUser);
    expect(access.isSelfService, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isFalse);
    expect(access.canDelete, isFalse);
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.employeesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.employeeEdit('id-1'),
      ),
      isFalse,
    );
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.employeesMe),
      isTrue,
    );
  });

  test('SUPER_ADMIN cannot create without company context', () {
    final EmployeeAccess access = EmployeeAccess.of(superAdminUser);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isTrue);
  });
}

import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('COMPANY_ADMIN can view, create, update, and delete', () {
    const EmployeeAccess access = EmployeeAccess(UserRole.companyAdmin);
    expect(access.canViewDirectory, isTrue);
    expect(access.canCreate, isTrue);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isTrue);
    expect(
      policy.canAccess(role: UserRole.companyAdmin, path: AppRoutes.employeesAdd),
      isTrue,
    );
  });

  test('MANAGER can view and update but cannot create or delete', () {
    const EmployeeAccess access = EmployeeAccess(UserRole.manager);
    expect(access.canViewDirectory, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isFalse);
    expect(
      policy.canAccess(role: UserRole.manager, path: AppRoutes.employeesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.manager,
        path: AppRoutes.employeeEdit('id-1'),
      ),
      isTrue,
    );
  });

  test('EMPLOYEE is self-service only', () {
    const EmployeeAccess access = EmployeeAccess(UserRole.employee);
    expect(access.isSelfService, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isFalse);
    expect(access.canDelete, isFalse);
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.employeesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.employeeEdit('id-1'),
      ),
      isFalse,
    );
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.employeesMe),
      isTrue,
    );
  });

  test('SUPER_ADMIN cannot create without company context', () {
    const EmployeeAccess access = EmployeeAccess(UserRole.superAdmin);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isTrue);
  });
}

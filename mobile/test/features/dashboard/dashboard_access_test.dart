import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/dashboard/domain/dashboard_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary dashboard follows company role without a second RBAC system', () {
    expect(
      const DashboardAccess(UserRole.companyAdmin).primaryKind,
      DashboardKind.admin,
    );
    expect(
      const DashboardAccess(UserRole.manager).primaryKind,
      DashboardKind.manager,
    );
    expect(
      const DashboardAccess(UserRole.employee).primaryKind,
      DashboardKind.employee,
    );
    expect(const DashboardAccess(UserRole.superAdmin).primaryKind, isNull);
    expect(const DashboardAccess(UserRole.unknown).primaryKind, isNull);
  });

  test('UI capability flags stay aligned with default catalog roles', () {
    const DashboardAccess admin = DashboardAccess(UserRole.companyAdmin);
    expect(admin.canViewAdmin, isTrue);
    expect(admin.canViewManager, isTrue);
    expect(admin.canViewEmployee, isTrue);

    const DashboardAccess manager = DashboardAccess(UserRole.manager);
    expect(manager.canViewAdmin, isFalse);
    expect(manager.canViewManager, isTrue);
    expect(manager.canViewEmployee, isTrue);

    const DashboardAccess employee = DashboardAccess(UserRole.employee);
    expect(employee.canViewAdmin, isFalse);
    expect(employee.canViewManager, isFalse);
    expect(employee.canViewEmployee, isTrue);
  });
}

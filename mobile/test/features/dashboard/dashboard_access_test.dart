import 'package:flutter_base/features/dashboard/domain/dashboard_access.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';

void main() {
  test('primary dashboard follows permissions and tenant context', () {
    expect(
      DashboardAccess.of(companyAdminUser).primaryKind,
      DashboardKind.admin,
    );
    expect(
      DashboardAccess.of(managerUser).primaryKind,
      DashboardKind.manager,
    );
    expect(
      DashboardAccess.of(sampleUser).primaryKind,
      DashboardKind.employee,
    );
    expect(DashboardAccess.of(superAdminUser).primaryKind, isNull);
    expect(DashboardAccess.of(null).primaryKind, isNull);
  });

  test('UI capability flags stay aligned with default catalog roles', () {
    final DashboardAccess admin = DashboardAccess.of(companyAdminUser);
    expect(admin.canViewAdmin, isTrue);
    expect(admin.canViewManager, isTrue);
    expect(admin.canViewEmployee, isTrue);

    final DashboardAccess manager = DashboardAccess.of(managerUser);
    expect(manager.canViewAdmin, isFalse);
    expect(manager.canViewManager, isTrue);
    expect(manager.canViewEmployee, isTrue);

    final DashboardAccess employee = DashboardAccess.of(sampleUser);
    expect(employee.canViewAdmin, isFalse);
    expect(employee.canViewManager, isFalse);
    expect(employee.canViewEmployee, isTrue);
  });
}

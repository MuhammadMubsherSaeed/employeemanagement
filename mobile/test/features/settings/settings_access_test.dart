import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('company admin can view and edit settings', () {
    final SettingsAccess access = SettingsAccess.of(companyAdminUser);
    expect(access.canView, isTrue);
    expect(access.canEdit, isTrue);
    expect(
      policy.canAccess(auth: authOf(companyAdminUser), path: AppRoutes.settings),
      isTrue,
    );
    expect(
      policy.canAccess(
        auth: authOf(companyAdminUser),
        path: AppRoutes.settingsAttendance,
      ),
      isTrue,
    );
  });

  test('manager and employee can view but cannot edit', () {
    final SettingsAccess manager = SettingsAccess.of(managerUser);
    final SettingsAccess employee = SettingsAccess.of(sampleUser);
    expect(manager.canView, isTrue);
    expect(manager.canEdit, isFalse);
    expect(employee.canView, isTrue);
    expect(employee.canEdit, isFalse);
    expect(
      policy.canAccess(
        auth: authOf(managerUser),
        path: AppRoutes.settingsCompany,
      ),
      isTrue,
    );
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.settings),
      isTrue,
    );
  });

  test('unknown and super-admin cannot open company settings in the app', () {
    expect(SettingsAccess.of(superAdminUser).canView, isFalse);
    expect(SettingsAccess.of(null).canView, isFalse);
    expect(
      policy.canAccess(auth: authOf(superAdminUser), path: AppRoutes.settings),
      isFalse,
    );
    expect(
      policy.canAccess(auth: anonymousAuth(), path: AppRoutes.settings),
      isFalse,
    );
  });
}

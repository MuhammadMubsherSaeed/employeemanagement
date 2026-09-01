import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('company admin can view and edit settings', () {
    const SettingsAccess access = SettingsAccess(UserRole.companyAdmin);
    expect(access.canView, isTrue);
    expect(access.canEdit, isTrue);
    expect(
      policy.canAccess(role: UserRole.companyAdmin, path: AppRoutes.settings),
      isTrue,
    );
    expect(
      policy.canAccess(
        role: UserRole.companyAdmin,
        path: AppRoutes.settingsAttendance,
      ),
      isTrue,
    );
  });

  test('manager and employee can view but cannot edit', () {
    const SettingsAccess manager = SettingsAccess(UserRole.manager);
    const SettingsAccess employee = SettingsAccess(UserRole.employee);
    expect(manager.canView, isTrue);
    expect(manager.canEdit, isFalse);
    expect(employee.canView, isTrue);
    expect(employee.canEdit, isFalse);
    expect(
      policy.canAccess(role: UserRole.manager, path: AppRoutes.settingsCompany),
      isTrue,
    );
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.settings),
      isTrue,
    );
  });

  test('unknown and super-admin cannot open company settings in the app', () {
    expect(const SettingsAccess(UserRole.superAdmin).canView, isFalse);
    expect(const SettingsAccess(UserRole.unknown).canView, isFalse);
    expect(
      policy.canAccess(role: UserRole.superAdmin, path: AppRoutes.settings),
      isFalse,
    );
    expect(
      policy.canAccess(role: UserRole.unknown, path: AppRoutes.settings),
      isFalse,
    );
  });
}

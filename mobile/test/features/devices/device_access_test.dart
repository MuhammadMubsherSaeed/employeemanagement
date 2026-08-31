import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view assigned devices but cannot manage inventory', () {
    const DeviceAccess access = DeviceAccess(UserRole.employee);
    expect(access.canView, isTrue);
    expect(access.isSelfService, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isFalse);
    expect(access.canDelete, isFalse);
    expect(access.canAssign, isFalse);
    expect(access.canReturn, isFalse);
    expect(access.canSeeSensitive, isFalse);
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.myDevices),
      isTrue,
    );
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.devices),
      isTrue,
    );
    expect(
      policy.canAccess(role: UserRole.employee, path: AppRoutes.devicesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.deviceAssign('dev-1'),
      ),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.deviceEdit('dev-1'),
      ),
      isFalse,
    );
  });

  test('MANAGER can assign and return but cannot create devices', () {
    const DeviceAccess access = DeviceAccess(UserRole.manager);
    expect(access.canAssign, isTrue);
    expect(access.canReturn, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canDelete, isFalse);
    expect(access.canSeeSensitive, isFalse);
    expect(
      policy.canAccess(role: UserRole.manager, path: AppRoutes.devices),
      isTrue,
    );
    expect(
      policy.canAccess(role: UserRole.manager, path: AppRoutes.devicesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        role: UserRole.manager,
        path: AppRoutes.deviceAssign('dev-1'),
      ),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can manage inventory including create and delete', () {
    const DeviceAccess access = DeviceAccess(UserRole.companyAdmin);
    expect(access.canCreate, isTrue);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isTrue);
    expect(access.canAssign, isTrue);
    expect(access.canSeeSensitive, isTrue);
    expect(
      policy.canAccess(role: UserRole.companyAdmin, path: AppRoutes.devicesAdd),
      isTrue,
    );
    expect(
      policy.canAccess(
        role: UserRole.companyAdmin,
        path: AppRoutes.deviceEdit('dev-1'),
      ),
      isTrue,
    );
  });

  test('unknown roles cannot open device routes', () {
    expect(
      policy.canAccess(role: UserRole.unknown, path: AppRoutes.devices),
      isFalse,
    );
    expect(
      policy.canAccess(role: UserRole.unknown, path: AppRoutes.myDevices),
      isFalse,
    );
  });
}

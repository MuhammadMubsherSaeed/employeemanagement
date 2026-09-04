import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view assigned devices but cannot manage inventory', () {
    final DeviceAccess access = DeviceAccess.of(sampleUser);
    expect(access.canView, isTrue);
    expect(access.isSelfService, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canUpdate, isFalse);
    expect(access.canDelete, isFalse);
    expect(access.canAssign, isFalse);
    expect(access.canReturn, isFalse);
    expect(access.canSeeSensitive, isFalse);
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.myDevices),
      isTrue,
    );
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.devices),
      isTrue,
    );
    expect(
      policy.canAccess(auth: authOf(sampleUser), path: AppRoutes.devicesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.deviceAssign('dev-1'),
      ),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.deviceEdit('dev-1'),
      ),
      isFalse,
    );
  });

  test('MANAGER can assign and return but cannot create devices', () {
    final DeviceAccess access = DeviceAccess.of(managerUser);
    expect(access.canAssign, isTrue);
    expect(access.canReturn, isTrue);
    expect(access.canCreate, isFalse);
    expect(access.canDelete, isFalse);
    expect(access.canSeeSensitive, isFalse);
    expect(
      policy.canAccess(auth: authOf(managerUser), path: AppRoutes.devices),
      isTrue,
    );
    expect(
      policy.canAccess(auth: authOf(managerUser), path: AppRoutes.devicesAdd),
      isFalse,
    );
    expect(
      policy.canAccess(
        auth: authOf(managerUser),
        path: AppRoutes.deviceAssign('dev-1'),
      ),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can manage inventory including create and delete', () {
    final DeviceAccess access = DeviceAccess.of(companyAdminUser);
    expect(access.canCreate, isTrue);
    expect(access.canUpdate, isTrue);
    expect(access.canDelete, isTrue);
    expect(access.canAssign, isTrue);
    expect(access.canSeeSensitive, isTrue);
    expect(
      policy.canAccess(
        auth: authOf(companyAdminUser),
        path: AppRoutes.devicesAdd,
      ),
      isTrue,
    );
    expect(
      policy.canAccess(
        auth: authOf(companyAdminUser),
        path: AppRoutes.deviceEdit('dev-1'),
      ),
      isTrue,
    );
  });

  test('unknown roles cannot open device routes', () {
    expect(
      policy.canAccess(auth: anonymousAuth(), path: AppRoutes.devices),
      isFalse,
    );
    expect(
      policy.canAccess(auth: anonymousAuth(), path: AppRoutes.myDevices),
      isFalse,
    );
  });
}

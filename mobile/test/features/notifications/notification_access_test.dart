import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view and mark own notifications', () {
    final NotificationAccess access = NotificationAccess.of(sampleUser);
    expect(access.canView, isTrue);
    expect(access.canMarkRead, isTrue);
    expect(access.canManage, isFalse);
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.notifications,
      ),
      isTrue,
    );
    expect(
      policy.canAccess(
        auth: authOf(sampleUser),
        path: AppRoutes.notification('n-1'),
      ),
      isTrue,
    );
  });

  test('MANAGER has inbox access without manage', () {
    final NotificationAccess access = NotificationAccess.of(managerUser);
    expect(access.canView, isTrue);
    expect(access.canManage, isFalse);
    expect(
      policy.canAccess(
        auth: authOf(managerUser),
        path: AppRoutes.notifications,
      ),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can manage', () {
    final NotificationAccess access = NotificationAccess.of(companyAdminUser);
    expect(access.canManage, isTrue);
    expect(
      policy.canAccess(
        auth: authOf(companyAdminUser),
        path: AppRoutes.notifications,
      ),
      isTrue,
    );
  });

  test('unknown roles cannot open notification routes', () {
    expect(
      policy.canAccess(auth: anonymousAuth(), path: AppRoutes.notifications),
      isFalse,
    );
  });
}

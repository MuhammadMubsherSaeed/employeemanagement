import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RoleRoutePolicy policy = RoleRoutePolicy();

  test('EMPLOYEE can view and mark own notifications', () {
    const NotificationAccess access = NotificationAccess(UserRole.employee);
    expect(access.canView, isTrue);
    expect(access.canMarkRead, isTrue);
    expect(access.canManage, isFalse);
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.notifications,
      ),
      isTrue,
    );
    expect(
      policy.canAccess(
        role: UserRole.employee,
        path: AppRoutes.notification('n-1'),
      ),
      isTrue,
    );
  });

  test('MANAGER has inbox access without manage', () {
    const NotificationAccess access = NotificationAccess(UserRole.manager);
    expect(access.canView, isTrue);
    expect(access.canManage, isFalse);
    expect(
      policy.canAccess(role: UserRole.manager, path: AppRoutes.notifications),
      isTrue,
    );
  });

  test('COMPANY_ADMIN can manage', () {
    const NotificationAccess access =
        NotificationAccess(UserRole.companyAdmin);
    expect(access.canManage, isTrue);
    expect(
      policy.canAccess(
        role: UserRole.companyAdmin,
        path: AppRoutes.notifications,
      ),
      isTrue,
    );
  });

  test('unknown roles cannot open notification routes', () {
    expect(
      policy.canAccess(role: UserRole.unknown, path: AppRoutes.notifications),
      isFalse,
    );
  });
}

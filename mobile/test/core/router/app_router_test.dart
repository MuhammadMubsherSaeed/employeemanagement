import 'package:flutter_base/core/router/app_router.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('createAppRouter starts at /home', () {
    final GoRouter router = createAppRouter();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    router.dispose();
  });

  test('future route names exist without screens', () {
    expect(AppRoutes.login, '/login');
    expect(AppRoutes.dashboard, '/dashboard');
    expect(AppRoutes.employees, '/employees');
    expect(AppRoutes.attendance, '/attendance');
    expect(AppRoutes.leaves, '/leaves');
    expect(AppRoutes.devices, '/devices');
    expect(AppRoutes.reports, '/reports');
    expect(AppRoutes.ai, '/ai');
    expect(AppRoutes.settings, '/settings');
  });
}

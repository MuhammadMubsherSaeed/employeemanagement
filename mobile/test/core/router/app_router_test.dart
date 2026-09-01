import 'package:flutter_base/core/router/app_router.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/auth_fakes.dart';

void main() {
  test('createAppRouter starts at splash', () {
    final GoRouter router = createAppRouter(
      readAuth: () => const AuthState.loading(),
    );
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.splash,
    );
    router.dispose();
  });

  test('future route names exist without screens', () {
    expect(AppRoutes.login, '/login');
    expect(AppRoutes.forgotPassword, '/forgot-password');
    expect(AppRoutes.resetPassword, '/reset-password');
    expect(AppRoutes.dashboard, '/dashboard');
    expect(AppRoutes.employees, '/employees');
    expect(AppRoutes.employeesAdd, '/employees/add');
    expect(AppRoutes.employeesMe, '/employees/me');
    expect(AppRoutes.attendance, '/attendance');
    expect(AppRoutes.attendanceHistory, '/attendance/history');
    expect(AppRoutes.attendanceCalendar, '/attendance/calendar');
    expect(AppRoutes.leaves, '/leaves');
    expect(AppRoutes.leavesBalances, '/leaves/balances');
    expect(AppRoutes.leavesApply, '/leaves/apply');
    expect(AppRoutes.leavesRequests, '/leaves/requests');
    expect(AppRoutes.leavesHistory, '/leaves/history');
    expect(AppRoutes.devices, '/devices');
    expect(AppRoutes.devicesAdd, '/devices/add');
    expect(AppRoutes.myDevices, '/my-devices');
    expect(AppRoutes.device('dev-1'), '/devices/dev-1');
    expect(AppRoutes.deviceEdit('dev-1'), '/devices/dev-1/edit');
    expect(AppRoutes.deviceAssign('dev-1'), '/devices/dev-1/assign');
    expect(AppRoutes.deviceHistory('dev-1'), '/devices/dev-1/history');
    expect(AppRoutes.notifications, '/notifications');
    expect(AppRoutes.notification('n-1'), '/notifications/n-1');
    expect(AppRoutes.reports, '/reports');
    expect(AppRoutes.ai, '/ai');
    expect(AppRoutes.settings, '/settings');
  });

  test('authenticated readAuth is accepted by the factory', () {
    final GoRouter router = createAppRouter(
      readAuth: () => const AuthState.authenticated(sampleUser),
      initialLocation: AppRoutes.home,
    );
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    router.dispose();
  });
}

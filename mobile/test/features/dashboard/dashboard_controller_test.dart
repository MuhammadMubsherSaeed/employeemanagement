import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/admin_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/employee_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/manager_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/dashboard_fakes.dart';
import '../../helpers/employee_fakes.dart';

ProviderContainer _container({
  required FakeDashboardRepository dashboard,
  SeededAuthController Function()? auth,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        auth ?? () => SeededAuthController(companyAdminUser),
      ),
      dashboardRepositoryProvider.overrideWithValue(dashboard),
    ],
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('admin dashboard loads, refreshes, and retries after an error', () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository()
      ..adminError = const NetworkException();
    final ProviderContainer container = _container(dashboard: dashboard);
    addTearDown(container.dispose);

    container.read(adminDashboardControllerProvider);
    await _flush();
    await _flush();

    DashboardViewState state = container.read(adminDashboardControllerProvider);
    expect(state.error, contains('internet'));
    expect(state.data, isNull);

    dashboard.adminError = null;
    dashboard.admin = sampleAdminDashboard(total: 21);
    await container.read(adminDashboardControllerProvider.notifier).load();
    state = container.read(adminDashboardControllerProvider);
    expect(state.error, isNull);
    expect(state.data?.totalEmployees, 21);

    dashboard.admin = sampleAdminDashboard(total: 30);
    await container.read(adminDashboardControllerProvider.notifier).refresh();
    expect(
      container.read(adminDashboardControllerProvider).data?.totalEmployees,
      30,
    );
    expect(dashboard.adminCalls, greaterThanOrEqualTo(3));
  });

  test('empty admin collections are success, not errors', () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository(
      admin: sampleAdminDashboard(empty: true),
    );
    final ProviderContainer container = _container(dashboard: dashboard);
    addTearDown(container.dispose);

    await container.read(adminDashboardControllerProvider.notifier).load();
    final DashboardViewState state =
        container.read(adminDashboardControllerProvider);
    expect(state.error, isNull);
    expect(state.data?.recentEmployees, isEmpty);
    expect(state.data?.recentActivity, isEmpty);
    expect(state.data?.pendingLeaveRequests, 0);
  });

  test('manager dashboard surfaces forbidden errors', () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository()
      ..managerError = const ForbiddenException();
    final ProviderContainer container = _container(
      dashboard: dashboard,
      auth: () => SeededAuthController(managerUser),
    );
    addTearDown(container.dispose);

    await container.read(managerDashboardControllerProvider.notifier).load();
    expect(
      container.read(managerDashboardControllerProvider).error,
      contains('do not have access'),
    );
  });

  test('employee dashboard loads and does not fetch other role APIs', () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository();
    final ProviderContainer container = _container(
      dashboard: dashboard,
      auth: () => SeededAuthController(sampleUser),
    );
    addTearDown(container.dispose);

    await container.read(employeeDashboardControllerProvider.notifier).load();
    expect(
      container.read(employeeDashboardControllerProvider).data?.workingMinutes,
      452,
    );
    expect(dashboard.employeeCalls, greaterThan(0));
    expect(dashboard.adminCalls, 0);
    expect(dashboard.managerCalls, 0);
  });

  test('unauthenticated users do not call dashboard APIs', () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authControllerProvider.overrideWith(LoggedOutAuthController.new),
        dashboardRepositoryProvider.overrideWithValue(dashboard),
      ],
    );
    addTearDown(container.dispose);

    await container.read(adminDashboardControllerProvider.notifier).load();
    await container.read(managerDashboardControllerProvider.notifier).load();
    await container.read(employeeDashboardControllerProvider.notifier).load();
    expect(dashboard.adminCalls, 0);
    expect(dashboard.managerCalls, 0);
    expect(dashboard.employeeCalls, 0);
  });
}

class LoggedOutAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

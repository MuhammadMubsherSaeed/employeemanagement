import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/providers/today_attendance_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/employee_dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';
import '../../helpers/auth_fakes.dart';
import '../../helpers/dashboard_fakes.dart';
import '../../helpers/employee_fakes.dart';

ProviderContainer _container({
  required FakeDashboardRepository dashboard,
  required FakeAttendanceRepository attendance,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        () => SeededAuthController(sampleUser),
      ),
      dashboardRepositoryProvider.overrideWithValue(dashboard),
      attendanceRepositoryProvider.overrideWithValue(attendance),
    ],
  );
}

void main() {
  test('check-in refreshes the employee dashboard after backend success',
      () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository(
      employee: sampleEmployeeDashboard(empty: true),
    );
    final FakeAttendanceRepository attendance = FakeAttendanceRepository(
      today: null,
    );
    final ProviderContainer container = _container(
      dashboard: dashboard,
      attendance: attendance,
    );
    addTearDown(container.dispose);

    await container.read(employeeDashboardControllerProvider.notifier).load();
    final int before = dashboard.employeeCalls;

    final bool ok =
        await container.read(employeeDashboardControllerProvider.notifier).checkIn();
    expect(ok, isTrue);
    expect(attendance.checkInCalls, 1);
    expect(dashboard.employeeCalls, greaterThan(before));
    expect(
      container.read(todayAttendanceProvider).punchState,
      PunchState.checkedIn,
    );
  });

  test('duplicate check-in while in flight is ignored', () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository(
      employee: sampleEmployeeDashboard(empty: true),
    );
    final FakeAttendanceRepository attendance = FakeAttendanceRepository(
      today: null,
    )..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(
      dashboard: dashboard,
      attendance: attendance,
    );
    addTearDown(container.dispose);

    await container.read(employeeDashboardControllerProvider.notifier).load();
    final EmployeeDashboardController controller =
        container.read(employeeDashboardControllerProvider.notifier);

    final Future<bool> first = controller.checkIn();
    final Future<bool> second = controller.checkIn();
    expect(await second, isFalse);
    expect(await first, isTrue);
    expect(attendance.checkInCalls, 1);
  });

  test('check-out refreshes the employee dashboard after backend success',
      () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository();
    final FakeAttendanceRepository attendance = FakeAttendanceRepository(
      today: sampleAttendance(checkOut: null, totalMinutes: null),
    );
    final ProviderContainer container = _container(
      dashboard: dashboard,
      attendance: attendance,
    );
    addTearDown(container.dispose);

    await container.read(todayAttendanceProvider.notifier).load();
    await container.read(employeeDashboardControllerProvider.notifier).load();
    final int before = dashboard.employeeCalls;

    final bool ok = await container
        .read(employeeDashboardControllerProvider.notifier)
        .checkOut();
    expect(ok, isTrue);
    expect(attendance.checkOutCalls, 1);
    expect(dashboard.employeeCalls, greaterThan(before));
    expect(
      container.read(todayAttendanceProvider).punchState,
      PunchState.checkedOut,
    );
  });

  test('duplicate check-out while in flight is ignored', () async {
    final FakeDashboardRepository dashboard = FakeDashboardRepository();
    final FakeAttendanceRepository attendance = FakeAttendanceRepository(
      today: sampleAttendance(checkOut: null, totalMinutes: null),
    )..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(
      dashboard: dashboard,
      attendance: attendance,
    );
    addTearDown(container.dispose);

    await container.read(todayAttendanceProvider.notifier).load();
    final EmployeeDashboardController controller =
        container.read(employeeDashboardControllerProvider.notifier);

    final Future<bool> first = controller.checkOut();
    final Future<bool> second = controller.checkOut();
    expect(await second, isFalse);
    expect(await first, isTrue);
    expect(attendance.checkOutCalls, 1);
  });
}

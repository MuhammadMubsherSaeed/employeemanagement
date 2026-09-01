import 'package:flutter_base/features/attendance/presentation/providers/today_attendance_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_error_mapper.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_base/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmployeeDashboardController
    extends Notifier<DashboardViewState<EmployeeDashboard>> {
  bool _inFlight = false;

  @override
  DashboardViewState<EmployeeDashboard> build() {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      if (next is AuthAuthenticated) {
        Future<void>.microtask(refresh);
      } else {
        state = const DashboardViewState<EmployeeDashboard>();
      }
    });
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      Future<void>.microtask(load);
    }
    return const DashboardViewState<EmployeeDashboard>(isLoading: true);
  }

  Future<void> load() => _load(refreshing: false);

  Future<void> refresh() => _load(refreshing: true);

  Future<bool> checkIn() async {
    final bool ok = await ref.read(todayAttendanceProvider.notifier).checkIn();
    if (ok) {
      await refresh();
    }
    return ok;
  }

  Future<bool> checkOut() async {
    final bool ok = await ref.read(todayAttendanceProvider.notifier).checkOut();
    if (ok) {
      await refresh();
    }
    return ok;
  }

  Future<void> _load({required bool refreshing}) async {
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      state = const DashboardViewState<EmployeeDashboard>();
      return;
    }
    if (_inFlight) {
      return;
    }
    _inFlight = true;
    state = state.copyWith(
      isLoading: !refreshing && state.data == null,
      isRefreshing: refreshing,
      clearError: true,
    );
    try {
      final EmployeeDashboard data =
          await ref.read(getEmployeeDashboardUseCaseProvider)();
      state = DashboardViewState<EmployeeDashboard>(data: data);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: DashboardErrorMapper.message(error),
      );
    } finally {
      _inFlight = false;
    }
  }
}

final employeeDashboardControllerProvider = NotifierProvider<
    EmployeeDashboardController, DashboardViewState<EmployeeDashboard>>(
  EmployeeDashboardController.new,
);

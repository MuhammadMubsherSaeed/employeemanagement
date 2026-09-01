import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_error_mapper.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_base/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardController
    extends Notifier<DashboardViewState<AdminDashboard>> {
  bool _inFlight = false;

  @override
  DashboardViewState<AdminDashboard> build() {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      if (next is AuthAuthenticated) {
        Future<void>.microtask(refresh);
      } else {
        state = const DashboardViewState<AdminDashboard>();
      }
    });
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      Future<void>.microtask(load);
    }
    return const DashboardViewState<AdminDashboard>(isLoading: true);
  }

  Future<void> load() => _load(refreshing: false);

  Future<void> refresh() => _load(refreshing: true);

  Future<void> _load({required bool refreshing}) async {
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      state = const DashboardViewState<AdminDashboard>();
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
      final AdminDashboard data =
          await ref.read(getAdminDashboardUseCaseProvider)();
      state = DashboardViewState<AdminDashboard>(data: data);
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

final adminDashboardControllerProvider = NotifierProvider<
    AdminDashboardController, DashboardViewState<AdminDashboard>>(
  AdminDashboardController.new,
);

import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/domain/dashboard_access.dart';
import 'package:flutter_base/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:flutter_base/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:flutter_base/features/dashboard/presentation/screens/manager_dashboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authControllerProvider);
    final UserRole role =
        auth is AuthAuthenticated ? auth.user.role : UserRole.unknown;
    switch (DashboardAccess(role).primaryKind) {
      case DashboardKind.admin:
        return const AdminDashboardScreen();
      case DashboardKind.manager:
        return const ManagerDashboardScreen();
      case DashboardKind.employee:
        return const EmployeeDashboardScreen();
      case null:
        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: const Padding(
            padding: AppSpacing.screen,
            child: AppEmptyState(
              title: 'Dashboard unavailable',
              subtitle:
                  'This account does not have a company dashboard. '
                  'Use Account to sign out or switch users.',
              icon: Icons.lock_outline,
            ),
          ),
        );
    }
  }
}

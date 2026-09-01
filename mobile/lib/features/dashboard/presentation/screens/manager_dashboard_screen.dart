import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/manager_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/attendance_summary_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/leave_summary_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/quick_action_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/recent_activity_list.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/unread_notification_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardViewState<ManagerDashboard> state =
        ref.watch(managerDashboardControllerProvider);
    final AuthState auth = ref.watch(authControllerProvider);
    final UserRole role =
        auth is AuthAuthenticated ? auth.user.role : UserRole.unknown;
    final LeaveAccess leave = LeaveAccess(role);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const UnreadNotificationBadge(
              child: Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Account',
            onPressed: () => context.push(AppRoutes.home),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(managerDashboardControllerProvider.notifier).refresh(),
        child: _body(context, ref, state, leave),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DashboardViewState<ManagerDashboard> state,
    LeaveAccess leave,
  ) {
    if (state.isLoading && state.data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120, child: AppLoader(message: 'Loading dashboard…')),
        ],
      );
    }
    if (state.error != null && state.data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          AppErrorWidget(
            message: state.error!,
            onRetry: () =>
                ref.read(managerDashboardControllerProvider.notifier).load(),
          ),
        ],
      );
    }
    final ManagerDashboard data = state.data!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screen,
      children: <Widget>[
        DashboardStatGrid(
          children: <DashboardStatCard>[
            DashboardStatCard(
              title: 'Team size',
              value: '${data.teamSize}',
              icon: Icons.groups_outlined,
            ),
            DashboardStatCard(
              title: 'Present',
              value: '${data.teamPresent}',
              icon: Icons.check_circle_outline,
            ),
            DashboardStatCard(
              title: 'Absent',
              value: '${data.teamAbsent}',
              icon: Icons.highlight_off_outlined,
            ),
            DashboardStatCard(
              title: 'Pending leave',
              value: '${data.pendingLeaveRequests}',
              icon: Icons.event_available_outlined,
              onTap: leave.canView
                  ? () => context.push(AppRoutes.leavesRequests)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Team attendance',
          child: AttendanceSummaryCard(
            present: data.teamPresent,
            absent: data.teamAbsent,
            late: data.teamLate,
            onLeave: data.teamOnLeave,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Leave',
          child: LeaveSummaryCard(
            pendingCount: data.pendingLeaveRequests,
            onTap: leave.canApprove
                ? () => context.push(AppRoutes.leavesRequests)
                : (leave.canView
                    ? () => context.push(AppRoutes.leavesRequests)
                    : null),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Recent activity',
          child: RecentActivityList(
            items: data.recentActivity,
            onSelect: (DashboardActivity activity) {
              final String? route = dashboardActivityRoute(activity);
              if (route != null) {
                context.push(route);
              }
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Quick actions',
          child: Column(
            children: <Widget>[
              QuickActionCard(
                icon: Icons.schedule_outlined,
                title: 'Team attendance',
                onTap: () => context.push(AppRoutes.attendance),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (leave.canView)
                QuickActionCard(
                  icon: Icons.event_available_outlined,
                  title: leave.canApprove ? 'Leave requests' : 'My leaves',
                  onTap: () => context.push(AppRoutes.leavesRequests),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

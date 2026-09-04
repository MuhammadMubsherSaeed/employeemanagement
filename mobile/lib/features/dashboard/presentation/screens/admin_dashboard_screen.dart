import 'package:flutter/material.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/admin_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/attendance_summary_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/leave_summary_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/recent_activity_list.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_card.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/unread_notification_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardViewState<AdminDashboard> state =
        ref.watch(adminDashboardControllerProvider);
    final notifications = NotificationAccess(ref.watch(authorizationProvider));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          if (notifications.canView)
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
            ref.read(adminDashboardControllerProvider.notifier).refresh(),
        child: _body(context, ref, state),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DashboardViewState<AdminDashboard> state,
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
                ref.read(adminDashboardControllerProvider.notifier).load(),
          ),
        ],
      );
    }
    final AdminDashboard data = state.data!;
    final employees = EmployeeAccess(ref.watch(authorizationProvider));
    final attendance = AttendanceAccess(employees.auth);
    final leave = LeaveAccess(employees.auth);
    final bool canViewAudit =
        employees.auth.hasPermission(Permissions.auditLogsView);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screen,
      children: <Widget>[
        if (employees.canView || leave.canView)
          DashboardStatGrid(
            children: <DashboardStatCard>[
              if (employees.canView) ...<DashboardStatCard>[
                DashboardStatCard(
                  title: 'Total employees',
                  value: '${data.totalEmployees}',
                  icon: Icons.groups_outlined,
                ),
                DashboardStatCard(
                  title: 'Active',
                  value: '${data.activeEmployees}',
                  icon: Icons.verified_outlined,
                ),
                DashboardStatCard(
                  title: 'Inactive',
                  value: '${data.inactiveEmployees}',
                  icon: Icons.person_off_outlined,
                ),
              ],
              if (leave.canView)
                DashboardStatCard(
                  title: 'Pending leave',
                  value: '${data.pendingLeaveRequests}',
                  icon: Icons.event_available_outlined,
                  onTap: () => context.push(AppRoutes.leavesRequests),
                ),
            ],
          ),
        if (attendance.canView) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          DashboardSection(
            title: 'Attendance overview',
            child: AttendanceSummaryCard(
              present: data.presentToday,
              absent: data.absentToday,
              late: data.lateToday,
              onLeave: data.onLeaveToday,
            ),
          ),
        ],
        if (leave.canView) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          DashboardSection(
            title: 'Leave',
            child: LeaveSummaryCard(
              pendingCount: data.pendingLeaveRequests,
              onTap: () => context.push(AppRoutes.leavesRequests),
            ),
          ),
        ],
        if (employees.canViewDirectory) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          DashboardSection(
            title: 'Recent employees',
            child: data.recentEmployees.isEmpty
                ? const AppEmptyState(
                    title: 'No recent employees',
                    icon: Icons.badge_outlined,
                  )
                : Column(
                    children: <Widget>[
                      for (final Employee employee in data.recentEmployees)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: EmployeeCard(
                            employee: employee,
                            onTap: () =>
                                context.push(AppRoutes.employee(employee.id)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
        if (canViewAudit) ...<Widget>[
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
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

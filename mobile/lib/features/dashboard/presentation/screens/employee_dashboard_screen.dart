import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_base/features/attendance/presentation/providers/today_attendance_controller.dart';
import 'package:flutter_base/features/attendance/presentation/states/today_attendance_state.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/today_attendance_card.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/employee_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/quick_action_card.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_card.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_balance_card.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_request_card.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/unread_notification_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState
    extends ConsumerState<EmployeeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(todayAttendanceProvider.notifier).load();
    });
  }

  Future<void> _refresh() async {
    await Future.wait(<Future<void>>[
      ref.read(employeeDashboardControllerProvider.notifier).refresh(),
      ref.read(todayAttendanceProvider.notifier).refresh(),
    ]);
  }

  Future<void> _checkIn() async {
    final bool ok =
        await ref.read(employeeDashboardControllerProvider.notifier).checkIn();
    if (!mounted) {
      return;
    }
    if (ok) {
      context.showSnack('Checked in.');
    } else {
      final String? error = ref.read(todayAttendanceProvider).actionError;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  Future<void> _checkOut() async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Check out',
      message: 'Are you sure you want to check out?',
      confirmLabel: 'Check Out',
      cancelLabel: 'Cancel',
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final bool ok =
        await ref.read(employeeDashboardControllerProvider.notifier).checkOut();
    if (!mounted) {
      return;
    }
    if (ok) {
      context.showSnack('Checked out.');
    } else {
      final String? error = ref.read(todayAttendanceProvider).actionError;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DashboardViewState<EmployeeDashboard> state =
        ref.watch(employeeDashboardControllerProvider);
    final TodayAttendanceState today = ref.watch(todayAttendanceProvider);
    final AuthState auth = ref.watch(authControllerProvider);
    final User? user = auth is AuthAuthenticated ? auth.user : null;
    final AttendanceAccess attendance = AttendanceAccess(
      ref.watch(authorizationProvider),
    );
    final LeaveAccess leave = LeaveAccess(attendance.auth);
    final DeviceAccess devices = DeviceAccess(attendance.auth);
    final NotificationAccess notifications = NotificationAccess(attendance.auth);
    final String name = (user?.firstName.isNotEmpty == true)
        ? user!.firstName
        : (user?.fullName.isNotEmpty == true ? user!.fullName : 'there');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My dashboard'),
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
        onRefresh: _refresh,
        child: _body(
          context,
          state,
          today,
          attendance,
          leave,
          devices,
          notifications,
          name,
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    DashboardViewState<EmployeeDashboard> state,
    TodayAttendanceState today,
    AttendanceAccess attendance,
    LeaveAccess leave,
    DeviceAccess devices,
    NotificationAccess notifications,
    String name,
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
                ref.read(employeeDashboardControllerProvider.notifier).load(),
          ),
        ],
      );
    }
    final EmployeeDashboard data = state.data!;
    final PunchState punch = today.record?.punchState ??
        data.todayAttendance?.punchState ??
        PunchState.none;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppBreakpoints.pagePadding(context),
      children: <Widget>[
        Text(
          '${dashboardGreeting(DateTime.now())}, $name',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        TodayAttendanceCard(record: today.record ?? data.todayAttendance),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Row(
            children: <Widget>[
              const Icon(Icons.timer_outlined),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Working hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                WorkingDuration.format(data.workingMinutes),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        if (attendance.canCheckIn) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          if (punch == PunchState.none)
            AppButton(
              label: today.isCheckingIn ? 'Checking in…' : 'Check In',
              isLoading: today.isCheckingIn,
              onPressed: today.isBusy ? null : _checkIn,
            ),
          if (punch == PunchState.checkedIn)
            AppButton(
              label: today.isCheckingOut ? 'Checking out…' : 'Check Out',
              variant: AppButtonVariant.outlined,
              isLoading: today.isCheckingOut,
              onPressed: today.isBusy ? null : _checkOut,
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Leave balances',
          child: data.leaveBalances.isEmpty
              ? const AppEmptyState(
                  title: 'No leave balances',
                  icon: Icons.event_busy_outlined,
                )
              : Column(
                  children: <Widget>[
                    for (final LeaveBalance balance in data.leaveBalances)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: LeaveBalanceCard(balance: balance),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Recent leaves',
          child: data.recentLeaveRequests.isEmpty
              ? const AppEmptyState(
                  title: 'No leave requests',
                  icon: Icons.event_note_outlined,
                )
              : Column(
                  children: <Widget>[
                    for (final LeaveRequest request in data.recentLeaveRequests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: LeaveRequestCard(
                          request: request,
                          onTap: () => context.push(
                            AppRoutes.leaveRequest(request.id),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Assigned devices',
          child: data.assignedDevices.isEmpty
              ? const AppEmptyState(
                  title: 'No assigned devices',
                  icon: Icons.devices_other_outlined,
                )
              : Column(
                  children: <Widget>[
                    for (final Device device in data.assignedDevices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: DeviceCard(
                          device: device,
                          onTap: () => context.push(AppRoutes.device(device.id)),
                        ),
                      ),
                  ],
                ),
        ),
        if (notifications.canView) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          QuickActionCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: data.notificationsCount == 0
                ? 'No unread notifications'
                : '${data.notificationsCount} unread',
            onTap: () => context.push(AppRoutes.notifications),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Quick actions',
          child: Column(
            children: <Widget>[
              if (attendance.canView)
                QuickActionCard(
                  icon: Icons.schedule_outlined,
                  title: 'My attendance',
                  onTap: () => context.push(AppRoutes.attendance),
                ),
              if (leave.canCreate) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                QuickActionCard(
                  icon: Icons.add_task_outlined,
                  title: 'Apply leave',
                  onTap: () => context.push(AppRoutes.leavesApply),
                ),
              ],
              if (leave.canView) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                QuickActionCard(
                  icon: Icons.event_available_outlined,
                  title: 'My leaves',
                  onTap: () => context.push(AppRoutes.leaves),
                ),
              ],
              if (devices.canView) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                QuickActionCard(
                  icon: Icons.phonelink_setup_outlined,
                  title: 'My devices',
                  onTap: () => context.push(
                    devices.isSelfService
                        ? AppRoutes.myDevices
                        : AppRoutes.devices,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/theme/theme_mode_controller.dart';
import 'package:flutter_base/core/widgets/app_avatar.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_module_tile.dart';
import 'package:flutter_base/core/widgets/app_section_header.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/unread_notification_badge.dart';
import 'package:flutter_base/features/reports/domain/report_access.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeModule {
  const _HomeModule({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Sign out',
      message: 'Sign out of this device?',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed != true || _loggingOut) {
      return;
    }
    setState(() => _loggingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authControllerProvider);
    final User? user = auth is AuthAuthenticated ? auth.user : null;
    final Authorization authorization = ref.watch(authorizationProvider);
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);
    final EmployeeAccess employees = EmployeeAccess(authorization);
    final AttendanceAccess attendance = AttendanceAccess(authorization);
    final LeaveAccess leave = LeaveAccess(authorization);
    final DeviceAccess devices = DeviceAccess(authorization);
    final NotificationAccess notifications = NotificationAccess(authorization);
    final ReportAccess reports = ReportAccess(authorization);
    final SettingsAccess settings = SettingsAccess(authorization);
    final bool canViewAuditLogs =
        authorization.hasPermission(Permissions.auditLogsView) &&
            authorization.hasTenant;
    final Brightness brightness = Theme.of(context).brightness;
    final String firstName = (user?.firstName.isNotEmpty == true)
        ? user!.firstName
        : (user?.fullName.isNotEmpty == true ? user!.fullName : 'there');

    final List<_HomeModule> modules = <_HomeModule>[
      _HomeModule(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        color: AppColors.infoOf(brightness),
        onTap: () => context.push(AppRoutes.dashboard),
      ),
      if (employees.canView)
        _HomeModule(
          title: employees.isSelfService ? 'My employee profile' : 'Employees',
          icon: Icons.groups_outlined,
          color: AppColors.successOf(brightness),
          onTap: () {
            context.push(
              employees.isSelfService
                  ? AppRoutes.employeesMe
                  : AppRoutes.employees,
            );
          },
        ),
      if (attendance.canView)
        _HomeModule(
          title: 'Attendance',
          icon: Icons.schedule_outlined,
          color: AppColors.warningOf(brightness),
          onTap: () => context.push(AppRoutes.attendance),
        ),
      if (leave.canView)
        _HomeModule(
          title: 'Leave',
          icon: Icons.event_available_outlined,
          color: AppColors.infoOf(brightness),
          onTap: () => context.push(AppRoutes.leaves),
        ),
      if (devices.isSelfService)
        _HomeModule(
          title: 'My devices',
          icon: Icons.phonelink_setup_outlined,
          color: Theme.of(context).colorScheme.secondary,
          onTap: () => context.push(AppRoutes.myDevices),
        ),
      if (devices.canView && !devices.isSelfService)
        _HomeModule(
          title: 'Devices',
          icon: Icons.devices_other_outlined,
          color: Theme.of(context).colorScheme.secondary,
          onTap: () => context.push(AppRoutes.devices),
        ),
      if (notifications.canView)
        _HomeModule(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          color: AppColors.warningOf(brightness),
          onTap: () => context.push(AppRoutes.notifications),
        ),
      if (reports.canView)
        _HomeModule(
          title: 'Reports',
          icon: Icons.assessment_outlined,
          color: AppColors.infoOf(brightness),
          onTap: () => context.push(AppRoutes.reports),
        ),
      if (canViewAuditLogs)
        _HomeModule(
          title: 'Audit logs',
          icon: Icons.policy_outlined,
          color: AppColors.mutedOf(brightness),
          onTap: () => context.push(AppRoutes.auditLogs),
        ),
      if (settings.canView)
        _HomeModule(
          title: 'Settings',
          icon: Icons.settings_outlined,
          color: AppColors.mutedOf(brightness),
          onTap: () => context.push(AppRoutes.settings),
        ),
    ];

    final List<NavigationDestination> destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      if (attendance.canView)
        const NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: 'Attendance',
        ),
      if (leave.canView)
        const NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available),
          label: 'Leave',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
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
            tooltip: 'Toggle theme',
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).cycle(),
            icon: Icon(switch (themeMode) {
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppBreakpoints.pagePadding(context),
          children: <Widget>[
            AppCard(
              variant: AppCardVariant.elevated,
              child: Row(
                children: <Widget>[
                  AppAvatar(
                    name: user?.fullName ?? 'User',
                    size: AppDimensions.avatarLg,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${dashboardGreeting(DateTime.now())}, $firstName',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(user?.email ?? ''),
                        const SizedBox(height: AppSpacing.xs),
                        AppStatusBadge(
                          label: user?.roleValue ?? 'UNKNOWN',
                          tone: AppBadgeTone.info,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Modules'),
            AppModuleGrid(
              children: modules
                  .map(
                    (_HomeModule module) => AppModuleTile(
                      title: module.title,
                      icon: module.icon,
                      color: module.color,
                      onTap: module.onTap,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Sign out',
              variant: AppButtonVariant.outlined,
              isLoading: _loggingOut,
              onPressed: _loggingOut ? null : _logout,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      bottomNavigationBar: destinations.length < 2 ||
              AppBreakpoints.isTablet(context)
          ? null
          : NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (int index) {
                if (index == 0) {
                  return;
                }
                if (index == 1) {
                  context.push(AppRoutes.dashboard);
                  return;
                }
                final String label = destinations[index].label;
                if (label == 'Attendance') {
                  context.push(AppRoutes.attendance);
                } else if (label == 'Leave') {
                  context.push(AppRoutes.leaves);
                }
              },
              destinations: destinations,
            ),
    );
  }
}

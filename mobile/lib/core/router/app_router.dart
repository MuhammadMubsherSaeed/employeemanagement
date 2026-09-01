import 'package:flutter/material.dart';
import 'package:flutter_base/core/presentation/app_error_screen.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/router/auth_redirect.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_calendar_screen.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_dashboard_screen.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_details_screen.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/home_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter_base/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_base/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter_base/features/devices/presentation/screens/assign_device_screen.dart';
import 'package:flutter_base/features/devices/presentation/screens/device_details_screen.dart';
import 'package:flutter_base/features/devices/presentation/screens/device_form_screen.dart';
import 'package:flutter_base/features/devices/presentation/screens/device_history_screen.dart';
import 'package:flutter_base/features/devices/presentation/screens/devices_screen.dart';
import 'package:flutter_base/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:flutter_base/features/employees/presentation/screens/employee_form_screens.dart';
import 'package:flutter_base/features/employees/presentation/screens/employees_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/apply_leave_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_balance_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_dashboard_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_request_details_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_requests_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_type_form_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_types_screen.dart';
import 'package:flutter_base/features/notifications/presentation/screens/notification_details_screen.dart';
import 'package:flutter_base/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter_base/features/reports/presentation/screens/attendance_report_screen.dart';
import 'package:flutter_base/features/reports/presentation/screens/device_report_screen.dart';
import 'package:flutter_base/features/reports/presentation/screens/employee_report_screen.dart';
import 'package:flutter_base/features/reports/presentation/screens/leave_report_screen.dart';
import 'package:flutter_base/features/reports/presentation/screens/reports_screen.dart';
import 'package:flutter_base/features/settings/presentation/screens/attendance_settings_screen.dart';
import 'package:flutter_base/features/settings/presentation/screens/company_settings_screen.dart';
import 'package:flutter_base/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createAppRouter({
  required AuthState Function() readAuth,
  Listenable? refreshListenable,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      return AuthRedirect.resolve(
        auth: readAuth(),
        location: state.matchedLocation,
      );
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return const AppErrorScreen(
        message: 'This page could not be found.',
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (BuildContext context, GoRouterState state) {
          return ResetPasswordScreen(
            uid: state.uri.queryParameters['uid'],
            token: state.uri.queryParameters['token'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (BuildContext context, GoRouterState state) {
          return const DashboardScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.employees,
        name: 'employees',
        builder: (BuildContext context, GoRouterState state) {
          return const EmployeesScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.employeesAdd,
        name: 'employees-add',
        builder: (BuildContext context, GoRouterState state) {
          return const AddEmployeeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.employeesMe,
        name: 'employees-me',
        builder: (BuildContext context, GoRouterState state) {
          return const EmployeeDetailsScreen(
            employeeId: 'me',
            isSelf: true,
          );
        },
      ),
      GoRoute(
        path: '/employees/:id/edit',
        name: 'employee-edit',
        builder: (BuildContext context, GoRouterState state) {
          return EditEmployeeScreen(
            employeeId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/employees/:id',
        name: 'employee-detail',
        builder: (BuildContext context, GoRouterState state) {
          return EmployeeDetailsScreen(
            employeeId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.attendance,
        name: 'attendance',
        builder: (BuildContext context, GoRouterState state) {
          return const AttendanceDashboardScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.attendanceHistory,
        name: 'attendance-history',
        builder: (BuildContext context, GoRouterState state) {
          return const AttendanceHistoryScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.attendanceCalendar,
        name: 'attendance-calendar',
        builder: (BuildContext context, GoRouterState state) {
          return const AttendanceCalendarScreen();
        },
      ),
      GoRoute(
        path: '/attendance/:id',
        name: 'attendance-detail',
        builder: (BuildContext context, GoRouterState state) {
          return AttendanceDetailsScreen(
            attendanceId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.leaves,
        name: 'leaves',
        builder: (BuildContext context, GoRouterState state) {
          return const LeaveDashboardScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.leavesBalances,
        name: 'leave-balances',
        builder: (BuildContext context, GoRouterState state) {
          return const LeaveBalanceScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.leavesApply,
        name: 'leave-apply',
        builder: (BuildContext context, GoRouterState state) {
          return const ApplyLeaveScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.leavesRequests,
        name: 'leave-requests',
        builder: (BuildContext context, GoRouterState state) {
          return const LeaveRequestsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.leavesHistory,
        name: 'leave-history',
        builder: (BuildContext context, GoRouterState state) {
          return const LeaveHistoryScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.leavesTypesAdd,
        name: 'leave-types-add',
        builder: (BuildContext context, GoRouterState state) {
          return const LeaveTypeFormScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.leavesTypes,
        name: 'leave-types',
        builder: (BuildContext context, GoRouterState state) {
          return const LeaveTypesScreen();
        },
      ),
      GoRoute(
        path: '/leaves/types/:id/edit',
        name: 'leave-type-edit',
        builder: (BuildContext context, GoRouterState state) {
          return LeaveTypeFormScreen(
            leaveTypeId: state.pathParameters['id'],
          );
        },
      ),
      GoRoute(
        path: '/leaves/approval/:id',
        name: 'leave-approval',
        builder: (BuildContext context, GoRouterState state) {
          return LeaveApprovalScreen(
            requestId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/leaves/requests/:id',
        name: 'leave-request-detail',
        builder: (BuildContext context, GoRouterState state) {
          return LeaveRequestDetailsScreen(
            requestId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myDevices,
        name: 'my-devices',
        builder: (BuildContext context, GoRouterState state) {
          return const MyDeviceScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.devicesAdd,
        name: 'devices-add',
        builder: (BuildContext context, GoRouterState state) {
          return const AddDeviceScreen();
        },
      ),
      GoRoute(
        path: '/devices/:id/edit',
        name: 'device-edit',
        builder: (BuildContext context, GoRouterState state) {
          return EditDeviceScreen(
            deviceId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/devices/:id/assign',
        name: 'device-assign',
        builder: (BuildContext context, GoRouterState state) {
          return AssignDeviceScreen(
            deviceId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/devices/:id/history',
        name: 'device-history',
        builder: (BuildContext context, GoRouterState state) {
          return DeviceHistoryScreen(
            deviceId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/devices/:id',
        name: 'device-detail',
        builder: (BuildContext context, GoRouterState state) {
          return DeviceDetailsScreen(
            deviceId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.devices,
        name: 'devices',
        builder: (BuildContext context, GoRouterState state) {
          return const DevicesScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (BuildContext context, GoRouterState state) {
          return const NotificationsScreen();
        },
      ),
      GoRoute(
        path: '/notifications/:id',
        name: 'notification-detail',
        builder: (BuildContext context, GoRouterState state) {
          return NotificationDetailsScreen(
            notificationId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (BuildContext context, GoRouterState state) {
          return const ReportsScreen();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'attendance',
            name: 'reports-attendance',
            builder: (BuildContext context, GoRouterState state) {
              return const AttendanceReportScreen();
            },
          ),
          GoRoute(
            path: 'leaves',
            name: 'reports-leaves',
            builder: (BuildContext context, GoRouterState state) {
              return const LeaveReportScreen();
            },
          ),
          GoRoute(
            path: 'employees',
            name: 'reports-employees',
            builder: (BuildContext context, GoRouterState state) {
              return const EmployeeReportScreen();
            },
          ),
          GoRoute(
            path: 'devices',
            name: 'reports-devices',
            builder: (BuildContext context, GoRouterState state) {
              return const DeviceReportScreen();
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'company',
            name: 'settings-company',
            builder: (BuildContext context, GoRouterState state) {
              return const CompanySettingsScreen();
            },
          ),
          GoRoute(
            path: 'attendance',
            name: 'settings-attendance',
            builder: (BuildContext context, GoRouterState state) {
              return const AttendanceSettingsScreen();
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.error,
        name: 'error',
        builder: (BuildContext context, GoRouterState state) {
          return const AppErrorScreen(
            message: 'Something went wrong.',
          );
        },
      ),
    ],
  );
}

final goRouterProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (
    AuthState? previous,
    AuthState next,
  ) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);
  return createAppRouter(
    readAuth: () => ref.read(authControllerProvider),
    refreshListenable: refresh,
  );
});

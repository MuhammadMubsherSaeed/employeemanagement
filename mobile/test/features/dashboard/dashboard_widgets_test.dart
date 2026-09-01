import 'package:flutter/material.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_base/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/attendance_summary_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/leave_summary_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/quick_action_card.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/recent_activity_list.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';
import '../../helpers/auth_fakes.dart';
import '../../helpers/dashboard_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/notification_fakes.dart';

Widget _app({
  required User user,
  required FakeDashboardRepository dashboard,
  FakeAttendanceRepository? attendance,
  FakeNotificationRepository? notifications,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      dashboardRepositoryProvider.overrideWithValue(dashboard),
      attendanceRepositoryProvider.overrideWithValue(
        attendance ?? FakeAttendanceRepository(today: null),
      ),
      notificationRepositoryProvider.overrideWithValue(
        notifications ?? FakeNotificationRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const DashboardScreen(),
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('role gate selects admin, manager, employee, or unauthorized',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(user: companyAdminUser, dashboard: FakeDashboardRepository()),
    );
    await _pumpReady(tester);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total employees'), findsOneWidget);

    await tester.pumpWidget(
      _app(user: managerUser, dashboard: FakeDashboardRepository()),
    );
    await _pumpReady(tester);
    expect(find.text('Team dashboard'), findsOneWidget);
    expect(find.text('Team size'), findsOneWidget);

    await tester.pumpWidget(
      _app(user: sampleUser, dashboard: FakeDashboardRepository()),
    );
    await _pumpReady(tester);
    expect(find.text('My dashboard'), findsOneWidget);
    expect(
      find.text('${dashboardGreeting(DateTime.now())}, User'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _app(user: superAdminUser, dashboard: FakeDashboardRepository()),
    );
    await _pumpReady(tester);
    expect(find.text('Dashboard unavailable'), findsOneWidget);
  });

  testWidgets('admin dashboard shows stats, empty sections, and retry',
      (WidgetTester tester) async {
    _setSize(tester, const Size(390, 2000));
    final FakeDashboardRepository dashboard = FakeDashboardRepository(
      admin: sampleAdminDashboard(empty: true),
    );
    await tester.pumpWidget(_app(user: companyAdminUser, dashboard: dashboard));
    await _pumpReady(tester);
    expect(find.text('No recent employees'), findsOneWidget);
    expect(find.text('No recent activity'), findsOneWidget);
    expect(find.text('No pending requests'), findsOneWidget);

    dashboard.adminError = const NetworkException();
    dashboard.admin = sampleAdminDashboard();
    await tester.pumpWidget(
      _app(user: companyAdminUser, dashboard: dashboard),
    );
    await _pumpReady(tester);
    expect(find.byType(AppErrorWidget), findsOneWidget);

    dashboard.adminError = null;
    await tester.tap(find.text('Retry'));
    await _pumpReady(tester);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('employee dashboard shows hours, empty sections, and check-in',
      (WidgetTester tester) async {
    _setSize(tester, const Size(390, 2400));
    await tester.pumpWidget(
      _app(
        user: sampleUser,
        dashboard: FakeDashboardRepository(),
      ),
    );
    await _pumpReady(tester);
    expect(find.text(WorkingDuration.format(452)), findsWidgets);
    expect(find.text('Annual Leave'), findsWidgets);
    expect(find.text('LAP-001'), findsOneWidget);
    expect(find.textContaining('unread'), findsOneWidget);
    expect(find.text('My attendance'), findsOneWidget);
    expect(find.text('Apply leave'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        user: sampleUser,
        dashboard: FakeDashboardRepository(
          employee: sampleEmployeeDashboard(empty: true),
        ),
      ),
    );
    await _pumpReady(tester);
    expect(find.text('No leave balances'), findsOneWidget);
    expect(find.text('No leave requests'), findsOneWidget);
    expect(find.text('No assigned devices'), findsOneWidget);
    expect(find.text('No unread notifications'), findsOneWidget);
    expect(find.text('Check In'), findsOneWidget);
  });

  testWidgets('phone and tablet layouts do not overflow',
      (WidgetTester tester) async {
    final AdminDashboard crowded = AdminDashboard.fromJson(
      sampleAdminDashboardJson()
        ..['recent_employees'] = <Map<String, dynamic>>[
          sampleDashboardRecentEmployeeJson(
            firstName: 'Bartholomew Maximilian',
            lastName: 'von Extremelylongsurname',
          ),
        ]
        ..['total_employees'] = 999999,
    );

    _setSize(tester, const Size(360, 1800));
    await tester.pumpWidget(
      _app(
        user: companyAdminUser,
        dashboard: FakeDashboardRepository(admin: crowded),
      ),
    );
    await _pumpReady(tester);
    expect(tester.takeException(), isNull);

    _setSize(tester, const Size(1024, 768));
    await tester.pumpWidget(
      _app(
        user: companyAdminUser,
        dashboard: FakeDashboardRepository(admin: crowded),
      ),
    );
    await _pumpReady(tester);
    expect(tester.takeException(), isNull);

    _setSize(tester, const Size(800, 400));
    await tester.pumpWidget(
      _app(
        user: managerUser,
        dashboard: FakeDashboardRepository(
          manager: ManagerDashboard.fromJson(
            sampleManagerDashboardJson()
              ..['recent_activity'] = <Map<String, dynamic>>[
                for (int i = 0; i < 12; i++)
                  sampleDashboardActivityJson(
                    id: 'act-$i',
                    action: 'Long activity description number $i',
                  ),
              ],
          ),
        ),
      ),
    );
    await _pumpReady(tester);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reusable dashboard widgets render loading empty and disabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            children: const <Widget>[
              DashboardStatCard(
                title: 'Headcount',
                value: '42',
                subtitle: 'Active company',
                icon: Icons.groups_outlined,
              ),
              AttendanceSummaryCard(
                present: 8,
                absent: 1,
                late: 1,
                onLeave: 2,
              ),
              LeaveSummaryCard(pendingCount: 0),
              RecentActivityList(items: <DashboardActivity>[]),
              QuickActionCard(
                icon: Icons.block,
                title: 'Disabled action',
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Headcount'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('No pending requests'), findsOneWidget);
    expect(find.text('No recent activity'), findsOneWidget);
    expect(find.text('Disabled action'), findsOneWidget);
  });
}

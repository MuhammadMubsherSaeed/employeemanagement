import 'package:flutter/material.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_calendar_screen.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_dashboard_screen.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_details_screen.dart';
import 'package:flutter_base/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_filter_sheet.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/today_attendance_card.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';
import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';

Widget _app({
  required Widget child,
  required User user,
  required FakeAttendanceRepository attendance,
}) {
  return ProviderScope(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      getTodayAttendanceProvider.overrideWithValue(
        GetTodayAttendance(attendance),
      ),
      checkInUseCaseProvider.overrideWithValue(CheckIn(attendance)),
      checkOutUseCaseProvider.overrideWithValue(CheckOut(attendance)),
      getAttendanceHistoryUseCaseProvider.overrideWithValue(
        GetAttendanceHistory(attendance),
      ),
      getAttendanceSummaryUseCaseProvider.overrideWithValue(
        GetAttendanceSummary(attendance),
      ),
      getAttendanceDetailsProvider.overrideWithValue(
        GetAttendanceDetails(attendance),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void main() {
  testWidgets('status badge uses a friendly label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AttendanceStatusBadge(status: AttendanceStatus.halfDay),
        ),
      ),
    );
    expect(find.text('Half day'), findsOneWidget);
    expect(find.text('HALF_DAY'), findsNothing);
  });

  testWidgets('attendance card shows backend duration and times',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AttendanceCard(
            record: sampleAttendance(
              checkOut: DateTime.parse('2026-08-31T18:02:00+05:00'),
              totalMinutes: 485,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('8h 05m'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
  });

  testWidgets('today card empty and checked-in states', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TodayAttendanceCard()),
      ),
    );
    expect(find.text('No attendance for today.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TodayAttendanceCard(
            record: sampleAttendance(checkOut: null, totalMinutes: null),
          ),
        ),
      ),
    );
    expect(find.text('Checked in'), findsOneWidget);
  });

  testWidgets('summary card displays backend counts and hides zero overtime',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AttendanceSummaryCard(summary: sampleSummary()),
        ),
      ),
    );
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Overtime'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AttendanceSummaryCard(
            summary: sampleSummary(overtimeMinutes: 60),
          ),
        ),
      ),
    );
    expect(find.text('Overtime'), findsOneWidget);
    expect(find.text('1h 00m'), findsOneWidget);
  });

  testWidgets('employee filter sheet has no employee picker',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AttendanceFilterSheet(
            current: AttendanceQuery(),
            canFilterByEmployee: false,
          ),
        ),
      ),
    );
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.textContaining('employee ID'), findsNothing);
    expect(find.textContaining('authorized'), findsNothing);
  });

  testWidgets('dashboard loads today and check-in shows a success message',
      (WidgetTester tester) async {
    final FakeAttendanceRepository attendance = FakeAttendanceRepository(
      today: null,
    );
    await tester.pumpWidget(
      _app(
        child: const AttendanceDashboardScreen(),
        user: sampleUser,
        attendance: attendance,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check In'), findsOneWidget);
    expect(find.text('Check Out'), findsNothing);

    await tester.tap(find.text('Check In'));
    await tester.pump();
    await tester.pump();
    expect(attendance.checkInCalls, 1);
    expect(find.text('Checked in.'), findsOneWidget);
  });

  testWidgets('check-out asks for confirmation and handles API errors',
      (WidgetTester tester) async {
    final FakeAttendanceRepository attendance = FakeAttendanceRepository(
      today: sampleAttendance(checkOut: null, totalMinutes: null),
    )..checkOutError = const ValidationException(
        'You must check in before checking out.',
      );
    await tester.pumpWidget(
      _app(
        child: const AttendanceDashboardScreen(),
        user: sampleUser,
        attendance: attendance,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check Out'), findsOneWidget);

    await tester.tap(find.text('Check Out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to check out?'), findsOneWidget);
    await tester.tap(find.text('Check Out').last);
    await tester.pumpAndSettle();
    expect(find.text('You must check in before checking out.'), findsOneWidget);
  });

  testWidgets('MANAGER does not see punch buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const AttendanceDashboardScreen(),
        user: managerUser,
        attendance: FakeAttendanceRepository(today: null),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check In'), findsNothing);
    expect(find.text('Check Out'), findsNothing);
    expect(find.textContaining('cannot check in'), findsOneWidget);
  });

  testWidgets('history shows an empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const AttendanceHistoryScreen(),
        user: sampleUser,
        attendance: FakeAttendanceRepository(records: <AttendanceRecord>[]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No attendance records found.'), findsOneWidget);
  });

  testWidgets('history shows an error state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const AttendanceHistoryScreen(),
        user: sampleUser,
        attendance: FakeAttendanceRepository()
          ..myError = const NetworkException()
          ..historyError = const NetworkException(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  testWidgets('history shows attendance cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const AttendanceHistoryScreen(),
        user: sampleUser,
        attendance: FakeAttendanceRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceCard), findsOneWidget);
  });

  testWidgets('calendar shows month navigation for backend data',
      (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    await tester.pumpWidget(
      _app(
        child: const AttendanceCalendarScreen(),
        user: sampleUser,
        attendance: FakeAttendanceRepository(
          records: <AttendanceRecord>[
            sampleAttendance(
              date: DateTime(now.year, now.month, 2),
              status: AttendanceStatus.late,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Attendance calendar'), findsOneWidget);
    expect(find.byTooltip('Previous month'), findsOneWidget);
    expect(find.byTooltip('Next month'), findsOneWidget);
  });

  testWidgets('details hide IP unless the API returned it',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const AttendanceDetailsScreen(attendanceId: 'att-1'),
        user: sampleUser,
        attendance: FakeAttendanceRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check-in IP'), findsNothing);

    await tester.pumpWidget(
      _app(
        child: const AttendanceDetailsScreen(attendanceId: 'att-1'),
        user: companyAdminUser,
        attendance: FakeAttendanceRepository(
          records: <AttendanceRecord>[
            sampleAttendance(
              checkInIp: '203.0.113.10',
              checkInLatitude: 24.86,
              checkInLongitude: 67.00,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check-in IP'), findsOneWidget);
    expect(find.text('203.0.113.10'), findsOneWidget);
  });

  testWidgets('unauthorized attendance detail shows a friendly error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const AttendanceDetailsScreen(attendanceId: 'secret'),
        user: sampleUser,
        attendance: FakeAttendanceRepository()
          ..detailError = const ForbiddenException(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('do not have access'), findsOneWidget);
  });
}

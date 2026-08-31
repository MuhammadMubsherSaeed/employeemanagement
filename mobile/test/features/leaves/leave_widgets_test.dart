import 'package:flutter/material.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/screens/apply_leave_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_balance_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_dashboard_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_request_details_screen.dart';
import 'package:flutter_base/features/leaves/presentation/screens/leave_requests_screen.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_balance_card.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_filter_sheet.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_request_card.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_status_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/leave_fakes.dart';

Widget _app({
  required Widget child,
  required User user,
  required FakeLeaveRepository leave,
}) {
  return ProviderScope(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      leaveRepositoryProvider.overrideWithValue(leave),
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
          body: LeaveStatusBadge(status: LeaveRequestStatus.pending),
        ),
      ),
    );
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('PENDING'), findsNothing);
  });

  testWidgets('balance card displays backend remaining days',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: LeaveBalanceCard(
            balance: sampleLeaveBalance(remainingDays: 12, usedDays: 3),
          ),
        ),
      ),
    );
    expect(find.textContaining('Remaining: 12 days'), findsOneWidget);
    expect(find.textContaining('Used: 3 days'), findsOneWidget);
  });

  testWidgets('request card hides employee for self-service views',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: LeaveRequestCard(request: sampleLeaveRequest()),
        ),
      ),
    );
    expect(find.text('Ada Lovelace'), findsNothing);
    expect(find.text('Annual Leave'), findsOneWidget);
  });

  testWidgets('employee filter sheet has no employee picker',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: LeaveFilterSheet(
            current: const LeaveRequestQuery(),
            leaveTypes: <LeaveType>[sampleLeaveType()],
            canFilterByEmployee: false,
          ),
        ),
      ),
    );
    expect(find.text('Status'), findsOneWidget);
    expect(find.textContaining('employee ID'), findsNothing);
    expect(find.textContaining('authorized'), findsNothing);
  });

  testWidgets('dashboard loads balances and hides apply for managers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveDashboardScreen(),
        user: managerUser,
        leave: FakeLeaveRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Apply for Leave'), findsNothing);
    expect(find.textContaining('Remaining: 12 days'), findsOneWidget);
  });

  testWidgets('employee dashboard shows apply and hides leave type management',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveDashboardScreen(),
        user: sampleUser,
        leave: FakeLeaveRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Apply for Leave'), findsOneWidget);
    expect(find.byTooltip('Leave types'), findsNothing);
  });

  testWidgets('balances show an empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveBalanceScreen(),
        user: sampleUser,
        leave: FakeLeaveRepository(balances: <LeaveBalance>[]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No leave balance available.'), findsOneWidget);
  });

  testWidgets('balances show an error state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveBalanceScreen(),
        user: sampleUser,
        leave: FakeLeaveRepository()..balancesError = const NetworkException(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  testWidgets('requests show an empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveRequestsScreen(),
        user: sampleUser,
        leave: FakeLeaveRepository(requests: <LeaveRequest>[]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No leave requests found.'), findsOneWidget);
  });

  testWidgets('requests show an error state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveRequestsScreen(),
        user: sampleUser,
        leave: FakeLeaveRepository()..listError = const NetworkException(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  testWidgets('employee cannot see approval actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveRequestDetailsScreen(requestId: 'req-1'),
        user: sampleUser,
        leave: FakeLeaveRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(find.text('Cancel request'), findsOneWidget);
  });

  testWidgets('manager sees approval actions for pending requests',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveRequestDetailsScreen(requestId: 'req-1'),
        user: managerUser,
        leave: FakeLeaveRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('unauthorized detail shows a friendly error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveRequestDetailsScreen(requestId: 'secret'),
        user: sampleUser,
        leave: FakeLeaveRepository()..detailError = const ForbiddenException(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('do not have access'), findsOneWidget);
  });

  testWidgets('apply leave validates required fields and blocks double submit',
      (WidgetTester tester) async {
    final FakeLeaveRepository leave = FakeLeaveRepository()
      ..delay = const Duration(milliseconds: 40);
    await tester.pumpWidget(
      _app(
        child: const ApplyLeaveScreen(),
        user: sampleUser,
        leave: leave,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Select a leave type.'), findsOneWidget);
    expect(leave.createCalls, 0);
  });

  testWidgets('cancel asks for confirmation', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const LeaveRequestDetailsScreen(requestId: 'req-1'),
        user: sampleUser,
        leave: FakeLeaveRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to cancel this leave request?'),
      findsOneWidget,
    );
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/domain/usecases/employee_usecases.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_base/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:flutter_base/features/employees/presentation/screens/employees_screen.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_card.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_filter_sheet.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_form.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_status_badge.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';

Widget _app({
  required Widget child,
  required User user,
  required FakeEmployeeRepository employees,
  FakeDepartmentRepository? departments,
  FakePositionRepository? positions,
}) {
  return ProviderScope(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      getEmployeesProvider.overrideWithValue(GetEmployees(employees)),
      getEmployeeProvider.overrideWithValue(GetEmployee(employees)),
      getMyEmployeeProvider.overrideWithValue(GetMyEmployee(employees)),
      createEmployeeProvider.overrideWithValue(CreateEmployee(employees)),
      updateEmployeeProvider.overrideWithValue(UpdateEmployee(employees)),
      deleteEmployeeProvider.overrideWithValue(DeleteEmployee(employees)),
      getDepartmentsProvider.overrideWithValue(
        GetDepartments(departments ?? FakeDepartmentRepository()),
      ),
      getPositionsProvider.overrideWithValue(
        GetPositions(positions ?? FakePositionRepository()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void main() {
  testWidgets('EmployeeStatusBadge uses a friendly label',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmployeeStatusBadge(status: EmployeeStatus.onLeave),
        ),
      ),
    );
    expect(find.text('On leave'), findsOneWidget);
    expect(find.text('ON_LEAVE'), findsNothing);
  });

  testWidgets('EmployeeCard and list item render shared employee data',
      (WidgetTester tester) async {
    final Employee employee = sampleEmployee();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              EmployeeCard(employee: employee, onTap: () => taps++),
              EmployeeListItem(employee: employee, onTap: () => taps++),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Ada Lovelace'), findsNWidgets(2));
    expect(find.text('EMP-001'), findsWidgets);
    expect(find.text('Active'), findsNWidgets(2));
    await tester.tap(find.byType(EmployeeCard));
    expect(taps, 1);
  });

  testWidgets('EmployeeSearchBar exposes clear and semantics',
      (WidgetTester tester) async {
    String value = 'seed';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EmployeeSearchBar(
            initialValue: 'Ada',
            onChanged: (String next) => value = next,
          ),
        ),
      ),
    );
    expect(find.text('Ada'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hopper');
    expect(value, 'Hopper');
    await tester.tap(find.byTooltip('Clear search'));
    expect(value, isEmpty);
  });

  testWidgets('filter sheet apply and clear all do not request until Apply',
      (WidgetTester tester) async {
    EmployeeQuery? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showEmployeeFilterSheet(
                    context: context,
                    current: const EmployeeQuery(search: 'keep-me'),
                    departments: FakeDepartmentRepository().items,
                    positions: FakePositionRepository().items,
                  );
                },
                child: const Text('Open filters'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<EmployeeStatus?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('On leave').last);
    await tester.pumpAndSettle();
    expect(result, isNull);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(result?.status, EmployeeStatus.onLeave);
    expect(result?.search, 'keep-me');
  });

  testWidgets('employees list shows loading then results for an admin',
      (WidgetTester tester) async {
    final FakeEmployeeRepository loading = FakeEmployeeRepository()
      ..delay = const Duration(milliseconds: 40);
    await tester.pumpWidget(
      _app(
        child: const EmployeesScreen(),
        user: companyAdminUser,
        employees: loading,
      ),
    );
    await tester.pump();
    expect(find.byType(AppLoader), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.byTooltip('Add employee'), findsOneWidget);
  });

  testWidgets('employees list shows an empty state', (WidgetTester tester) async {
    final FakeEmployeeRepository empty =
        FakeEmployeeRepository(employees: <Employee>[]);
    await tester.pumpWidget(
      _app(
        child: const EmployeesScreen(),
        user: companyAdminUser,
        employees: empty,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No employees found.'), findsOneWidget);
  });

  testWidgets('employees list shows an error state for a manager',
      (WidgetTester tester) async {
    final FakeEmployeeRepository failing = FakeEmployeeRepository()
      ..listError = const NetworkException();
    await tester.pumpWidget(
      _app(
        child: const EmployeesScreen(),
        user: managerUser,
        employees: failing,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorWidget), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byTooltip('Add employee'), findsNothing);
  });

  testWidgets('EMPLOYEE does not see directory management actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const EmployeesScreen(),
        user: sampleUser,
        employees: FakeEmployeeRepository(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Add employee'), findsNothing);
  });

  testWidgets('details overview loads and future tabs are placeholders',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: EmployeeDetailsScreen(
          employeeId: sampleEmployee().id,
        ),
        user: companyAdminUser,
        employees: FakeEmployeeRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ada Lovelace'), findsWidgets);
    expect(find.text('Employment information'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);

    await tester.tap(find.text('Attendance'));
    await tester.pumpAndSettle();
    expect(find.text('Attendance module coming soon.'), findsOneWidget);
    await tester.tap(find.text('Leaves'));
    await tester.pumpAndSettle();
    expect(find.text('Leaves module coming soon.'), findsOneWidget);
  });

  testWidgets('details loading and error states', (WidgetTester tester) async {
    final FakeEmployeeRepository slow = FakeEmployeeRepository()
      ..delay = const Duration(milliseconds: 40);
    await tester.pumpWidget(
      _app(
        child: const EmployeeDetailsScreen(employeeId: 'id-1'),
        user: managerUser,
        employees: slow,
      ),
    );
    await tester.pump();
    expect(find.byType(AppLoader), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));

    final FakeEmployeeRepository missing = FakeEmployeeRepository()
      ..detailError = const NotFoundException();
    await tester.pumpWidget(
      _app(
        child: const EmployeeDetailsScreen(employeeId: 'missing'),
        user: managerUser,
        employees: missing,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be found'), findsOneWidget);

    final FakeEmployeeRepository forbidden = FakeEmployeeRepository()
      ..detailError = const ForbiddenException();
    await tester.pumpWidget(
      _app(
        child: const EmployeeDetailsScreen(employeeId: 'secret'),
        user: sampleUser,
        employees: forbidden,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('do not have access'), findsOneWidget);
  });

  testWidgets('self profile hides management actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const EmployeeDetailsScreen(employeeId: 'me', isSelf: true),
        user: sampleUser,
        employees: FakeEmployeeRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My profile'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);
  });

  testWidgets('form validates required fields and maps backend errors',
      (WidgetTester tester) async {
    EmployeeWrite? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EmployeeForm(
              departments: const <Department>[],
              positions: const <Position>[],
              managers: const <Employee>[],
              fieldErrors: const <String, String>{
                'first_name': 'Backend rejected this name.',
              },
              onSubmit: (EmployeeWrite write) async {
                submitted = write;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Backend rejected this name.'), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('First name is required.'), findsOneWidget);
    expect(find.text('Last name is required.'), findsOneWidget);
    expect(find.text('Employee code is required.'), findsOneWidget);
    expect(submitted, isNull);
  });

  testWidgets('form submits populated data and prevents double submit',
      (WidgetTester tester) async {
    int calls = 0;
    final Completer<void> hold = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EmployeeForm(
              initial: sampleEmployee(),
              departments: FakeDepartmentRepository().items,
              positions: FakePositionRepository().items,
              managers: const <Employee>[],
              onSubmit: (EmployeeWrite write) async {
                calls += 1;
                await hold.future;
              },
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    hold.complete();
    await tester.pump();
  });
}

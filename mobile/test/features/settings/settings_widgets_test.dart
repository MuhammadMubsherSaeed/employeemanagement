import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/settings/domain/usecases/settings_usecases.dart';
import 'package:flutter_base/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_base/features/settings/presentation/screens/attendance_settings_screen.dart';
import 'package:flutter_base/features/settings/presentation/screens/company_settings_screen.dart';
import 'package:flutter_base/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_base/features/settings/presentation/widgets/working_days_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/settings_fakes.dart';

Widget _app({
  required Widget child,
  required User user,
  required FakeSettingsRepository settings,
}) {
  return ProviderScope(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      getCompanySettingsUseCaseProvider.overrideWithValue(
        GetCompanySettings(settings),
      ),
      updateCompanySettingsUseCaseProvider.overrideWithValue(
        UpdateCompanySettings(settings),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void main() {
  testWidgets('settings hub lists company and attendance sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const SettingsScreen(),
        user: companyAdminUser,
        settings: FakeSettingsRepository(),
      ),
    );
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
  });

  testWidgets('admin can edit company settings including timezone',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const CompanySettingsScreen(),
        user: companyAdminUser,
        settings: FakeSettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Company name'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('UTC'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).first, 'Acme Corp');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Company settings saved.'), findsOneWidget);
  });

  testWidgets('manager company settings are read-only', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const CompanySettingsScreen(),
        user: managerUser,
        settings: FakeSettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsNothing);
    expect(
      find.textContaining('Only administrators can change them'),
      findsOneWidget,
    );
  });

  testWidgets('employee attendance settings are read-only',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const AttendanceSettingsScreen(),
        user: sampleUser,
        settings: FakeSettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsNothing);
    expect(find.text('Overtime enabled'), findsOneWidget);
  });

  testWidgets('attendance screen shows a loading indicator while fetching',
      (WidgetTester tester) async {
    final FakeSettingsRepository repository = FakeSettingsRepository()
      ..delay = const Duration(milliseconds: 200);
    await tester.pumpWidget(
      _app(
        child: const AttendanceSettingsScreen(),
        user: companyAdminUser,
        settings: repository,
      ),
    );
    expect(find.byType(AppLoader), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('Work start time'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('working day chips toggle selection', (WidgetTester tester) async {
    List<String> selected = <String>['monday', 'tuesday'];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return WorkingDaysSelector(
                selected: selected,
                onChanged: (List<String> next) {
                  setState(() => selected = next);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Wednesday'));
    await tester.pump();
    expect(selected, contains('wednesday'));
    await tester.tap(find.text('Monday'));
    await tester.pump();
    expect(selected.contains('monday'), isFalse);
  });
}

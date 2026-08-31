import 'package:flutter/material.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/screens/device_details_screen.dart';
import 'package:flutter_base/features/devices/presentation/screens/devices_screen.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_card.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_filter_sheet.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_history_timeline.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_status_badge.dart';
import 'package:flutter_base/features/employees/domain/usecases/employee_usecases.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/device_fakes.dart';
import '../../helpers/employee_fakes.dart';

Widget _app({
  required Widget child,
  required User user,
  required FakeDeviceRepository devices,
  FakeEmployeeRepository? employees,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      deviceRepositoryProvider.overrideWithValue(devices),
      getEmployeesProvider.overrideWithValue(
        GetEmployees(employees ?? FakeEmployeeRepository()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('status badge uses a friendly label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: DeviceStatusBadge(status: DeviceStatus.available),
        ),
      ),
    );
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('AVAILABLE'), findsNothing);
  });

  testWidgets('device card hides cost and notes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DeviceCard(
            device: sampleDevice(cost: '9999.00', notes: 'SECRET'),
          ),
        ),
      ),
    );
    expect(find.text('LAP-001'), findsOneWidget);
    expect(find.textContaining('9999'), findsNothing);
    expect(find.text('SECRET'), findsNothing);
  });

  testWidgets('filter sheet has no employee picker', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: DeviceFilterSheet(current: DeviceQuery()),
        ),
      ),
    );
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Assignment'), findsOneWidget);
    expect(find.textContaining('employee ID'), findsNothing);
  });

  testWidgets('timeline shows the active assignment from backend history',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DeviceHistoryTimeline(
            items: <DeviceHistoryItem>[
              sampleHistoryItem(),
              sampleHistoryItem(
                id: 'hist-2',
                returnedAt: DateTime.parse('2026-03-01T09:00:00Z'),
                conditionOnReturn: 'Scratched',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Currently assigned'), findsOneWidget);
    expect(find.textContaining('Returned'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsWidgets);
  });

  testWidgets('employee inventory hides create action', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const DevicesScreen(),
        user: sampleUser,
        devices: FakeDeviceRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add device'), findsNothing);
  });

  testWidgets('admin inventory shows create action', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const DevicesScreen(),
        user: companyAdminUser,
        devices: FakeDeviceRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add device'), findsOneWidget);
  });

  testWidgets('inventory shows an empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const DevicesScreen(),
        user: managerUser,
        devices: FakeDeviceRepository(devices: <Device>[]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No devices match these filters'), findsOneWidget);
  });

  testWidgets('inventory shows an error state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const DevicesScreen(),
        user: managerUser,
        devices: FakeDeviceRepository()..listError = const NetworkException(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorWidget), findsOneWidget);
  });

  testWidgets('my devices empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const MyDeviceScreen(),
        user: sampleUser,
        devices: FakeDeviceRepository(devices: <Device>[]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No devices assigned to you'), findsOneWidget);
  });

  testWidgets('my devices supports multiple assigned devices',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const MyDeviceScreen(),
        user: sampleUser,
        devices: FakeDeviceRepository(
          devices: <Device>[
            sampleDevice(id: 'a', status: DeviceStatus.assigned),
            sampleDevice(
              id: 'b',
              assetCode: 'PHN-002',
              status: DeviceStatus.assigned,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('LAP-001'), findsOneWidget);
    expect(find.text('PHN-002'), findsOneWidget);
  });

  testWidgets('employee cannot see CRUD or assignment actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const DeviceDetailsScreen(deviceId: 'dev-1'),
        user: sampleUser,
        devices: FakeDeviceRepository(
          devices: <Device>[sampleDevice(status: DeviceStatus.assigned)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Assign'), findsNothing);
    expect(find.text('Return'), findsNothing);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);
    expect(find.textContaining('1299'), findsNothing);
  });

  testWidgets('manager sees assignment actions for an available device',
      (WidgetTester tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(
      _app(
        child: const DeviceDetailsScreen(deviceId: 'dev-1'),
        user: managerUser,
        devices: FakeDeviceRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Assign'), findsOneWidget);
    expect(find.text('Return'), findsNothing);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);
  });

  testWidgets('admin sees edit and delete; return asks for confirmation',
      (WidgetTester tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(
      _app(
        child: const DeviceDetailsScreen(deviceId: 'dev-1'),
        user: companyAdminUser,
        devices: FakeDeviceRepository(
          devices: <Device>[
            sampleDevice(
              status: DeviceStatus.assigned,
              cost: '1299.00',
              notes: 'Dock included',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.text('Return'), findsOneWidget);
    expect(find.text('1299.00'), findsOneWidget);

    await tester.tap(find.text('Return'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to mark this device as returned?'),
      findsOneWidget,
    );
  });

  testWidgets('unauthorized detail shows a friendly error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        child: const DeviceDetailsScreen(deviceId: 'secret'),
        user: sampleUser,
        devices: FakeDeviceRepository()..detailError = const ForbiddenException(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('do not have access'), findsOneWidget);
  });
}

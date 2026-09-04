import 'package:flutter/material.dart';
import 'package:flutter_base/core/auth/permission_gate.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/core/presentation/access_denied_screen.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';

void main() {
  testWidgets('PermissionGate hides unauthorized actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authControllerProvider.overrideWith(() => SeededAuthController(sampleUser)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PermissionGate(
              permission: Permissions.employeesCreate,
              child: Text('Add employee'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Add employee'), findsNothing);
  });

  testWidgets('PermissionGate shows authorized actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authControllerProvider.overrideWith(
            () => SeededAuthController(companyAdminUser),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PermissionGate(
              permission: Permissions.employeesCreate,
              child: Text('Add employee'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Add employee'), findsOneWidget);
  });

  testWidgets('AccessDeniedScreen uses a generic message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AccessDeniedScreen()),
    );
    expect(find.text(AccessDeniedScreen.message), findsOneWidget);
  });
}

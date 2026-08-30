import 'package:flutter_base/app.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/shared_prefs_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unauthenticated app opens the login screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          flutterSecureStorageProvider.overrideWithValue(
            const FlutterSecureStorage(),
          ),
        ],
        child: const HrmsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsAtLeastNWidgets(1));
    expect(find.text('Use your HRMS email and password.'), findsOneWidget);
  });
}

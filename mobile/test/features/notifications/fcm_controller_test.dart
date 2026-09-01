import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/session/logout_side_effects.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/notifications/domain/services/firebase_notification_service.dart';
import 'package:flutter_base/features/notifications/presentation/providers/fcm_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/notification_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('initializes once, registers token, and ignores duplicate init', () async {
    final FakeFcmGateway gateway = FakeFcmGateway();
    final FakeNotificationRepository repository = FakeNotificationRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authControllerProvider.overrideWith(
          () => SeededAuthController(sampleUser),
        ),
        notificationRepositoryProvider.overrideWithValue(repository),
        fcmGatewayProvider.overrideWithValue(gateway),
        flutterSecureStorageProvider.overrideWithValue(
          const FlutterSecureStorage(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final FirebaseNotificationService service =
        container.read(firebaseNotificationServiceProvider);
    await service.initialize();
    await service.initialize();
    expect(gateway.permissionCalls, 1);

    await container.read(fcmControllerProvider.notifier).syncAfterAuth();
    expect(repository.registerCalls, 1);
    expect(repository.lastRegister?.token, 'fcm-token-12345678');
    expect(
      await container.read(secureStorageServiceProvider).read(
            StorageKeys.fcmDeviceTokenId,
          ),
      'tok-1',
    );

    await container.read(fcmControllerProvider.notifier).syncAfterAuth();
    expect(repository.registerCalls, 1);
  });

  test('token refresh updates the existing registration', () async {
    final FakeFcmGateway gateway = FakeFcmGateway();
    final FakeNotificationRepository repository = FakeNotificationRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authControllerProvider.overrideWith(
          () => SeededAuthController(sampleUser),
        ),
        notificationRepositoryProvider.overrideWithValue(repository),
        fcmGatewayProvider.overrideWithValue(gateway),
        flutterSecureStorageProvider.overrideWithValue(
          const FlutterSecureStorage(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(fcmControllerProvider.notifier).syncAfterAuth();
    gateway.tokenRefresh.add('fcm-token-99999999');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repository.updateCalls, 1);
    expect(repository.lastUpdate?.token, 'fcm-token-99999999');
  });

  test('logout deactivates the current device token only', () async {
    final FakeFcmGateway gateway = FakeFcmGateway();
    final FakeNotificationRepository repository = FakeNotificationRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authControllerProvider.overrideWith(
          () => SeededAuthController(sampleUser),
        ),
        notificationRepositoryProvider.overrideWithValue(repository),
        fcmGatewayProvider.overrideWithValue(gateway),
        flutterSecureStorageProvider.overrideWithValue(
          const FlutterSecureStorage(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(fcmControllerProvider.notifier).syncAfterAuth();
    await container.read(logoutSideEffectsProvider).run();
    expect(repository.removeCalls, 1);
    expect(repository.lastId, 'tok-1');
  });

  test('disabled gateway never claims a successful send', () async {
    final FakeFcmGateway gateway = FakeFcmGateway(available: false, token: null);
    final FirebaseNotificationService service =
        FirebaseNotificationService(gateway);
    await service.initialize();
    expect(await service.getToken(), isNull);
    expect(gateway.permissionCalls, 0);
  });

  test('FCM errors are swallowed and do not crash', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..registerError = sampleNetworkError;
    final FakeFcmGateway gateway = FakeFcmGateway();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authControllerProvider.overrideWith(
          () => SeededAuthController(sampleUser),
        ),
        notificationRepositoryProvider.overrideWithValue(repository),
        fcmGatewayProvider.overrideWithValue(gateway),
        flutterSecureStorageProvider.overrideWithValue(
          const FlutterSecureStorage(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(fcmControllerProvider.notifier).syncAfterAuth();
    expect(container.read(fcmControllerProvider).registrationId, isNull);
  });
}

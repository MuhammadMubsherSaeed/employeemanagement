import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_action_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_list_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/providers/unread_count_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/notification_fakes.dart';

ProviderContainer _container(FakeNotificationRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(sampleUser)),
      notificationRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void main() {
  test('unread count loads and ignores negatives', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..unreadCount = 7;
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    await container
        .read(unreadNotificationCountControllerProvider.notifier)
        .refresh();
    expect(container.read(unreadNotificationCountControllerProvider).count, 7);
    expect(
      container.read(unreadNotificationCountControllerProvider).badgeLabel,
      '7',
    );

    repository.unreadCount = 120;
    await container
        .read(unreadNotificationCountControllerProvider.notifier)
        .refresh();
    expect(
      container.read(unreadNotificationCountControllerProvider).badgeLabel,
      '99+',
    );
  });

  test('mark as read is idempotent and prevents duplicate in-flight calls',
      () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    await container.read(notificationListControllerProvider.notifier).loadInitial();
    final AppNotification item = sampleNotification();

    final Future<AppNotification?> first = container
        .read(notificationActionControllerProvider.notifier)
        .markAsRead(item);
    final Future<AppNotification?> second = container
        .read(notificationActionControllerProvider.notifier)
        .markAsRead(item);
    await Future.wait(<Future<AppNotification?>>[first, second]);
    expect(repository.markCalls, 1);

    await container
        .read(notificationActionControllerProvider.notifier)
        .markAsRead(sampleNotification(isRead: true));
    expect(repository.markCalls, 1);
  });

  test('mark as read rolls back the list item on failure', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..markError = const NetworkException();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    await container.read(notificationListControllerProvider.notifier).loadInitial();
    final AppNotification? result = await container
        .read(notificationActionControllerProvider.notifier)
        .markAsRead(sampleNotification());
    expect(result, isNull);
    expect(
      container.read(notificationListControllerProvider).items.single.isRead,
      isFalse,
    );
  });

  test('mark all as read uses the bulk endpoint once', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..delay = const Duration(milliseconds: 20);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final Future<int?> first = container
        .read(notificationActionControllerProvider.notifier)
        .markAllAsRead();
    final Future<int?> second = container
        .read(notificationActionControllerProvider.notifier)
        .markAllAsRead();
    await Future.wait(<Future<int?>>[first, second]);
    expect(repository.markAllCalls, 1);
    expect(repository.markCalls, 0);
  });
}

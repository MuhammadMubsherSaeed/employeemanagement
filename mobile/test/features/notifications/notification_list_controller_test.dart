import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_list_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/states/notification_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/device_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/notification_fakes.dart';

ProviderContainer _container(
  FakeNotificationRepository repository, {
  User user = sampleUser,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      notificationRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

NotificationPage<AppNotification> _page({
  required int page,
  required bool hasMore,
  required List<AppNotification> results,
  int count = 40,
}) {
  return NotificationPage<AppNotification>(
    results: results,
    count: count,
    next: hasMore
        ? 'http://example.com/api/v1/notifications/?page=${page + 1}'
        : null,
  );
}

void main() {
  test('initial load, empty, and error states', () async {
    final FakeNotificationRepository empty = FakeNotificationRepository(
      items: <AppNotification>[],
    );
    final ProviderContainer container = _container(empty);
    addTearDown(container.dispose);

    await container.read(notificationListControllerProvider.notifier).loadInitial();
    expect(container.read(notificationListControllerProvider).isEmpty, isTrue);

    empty.listError = const NetworkException();
    empty.items = <AppNotification>[sampleNotification()];
    await container.read(notificationListControllerProvider.notifier).loadInitial();
    expect(
      container.read(notificationListControllerProvider).error,
      contains('internet'),
    );
  });

  test('pagination loads the next page once and stops on the last page',
      () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..delay = const Duration(milliseconds: 20)
      ..pageBuilder = (NotificationQuery query) {
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <AppNotification>[sampleNotification(id: 'a')],
          );
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <AppNotification>[sampleNotification(id: 'b')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final NotificationListController controller =
        container.read(notificationListControllerProvider.notifier);
    await controller.loadInitial();
    expect(container.read(notificationListControllerProvider).hasMore, isTrue);

    final Future<void> first = controller.loadMore();
    final Future<void> second = controller.loadMore();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.listCalls, 2);
    expect(container.read(notificationListControllerProvider).items.length, 2);
    expect(container.read(notificationListControllerProvider).hasMore, isFalse);

    await controller.loadMore();
    expect(repository.listCalls, 2);
  });

  test('filters and refresh reset to page one', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..pageBuilder = (NotificationQuery query) => _page(
            page: query.page,
            hasMore: query.page == 1,
            results: <AppNotification>[
              sampleNotification(id: 'p${query.page}'),
            ],
          );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final NotificationListController controller =
        container.read(notificationListControllerProvider.notifier);
    await controller.loadInitial();
    await controller.loadMore();
    expect(container.read(notificationListControllerProvider).query.page, 2);

    await controller.setReadFilter(false);
    expect(container.read(notificationListControllerProvider).query.page, 1);
    expect(container.read(notificationListControllerProvider).query.isRead, false);
    expect(repository.listQueries.last.isRead, false);

    await controller.refresh();
    expect(container.read(notificationListControllerProvider).query.page, 1);
  });

  test('load-more error keeps previous items', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..pageBuilder = (NotificationQuery query) {
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <AppNotification>[sampleNotification(id: 'a')],
          );
        }
        throw const NetworkException();
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final NotificationListController controller =
        container.read(notificationListControllerProvider.notifier);
    await controller.loadInitial();
    await controller.loadMore();
    final NotificationListState state =
        container.read(notificationListControllerProvider);
    expect(state.items.single.id, 'a');
    expect(state.error, contains('internet'));
  });

  test('auth change resets the inbox', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository();
    final SwitchingAuthController auth = SwitchingAuthController(sampleUser);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authControllerProvider.overrideWith(() => auth),
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(notificationListControllerProvider.notifier).loadInitial();
    expect(container.read(notificationListControllerProvider).items, isNotEmpty);

    auth.switchTo(managerUser);
    await Future<void>.delayed(Duration.zero);
    expect(repository.listCalls, greaterThan(1));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/providers/unread_count_controller.dart';
import 'package:flutter_base/features/notifications/presentation/screens/notification_details_screen.dart';
import 'package:flutter_base/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_card.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/unread_notification_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/notification_fakes.dart';

Widget _app({
  required Widget child,
  required User user,
  required FakeNotificationRepository notifications,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      notificationRepositoryProvider.overrideWithValue(notifications),
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
  testWidgets('unread card is distinguishable from a read card',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationCard(
            notification: sampleNotification(title: 'Unread item'),
          ),
        ),
      ),
    );
    expect(find.text('Unread item'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationCard(
            notification: sampleNotification(
              title: 'Read item',
              isRead: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Read item'), findsOneWidget);
  });

  testWidgets('badge hides at zero and caps at 99+', (WidgetTester tester) async {
    final FakeNotificationRepository repository = FakeNotificationRepository()
      ..unreadCount = 12;
    await tester.pumpWidget(
      _app(
        user: sampleUser,
        notifications: repository,
        child: const Scaffold(
          body: UnreadNotificationBadge(child: Icon(Icons.notifications)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('12'), findsOneWidget);

    repository.unreadCount = 120;
    final BuildContext context =
        tester.element(find.byType(UnreadNotificationBadge));
    await ProviderScope.containerOf(context)
        .read(unreadNotificationCountControllerProvider.notifier)
        .refresh();
    await tester.pump();
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('list shows empty, error, and items', (WidgetTester tester) async {
    _tallSurface(tester);
    final FakeNotificationRepository empty = FakeNotificationRepository(
      items: <AppNotification>[],
    );
    await tester.pumpWidget(
      _app(
        user: sampleUser,
        notifications: empty,
        child: const NotificationsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text("You're all caught up"), findsOneWidget);

    empty.listError = const NetworkException();
    empty.items = <AppNotification>[sampleNotification()];
    await tester.pumpWidget(
      _app(
        user: sampleUser,
        notifications: empty,
        child: const NotificationsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(AppErrorWidget), findsOneWidget);

    empty.listError = null;
    await tester.pumpWidget(
      _app(
        user: sampleUser,
        notifications: empty,
        child: const NotificationsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('System notice'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('details screen shows the message and type',
      (WidgetTester tester) async {
    _tallSurface(tester);
    final FakeNotificationRepository repository = FakeNotificationRepository(
      items: <AppNotification>[
        sampleNotification(title: 'Leave approved', message: 'Your leave was approved.'),
      ],
    );
    await tester.pumpWidget(
      _app(
        user: sampleUser,
        notifications: repository,
        child: const NotificationDetailsScreen(notificationId: 'n-1'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Leave approved'), findsOneWidget);
    expect(find.text('Your leave was approved.'), findsOneWidget);
  });
}

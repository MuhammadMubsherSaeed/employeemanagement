import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_router.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/services/fcm_gateway.dart';
import 'package:flutter_base/features/notifications/domain/services/notification_navigation_service.dart';
import 'package:flutter_base/features/notifications/presentation/providers/fcm_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_action_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_error_mapper.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationHost extends ConsumerStatefulWidget {
  const NotificationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends ConsumerState<NotificationHost>
    with WidgetsBindingObserver {
  StreamSubscription<PushMessage>? _foreground;
  StreamSubscription<PushMessage>? _opened;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_bind);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foreground?.cancel();
    _opened?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(fcmControllerProvider.notifier).onAppResumed());
    }
  }

  void _bind() {
    ref.read(fcmControllerProvider);
    final FcmController controller = ref.read(fcmControllerProvider.notifier);
    _foreground = controller.foregroundMessages.listen(_onForeground);
    _opened = controller.openedMessages.listen(_onOpened);
    _processPending();
  }

  void _processPending() {
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return;
    }
    final PushMessage? pending =
        ref.read(fcmControllerProvider.notifier).takePendingOpened();
    if (pending != null) {
      unawaited(_onOpened(pending));
    }
  }

  void _onForeground(PushMessage message) {
    if (!mounted) {
      return;
    }
    final String title = (message.title ?? message.payload.title ?? 'Notification')
        .trim();
    final String body = (message.body ?? message.payload.body ?? '').trim();
    final String text = body.isEmpty ? title : '$title: $body';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => unawaited(_onOpened(message)),
          ),
        ),
      );
  }

  Future<void> _onOpened(PushMessage message) async {
    final FcmController controller = ref.read(fcmControllerProvider.notifier);
    if (!controller.markHandled(message.messageId)) {
      return;
    }
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return;
    }
    final GoRouter router = ref.read(goRouterProvider);
    final UserRole role = auth.user.role;
    try {
      if (message.payload.hasNotificationId) {
        final AppNotification notification =
            await ref.read(getNotificationDetailUseCaseProvider)(
          message.payload.notificationId!,
        );
        unawaited(
          ref
              .read(notificationActionControllerProvider.notifier)
              .markAsRead(notification),
        );
        final NotificationDestination destination = ref
            .read(notificationNavigationServiceProvider)
            .destination(notification: notification, role: role);
        router.push(destination.location);
        return;
      }
      router.push(AppRoutes.notifications);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final AppException mapped = ErrorMapper.map(error);
      context.showSnack(
        NotificationErrorMapper.message(
          mapped,
          relatedEntity:
              mapped is NotFoundException || mapped is ForbiddenException,
        ),
      );
      router.push(AppRoutes.notifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      if (next is AuthAuthenticated) {
        Future<void>.microtask(_processPending);
      }
    });
    return widget.child;
  }
}

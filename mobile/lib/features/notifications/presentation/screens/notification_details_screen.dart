import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/services/notification_navigation_service.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_action_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_error_mapper.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_presentation.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_type_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationDetailsScreen extends ConsumerWidget {
  const NotificationDetailsScreen({super.key, required this.notificationId});

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppNotification> detail =
        ref.watch(notificationDetailProvider(notificationId));
    final AuthState auth = ref.watch(authControllerProvider);
    final UserRole role =
        auth is AuthAuthenticated ? auth.user.role : UserRole.unknown;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: detail.when(
        loading: () => const AppLoader(message: 'Loading notification…'),
        error: (Object error, StackTrace _) => AppErrorWidget(
          message: NotificationErrorMapper.message(error),
          onRetry: () =>
              ref.invalidate(notificationDetailProvider(notificationId)),
        ),
        data: (AppNotification notification) {
          return _NotificationDetailsBody(
            notification: notification,
            role: role,
          );
        },
      ),
    );
  }
}

class _NotificationDetailsBody extends ConsumerStatefulWidget {
  const _NotificationDetailsBody({
    required this.notification,
    required this.role,
  });

  final AppNotification notification;
  final UserRole role;

  @override
  ConsumerState<_NotificationDetailsBody> createState() =>
      _NotificationDetailsBodyState();
}

class _NotificationDetailsBodyState
    extends ConsumerState<_NotificationDetailsBody> {
  @override
  void initState() {
    super.initState();
    if (!widget.notification.isRead) {
      Future<void>.microtask(() {
        ref.read(notificationActionControllerProvider.notifier).markAsRead(
              widget.notification,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppNotification notification = widget.notification;
    final TextTheme text = Theme.of(context).textTheme;
    final NotificationNavigationService navigation =
        ref.watch(notificationNavigationServiceProvider);
    final NotificationDestination destination = navigation.destination(
      notification: notification,
      role: widget.role,
    );
    final String? actionLabel = navigation.relatedActionLabel(notification);
    final DateTime? created = notification.createdAt;

    return ListView(
      padding: AppSpacing.screen,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  NotificationTypeIcon(
                    type: notification.type,
                    unread: !notification.isRead,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      notification.displayTitle,
                      style: text.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  AppStatusBadge(
                    label: NotificationPresentation.category(notification.type),
                    tone: AppBadgeTone.info,
                  ),
                  AppStatusBadge(
                    label: notification.isRead ? 'Read' : 'Unread',
                    tone: notification.isRead
                        ? AppBadgeTone.neutral
                        : AppBadgeTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(notification.message, style: text.bodyLarge),
              if (created != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppDateFormatter.dateTime(created.toLocal()),
                  style: text.bodySmall,
                ),
              ],
              if (notification.hasEntity) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${notification.entityType.label} · ${notification.entityId}',
                  style: text.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && !destination.isInboxFallback) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: actionLabel,
            onPressed: () => _openRelated(context, destination.location),
          ),
        ],
      ],
    );
  }

  Future<void> _openRelated(BuildContext context, String location) async {
    try {
      context.push(location);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final AppException mapped = ErrorMapper.map(error);
      context.showSnack(
        NotificationErrorMapper.message(
          mapped,
          relatedEntity: mapped is NotFoundException || mapped is ForbiddenException,
        ),
      );
    }
  }
}

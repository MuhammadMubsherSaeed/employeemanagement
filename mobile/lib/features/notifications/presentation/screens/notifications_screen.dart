import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_base/features/notifications/domain/services/notification_navigation_service.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_action_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_list_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/states/notification_states.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_filter_sheet.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authControllerProvider);
    final UserRole role =
        auth is AuthAuthenticated ? auth.user.role : UserRole.unknown;
    final NotificationAccess access = NotificationAccess(role);
    final NotificationListState list =
        ref.watch(notificationListControllerProvider);
    final NotificationActionState actions =
        ref.watch(notificationActionControllerProvider);
    final int filters = list.query.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          IconButton(
            tooltip: filters == 0 ? 'Filters' : 'Filters ($filters)',
            onPressed: () => _openFilters(context, ref),
            icon: Badge(
              isLabelVisible: filters > 0,
              label: Text('$filters'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          if (access.canMarkRead)
            TextButton(
              onPressed: actions.isMarkingAll
                  ? null
                  : () => _markAll(context, ref),
              child: actions.isMarkingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mark all read'),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'all', label: Text('All')),
                ButtonSegment<String>(value: 'unread', label: Text('Unread')),
                ButtonSegment<String>(value: 'read', label: Text('Read')),
              ],
              selected: <String>{
                if (list.query.isRead == null) 'all',
                if (list.query.isRead == false) 'unread',
                if (list.query.isRead == true) 'read',
              },
              onSelectionChanged: (Set<String> next) {
                final String value = next.first;
                ref.read(notificationListControllerProvider.notifier).setReadFilter(
                      value == 'all'
                          ? null
                          : value == 'read',
                    );
              },
            ),
          ),
          Expanded(
            child: NotificationListView(
              onOpen: (AppNotification notification) {
                _open(context, ref, notification, role);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final NotificationListState list =
        ref.read(notificationListControllerProvider);
    final NotificationQuery? next = await showNotificationFilterSheet(
      context: context,
      current: list.query,
    );
    if (next == null) {
      return;
    }
    await ref
        .read(notificationListControllerProvider.notifier)
        .applyFilters(next);
  }

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Mark all as read',
      message: 'Mark every notification in this inbox as read?',
      confirmLabel: 'Mark all read',
    );
    if (confirmed != true) {
      return;
    }
    final int? updated = await ref
        .read(notificationActionControllerProvider.notifier)
        .markAllAsRead();
    if (!context.mounted) {
      return;
    }
    if (updated != null) {
      context.showSnack('Marked as read.');
    } else {
      final String? error = ref.read(notificationActionControllerProvider).error;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    UserRole role,
  ) {
    ref.read(notificationActionControllerProvider.notifier).markAsRead(
          notification,
        );
    final NotificationDestination destination = ref
        .read(notificationNavigationServiceProvider)
        .destination(notification: notification, role: role);
    if (destination.isInboxFallback) {
      context.push(AppRoutes.notification(notification.id));
      return;
    }
    context.push(destination.location);
  }
}

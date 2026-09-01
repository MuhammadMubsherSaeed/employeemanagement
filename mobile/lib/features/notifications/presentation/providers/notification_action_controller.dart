import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_invalidation.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_error_mapper.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_list_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/providers/unread_count_controller.dart';
import 'package:flutter_base/features/notifications/presentation/states/notification_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationActionController extends Notifier<NotificationActionState> {
  @override
  NotificationActionState build() => const NotificationActionState();

  Future<AppNotification?> markAsRead(AppNotification notification) async {
    if (notification.isRead) {
      return notification;
    }
    if (state.isMarking(notification.id) || state.isMarkingAll) {
      return null;
    }
    final Set<String> nextIds = <String>{...state.markingIds, notification.id};
    state = state.copyWith(markingIds: nextIds, clearError: true);
    final DateTime now = DateTime.now().toUtc();
    ref.read(notificationListControllerProvider.notifier).replaceNotification(
          notification.copyWith(isRead: true, readAt: now),
        );
    try {
      final AppNotification result =
          await ref.read(markNotificationAsReadUseCaseProvider)(
        notification.id,
      );
      ref
          .read(notificationListControllerProvider.notifier)
          .replaceNotification(result);
      ref.invalidate(notificationDetailProvider(notification.id));
      await ref
          .read(unreadNotificationCountControllerProvider.notifier)
          .refresh();
      invalidateEmployeeDashboard(ref);
      state = state.copyWith(
        markingIds: <String>{
          for (final String id in state.markingIds)
            if (id != notification.id) id,
        },
      );
      return result;
    } catch (error) {
      ref
          .read(notificationListControllerProvider.notifier)
          .replaceNotification(notification);
      state = state.copyWith(
        markingIds: <String>{
          for (final String id in state.markingIds)
            if (id != notification.id) id,
        },
        error: NotificationErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<int?> markAllAsRead() async {
    if (state.isMarkingAll) {
      return null;
    }
    state = state.copyWith(isMarkingAll: true, clearError: true);
    try {
      final int updated =
          await ref.read(markAllNotificationsAsReadUseCaseProvider)();
      ref.read(notificationListControllerProvider.notifier).markAllLocallyRead();
      await ref.read(notificationListControllerProvider.notifier).refresh();
      await ref
          .read(unreadNotificationCountControllerProvider.notifier)
          .refresh();
      invalidateEmployeeDashboard(ref);
      state = const NotificationActionState();
      return updated;
    } catch (error) {
      state = state.copyWith(
        isMarkingAll: false,
        error: NotificationErrorMapper.message(error),
      );
      return null;
    }
  }
}

final notificationActionControllerProvider =
    NotifierProvider<NotificationActionController, NotificationActionState>(
  NotificationActionController.new,
);

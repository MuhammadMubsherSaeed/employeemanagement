import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_error_mapper.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/providers/unread_count_controller.dart';
import 'package:flutter_base/features/notifications/presentation/states/notification_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationListController extends Notifier<NotificationListState> {
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  @override
  NotificationListState build() {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      state = const NotificationListState();
      if (next is AuthAuthenticated) {
        Future<void>.microtask(loadInitial);
      }
    });
    return const NotificationListState();
  }

  Future<void> loadInitial() {
    return _load(reset: true, refreshing: false);
  }

  Future<void> refresh() async {
    await _load(reset: true, refreshing: true);
    await ref.read(unreadNotificationCountControllerProvider.notifier).refresh();
  }

  Future<void> loadMore() {
    if (!state.hasMore ||
        state.isInitialLoading ||
        state.isLoadingMore ||
        _pageRequestInFlight) {
      return Future<void>.value();
    }
    return _load(reset: false, refreshing: false);
  }

  Future<void> applyFilters(NotificationQuery query) {
    state = state.copyWith(query: query.copyWith(page: 1));
    return loadInitial();
  }

  Future<void> setReadFilter(bool? isRead) {
    return applyFilters(
      state.query.copyWith(
        page: 1,
        isRead: isRead,
        clearIsRead: isRead == null,
      ),
    );
  }

  Future<void> clearFilters() {
    state = state.copyWith(query: state.query.clearedFilters());
    return loadInitial();
  }

  void replaceNotification(AppNotification notification) {
    final List<AppNotification> items = state.items
        .map(
          (AppNotification item) =>
              item.id == notification.id ? notification : item,
        )
        .toList();
    state = state.copyWith(items: items);
  }

  void markAllLocallyRead() {
    final DateTime now = DateTime.now().toUtc();
    state = state.copyWith(
      items: state.items
          .map(
            (AppNotification item) => item.isRead
                ? item
                : item.copyWith(isRead: true, readAt: now),
          )
          .toList(),
    );
  }

  Future<void> _load({required bool reset, required bool refreshing}) async {
    if (_pageRequestInFlight) {
      if (reset) {
        _pendingReload = true;
      }
      return;
    }
    _pageRequestInFlight = true;
    if (reset) {
      _pendingReload = false;
    }
    final int page = reset ? 1 : state.query.page + 1;
    final NotificationQuery requested = state.query.copyWith(page: page);
    state = state.copyWith(
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isRefreshing: refreshing,
      isLoadingMore: !reset,
      query: requested,
      clearError: true,
    );
    try {
      final NotificationPage<AppNotification> result =
          await ref.read(getNotificationsUseCaseProvider)(requested);
      if (!_sameQuery(state.query, requested)) {
        return;
      }
      final List<AppNotification> merged = reset
          ? result.results
          : _unique(<AppNotification>[...state.items, ...result.results]);
      state = state.copyWith(
        items: merged,
        count: result.count,
        hasMore: result.hasMore,
        isInitialLoading: false,
        isLoadingMore: false,
        isRefreshing: false,
        query: requested,
        clearError: true,
      );
    } catch (error) {
      if (_sameQuery(state.query, requested)) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          query: reset
              ? requested
              : requested.copyWith(
                  page: requested.page > 1 ? requested.page - 1 : 1,
                ),
          error: NotificationErrorMapper.message(error),
        );
      }
    } finally {
      _pageRequestInFlight = false;
    }
    if (!_sameQuery(state.query, requested) || _pendingReload) {
      _pendingReload = false;
      await _load(reset: true, refreshing: false);
    }
  }

  bool _sameQuery(NotificationQuery current, NotificationQuery requested) {
    return current.isRead == requested.isRead &&
        current.type == requested.type &&
        current.createdAtAfter == requested.createdAtAfter &&
        current.createdAtBefore == requested.createdAtBefore &&
        current.pageSize == requested.pageSize;
  }

  List<AppNotification> _unique(List<AppNotification> items) {
    final Set<String> seen = <String>{};
    return items.where((AppNotification item) => seen.add(item.id)).toList();
  }
}

final notificationListControllerProvider =
    NotifierProvider<NotificationListController, NotificationListState>(
  NotificationListController.new,
);

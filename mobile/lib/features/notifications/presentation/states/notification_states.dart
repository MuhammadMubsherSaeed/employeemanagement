import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';

class NotificationListState extends Equatable {
  const NotificationListState({
    this.items = const <AppNotification>[],
    this.query = const NotificationQuery(),
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.count = 0,
    this.error,
  });

  final List<AppNotification> items;
  final NotificationQuery query;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int count;
  final String? error;

  bool get isEmpty => !isInitialLoading && items.isEmpty && error == null;

  NotificationListState copyWith({
    List<AppNotification>? items,
    NotificationQuery? query,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? count,
    String? error,
    bool clearError = false,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      query: query ?? this.query,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      count: count ?? this.count,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        items,
        query,
        isInitialLoading,
        isLoadingMore,
        isRefreshing,
        hasMore,
        count,
        error,
      ];
}

class NotificationActionState extends Equatable {
  const NotificationActionState({
    this.markingIds = const <String>{},
    this.isMarkingAll = false,
    this.error,
  });

  final Set<String> markingIds;
  final bool isMarkingAll;
  final String? error;

  bool isMarking(String id) => markingIds.contains(id);

  bool get isBusy => isMarkingAll || markingIds.isNotEmpty;

  NotificationActionState copyWith({
    Set<String>? markingIds,
    bool? isMarkingAll,
    String? error,
    bool clearError = false,
  }) {
    return NotificationActionState(
      markingIds: markingIds ?? this.markingIds,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[markingIds, isMarkingAll, error];
}

class UnreadNotificationCountState extends Equatable {
  const UnreadNotificationCountState({
    this.count = 0,
    this.isLoading = false,
    this.error,
  });

  final int count;
  final bool isLoading;
  final String? error;

  String get badgeLabel {
    if (count <= 0) {
      return '';
    }
    if (count > 99) {
      return '99+';
    }
    return '$count';
  }

  bool get showBadge => count > 0;

  UnreadNotificationCountState copyWith({
    int? count,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return UnreadNotificationCountState(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[count, isLoading, error];
}

class FcmSessionState extends Equatable {
  const FcmSessionState({
    this.registrationId,
    this.lastToken,
    this.isSyncing = false,
  });

  final String? registrationId;
  final String? lastToken;
  final bool isSyncing;

  FcmSessionState copyWith({
    String? registrationId,
    String? lastToken,
    bool? isSyncing,
    bool clearRegistration = false,
    bool clearToken = false,
  }) {
    return FcmSessionState(
      registrationId:
          clearRegistration ? null : (registrationId ?? this.registrationId),
      lastToken: clearToken ? null : (lastToken ?? this.lastToken),
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => <Object?>[registrationId, lastToken, isSyncing];
}

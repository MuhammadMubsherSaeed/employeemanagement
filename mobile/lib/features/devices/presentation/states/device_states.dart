import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';

enum DeviceListKind { inventory, mine }

class DeviceListState extends Equatable {
  const DeviceListState({
    this.items = const <Device>[],
    this.query = const DeviceQuery(),
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.count = 0,
    this.error,
  });

  final List<Device> items;
  final DeviceQuery query;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int count;
  final String? error;

  bool get isEmpty => !isInitialLoading && items.isEmpty && error == null;

  DeviceListState copyWith({
    List<Device>? items,
    DeviceQuery? query,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? count,
    String? error,
    bool clearError = false,
  }) {
    return DeviceListState(
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

class DeviceHistoryState extends Equatable {
  const DeviceHistoryState({
    this.items = const <DeviceHistoryItem>[],
    this.query = const DeviceHistoryQuery(),
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.count = 0,
    this.error,
  });

  final List<DeviceHistoryItem> items;
  final DeviceHistoryQuery query;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int count;
  final String? error;

  bool get isEmpty => !isInitialLoading && items.isEmpty && error == null;

  DeviceHistoryItem? get activeAssignment {
    for (final DeviceHistoryItem item in items) {
      if (item.isActive) {
        return item;
      }
    }
    return null;
  }

  DeviceHistoryState copyWith({
    List<DeviceHistoryItem>? items,
    DeviceHistoryQuery? query,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? count,
    String? error,
    bool clearError = false,
  }) {
    return DeviceHistoryState(
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

class DeviceFormState extends Equatable {
  const DeviceFormState({
    this.isSubmitting = false,
    this.fieldErrors = const <String, String>{},
    this.error,
  });

  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final String? error;

  DeviceFormState copyWith({
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? error,
    bool clearError = false,
  }) {
    return DeviceFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[isSubmitting, fieldErrors, error];
}

class DeviceActionState extends Equatable {
  const DeviceActionState({
    this.isAssigning = false,
    this.isReturning = false,
    this.isDeleting = false,
    this.fieldErrors = const <String, String>{},
    this.error,
  });

  final bool isAssigning;
  final bool isReturning;
  final bool isDeleting;
  final Map<String, String> fieldErrors;
  final String? error;

  bool get isBusy => isAssigning || isReturning || isDeleting;

  DeviceActionState copyWith({
    bool? isAssigning,
    bool? isReturning,
    bool? isDeleting,
    Map<String, String>? fieldErrors,
    String? error,
    bool clearError = false,
  }) {
    return DeviceActionState(
      isAssigning: isAssigning ?? this.isAssigning,
      isReturning: isReturning ?? this.isReturning,
      isDeleting: isDeleting ?? this.isDeleting,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[isAssigning, isReturning, isDeleting, fieldErrors, error];
}

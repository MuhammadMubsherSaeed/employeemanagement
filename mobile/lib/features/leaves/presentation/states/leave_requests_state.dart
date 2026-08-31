import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';

class LeaveRequestsState extends Equatable {
  const LeaveRequestsState({
    this.items = const <LeaveRequest>[],
    this.query = const LeaveRequestQuery(),
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.count = 0,
    this.error,
  });

  final List<LeaveRequest> items;
  final LeaveRequestQuery query;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int count;
  final String? error;

  bool get isEmpty => !isInitialLoading && items.isEmpty && error == null;

  LeaveRequestsState copyWith({
    List<LeaveRequest>? items,
    LeaveRequestQuery? query,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? count,
    String? error,
    bool clearError = false,
  }) {
    return LeaveRequestsState(
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

enum LeaveListKind { all, history, pendingApproval }

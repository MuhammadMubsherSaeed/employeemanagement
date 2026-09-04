import 'package:flutter_base/features/audit_logs/domain/entities/audit_log.dart';

class AuditLogListState {
  const AuditLogListState({
    this.items = const <AuditLogEntry>[],
    this.count = 0,
    this.page = 1,
    this.hasMore = false,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<AuditLogEntry> items;
  final int count;
  final int page;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? error;

  AuditLogListState copyWith({
    List<AuditLogEntry>? items,
    int? count,
    int? page,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return AuditLogListState(
      items: items ?? this.items,
      count: count ?? this.count,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

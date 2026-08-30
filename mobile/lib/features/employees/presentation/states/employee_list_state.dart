import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';

class EmployeeListState extends Equatable {
  const EmployeeListState({
    this.items = const <Employee>[],
    this.query = const EmployeeQuery(),
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.count = 0,
    this.error,
  });

  final List<Employee> items;
  final EmployeeQuery query;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int count;
  final String? error;

  bool get isEmpty => !isInitialLoading && items.isEmpty && error == null;

  EmployeeListState copyWith({
    List<Employee>? items,
    EmployeeQuery? query,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? count,
    String? error,
    bool clearError = false,
  }) {
    return EmployeeListState(
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

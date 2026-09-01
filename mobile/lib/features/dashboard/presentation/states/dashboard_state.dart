import 'package:equatable/equatable.dart';

class DashboardViewState<T> extends Equatable {
  const DashboardViewState({
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  final T? data;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  bool get hasData => data != null;

  bool get isEmpty => !isLoading && error == null && data != null;

  DashboardViewState<T> copyWith({
    T? data,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearData = false,
    bool clearError = false,
  }) {
    return DashboardViewState<T>(
      data: clearData ? null : (data ?? this.data),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[data, isLoading, isRefreshing, error];
}

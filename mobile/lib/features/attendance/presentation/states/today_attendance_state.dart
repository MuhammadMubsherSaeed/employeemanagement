import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';

class TodayAttendanceState extends Equatable {
  const TodayAttendanceState({
    this.record,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isCheckingIn = false,
    this.isCheckingOut = false,
    this.error,
    this.actionError,
  });

  final AttendanceRecord? record;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCheckingIn;
  final bool isCheckingOut;
  final String? error;
  final String? actionError;

  PunchState get punchState => record?.punchState ?? PunchState.none;

  bool get isBusy => isCheckingIn || isCheckingOut;

  TodayAttendanceState copyWith({
    AttendanceRecord? record,
    bool? isLoading,
    bool? isRefreshing,
    bool? isCheckingIn,
    bool? isCheckingOut,
    String? error,
    String? actionError,
    bool clearRecord = false,
    bool clearError = false,
    bool clearActionError = false,
  }) {
    return TodayAttendanceState(
      record: clearRecord ? null : (record ?? this.record),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        record,
        isLoading,
        isRefreshing,
        isCheckingIn,
        isCheckingOut,
        error,
        actionError,
      ];
}

import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_error_mapper.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_history_controller.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/states/today_attendance_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodayAttendanceController extends Notifier<TodayAttendanceState> {
  @override
  TodayAttendanceState build() {
    return const TodayAttendanceState(isLoading: true);
  }

  Future<void> load() {
    return _load(refreshing: false);
  }

  Future<void> refresh() {
    return _load(refreshing: true);
  }

  Future<bool> checkIn() async {
    if (state.isBusy) {
      return false;
    }
    state = state.copyWith(isCheckingIn: true, clearActionError: true);
    try {
      final AttendanceRecord record = await ref.read(checkInUseCaseProvider)();
      state = state.copyWith(
        record: record,
        isCheckingIn: false,
        clearError: true,
        clearActionError: true,
      );
      _invalidateRelated();
      return true;
    } catch (error) {
      state = state.copyWith(
        isCheckingIn: false,
        actionError: AttendanceErrorMapper.message(error),
      );
      return false;
    }
  }

  Future<bool> checkOut() async {
    if (state.isBusy) {
      return false;
    }
    state = state.copyWith(isCheckingOut: true, clearActionError: true);
    try {
      final AttendanceRecord record = await ref.read(checkOutUseCaseProvider)();
      state = state.copyWith(
        record: record,
        isCheckingOut: false,
        clearError: true,
        clearActionError: true,
      );
      _invalidateRelated();
      return true;
    } catch (error) {
      state = state.copyWith(
        isCheckingOut: false,
        actionError: AttendanceErrorMapper.message(error),
      );
      return false;
    }
  }

  Future<void> _load({required bool refreshing}) async {
    state = state.copyWith(
      isLoading: !refreshing && state.record == null,
      isRefreshing: refreshing,
      clearError: true,
    );
    try {
      final AttendanceRecord? record =
          await ref.read(getTodayAttendanceProvider)();
      state = state.copyWith(
        record: record,
        clearRecord: record == null,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: AttendanceErrorMapper.message(error),
      );
    }
  }

  void _invalidateRelated() {
    ref.invalidate(attendanceSummaryProvider);
    ref.read(attendanceHistoryControllerProvider.notifier).refresh();
  }
}

final todayAttendanceProvider =
    NotifierProvider<TodayAttendanceController, TodayAttendanceState>(
  TodayAttendanceController.new,
);

import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_error_mapper.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/states/attendance_calendar_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceCalendarController extends Notifier<AttendanceCalendarState> {
  @override
  AttendanceCalendarState build() {
    final DateTime now = DateTime.now();
    return AttendanceCalendarState(month: DateTime(now.year, now.month));
  }

  Future<void> load() => _load(state.month);

  Future<void> goToCurrentMonth() {
    final DateTime now = DateTime.now();
    return _load(DateTime(now.year, now.month));
  }

  Future<void> previousMonth() {
    return _load(DateTime(state.month.year, state.month.month - 1));
  }

  Future<void> nextMonth() {
    final DateTime next = DateTime(state.month.year, state.month.month + 1);
    final DateTime now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) {
      return Future<void>.value();
    }
    return _load(next);
  }

  Future<void> _load(DateTime month) async {
    final DateTime start = monthStart(month);
    final DateTime end = monthEnd(month);
    state = state.copyWith(month: start, isLoading: true, clearError: true);
    try {
      final AttendancePage<AttendanceRecord> page =
          await ref.read(getAttendanceHistoryUseCaseProvider)(
        AttendanceQuery(
          startDate: start,
          endDate: end,
          page: 1,
          pageSize: AppConstants.maxPageSize,
          ordering: 'date',
        ),
        selfOnly: true,
      );
      state = state.copyWith(
        records: page.results,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: AttendanceErrorMapper.message(error),
      );
    }
  }
}

final attendanceCalendarControllerProvider =
    NotifierProvider<AttendanceCalendarController, AttendanceCalendarState>(
  AttendanceCalendarController.new,
);

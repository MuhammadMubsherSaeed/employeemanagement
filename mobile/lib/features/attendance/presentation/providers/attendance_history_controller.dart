import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_error_mapper.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/states/attendance_history_state.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceHistoryController extends Notifier<AttendanceHistoryState> {
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  @override
  AttendanceHistoryState build() {
    return const AttendanceHistoryState();
  }

  bool get _selfOnly {
    return AttendanceAccess(ref.read(authorizationProvider)).isSelfService;
  }

  Future<void> loadInitial() {
    return _load(reset: true, refreshing: false);
  }

  Future<void> refresh() {
    return _load(reset: true, refreshing: true);
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

  Future<void> applyFilters(AttendanceQuery query) {
    state = state.copyWith(query: query.copyWith(page: 1));
    return loadInitial();
  }

  Future<void> clearFilters() {
    state = state.copyWith(query: state.query.clearedFilters());
    return loadInitial();
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
    final AttendanceQuery requested = state.query.copyWith(page: page);
    state = state.copyWith(
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isRefreshing: refreshing,
      isLoadingMore: !reset,
      query: requested,
      clearError: true,
    );
    try {
      final AttendancePage<AttendanceRecord> result =
          await ref.read(getAttendanceHistoryUseCaseProvider)(
        requested,
        selfOnly: _selfOnly,
      );
      if (_sameQuery(state.query, requested)) {
        final List<AttendanceRecord> merged = reset
            ? result.results
            : _unique(<AttendanceRecord>[...state.items, ...result.results]);
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
      }
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
          error: AttendanceErrorMapper.message(error),
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

  bool _sameQuery(AttendanceQuery current, AttendanceQuery requested) {
    return current.startDate == requested.startDate &&
        current.endDate == requested.endDate &&
        current.status == requested.status &&
        current.employeeId == requested.employeeId &&
        current.departmentId == requested.departmentId &&
        current.ordering == requested.ordering &&
        current.pageSize == requested.pageSize;
  }

  List<AttendanceRecord> _unique(List<AttendanceRecord> items) {
    final Set<String> seen = <String>{};
    return items.where((AttendanceRecord item) => seen.add(item.id)).toList();
  }
}

final attendanceHistoryControllerProvider =
    NotifierProvider<AttendanceHistoryController, AttendanceHistoryState>(
  AttendanceHistoryController.new,
);

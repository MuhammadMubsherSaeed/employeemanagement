import 'dart:async';

import 'package:flutter_base/core/session/session_store.dart';
import 'package:flutter_base/core/session/user_session.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_error_mapper.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_providers.dart';
import 'package:flutter_base/features/reports/presentation/states/report_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportListController extends FamilyNotifier<ReportListState, ReportKind> {
  Timer? _debounce;
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  static const Duration searchDebounce = Duration(milliseconds: 400);

  @override
  ReportListState build(ReportKind arg) {
    ref.onDispose(() => _debounce?.cancel());
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      state = ReportListState(query: ReportQuery(kind: arg));
      if (next is AuthAuthenticated) {
        Future<void>.microtask(loadInitial);
      }
    });
    ref.listen(currentSessionProvider, (
      AsyncValue<UserSession?>? previous,
      AsyncValue<UserSession?> next,
    ) {
      final String? previousCompany = previous?.value?.companyId;
      final String? nextCompany = next.value?.companyId;
      if (previousCompany == nextCompany) {
        return;
      }
      state = ReportListState(query: ReportQuery(kind: arg));
      if (next.value != null) {
        Future<void>.microtask(loadInitial);
      }
    });
    return ReportListState(query: ReportQuery(kind: arg));
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

  Future<void> setSearch(String value, {bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      return _applySearch(value);
    }
    _debounce = Timer(searchDebounce, () => _applySearch(value));
    return Future<void>.value();
  }

  Future<void> applyFilters(ReportQuery query) {
    final ReportQuery next = query.sanitized().copyWith(page: 1);
    if (next.hasInvalidDateRange) {
      state = state.copyWith(
        query: next,
        error: ReportErrorMapper.invalidRange,
      );
      return Future<void>.value();
    }
    state = state.copyWith(query: next, clearItems: true, clearError: true);
    return loadInitial();
  }

  Future<void> clearFilters() {
    state = state.copyWith(
      query: state.query.clearedFilters(),
      clearItems: true,
      clearError: true,
    );
    return loadInitial();
  }

  Future<void> _applySearch(String value) {
    state = state.copyWith(
      query: state.query.copyWith(search: value, page: 1),
      clearItems: true,
    );
    return loadInitial();
  }

  Future<void> _load({required bool reset, required bool refreshing}) async {
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      state = ReportListState(query: ReportQuery(kind: arg));
      return;
    }
    final ReportQuery candidate = state.query.sanitized();
    if (candidate.hasInvalidDateRange) {
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        isRefreshing: false,
        error: ReportErrorMapper.invalidRange,
      );
      return;
    }
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
    final ReportQuery requested = candidate.copyWith(page: page);
    state = state.copyWith(
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isRefreshing: refreshing,
      isLoadingMore: !reset,
      query: requested,
      clearError: true,
    );
    try {
      final ReportPage<Object> result = await _fetch(requested);
      if (!state.query.matchesListQuery(requested)) {
        return;
      }
      final List<Object> merged = reset
          ? result.results
          : _unique(<Object>[...state.items, ...result.results]);
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
    } catch (error) {
      if (state.query.matchesListQuery(requested)) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          query: reset
              ? requested
              : requested.copyWith(
                  page: requested.page > 1 ? requested.page - 1 : 1,
                ),
          error: ReportErrorMapper.message(error),
        );
      }
    } finally {
      _pageRequestInFlight = false;
    }
    if (!state.query.matchesListQuery(requested) || _pendingReload) {
      _pendingReload = false;
      await _load(reset: true, refreshing: false);
    }
  }

  Future<ReportPage<Object>> _fetch(ReportQuery query) async {
    switch (arg) {
      case ReportKind.attendance:
        final ReportPage<AttendanceReportItem> page =
            await ref.read(getAttendanceReportProvider)(query);
        return ReportPage<Object>(
          results: page.results,
          count: page.count,
          next: page.next,
          previous: page.previous,
        );
      case ReportKind.leaves:
        final ReportPage<LeaveReportItem> page =
            await ref.read(getLeaveReportProvider)(query);
        return ReportPage<Object>(
          results: page.results,
          count: page.count,
          next: page.next,
          previous: page.previous,
        );
      case ReportKind.employees:
        final ReportPage<EmployeeReportItem> page =
            await ref.read(getEmployeeReportProvider)(query);
        return ReportPage<Object>(
          results: page.results,
          count: page.count,
          next: page.next,
          previous: page.previous,
        );
      case ReportKind.devices:
        final ReportPage<DeviceReportItem> page =
            await ref.read(getDeviceReportProvider)(query);
        return ReportPage<Object>(
          results: page.results,
          count: page.count,
          next: page.next,
          previous: page.previous,
        );
    }
  }

  List<Object> _unique(List<Object> items) {
    final Set<String> seen = <String>{};
    return items.where((Object item) {
      final String id = switch (item) {
        AttendanceReportItem row => row.id,
        LeaveReportItem row => row.id,
        EmployeeReportItem row => row.id,
        DeviceReportItem row => row.id,
        _ => item.hashCode.toString(),
      };
      return seen.add(id);
    }).toList();
  }
}

final reportListControllerProvider =
    NotifierProvider.family<ReportListController, ReportListState, ReportKind>(
  ReportListController.new,
);

import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/states/leave_requests_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveRequestsController extends FamilyNotifier<LeaveRequestsState, LeaveListKind> {
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  @override
  LeaveRequestsState build(LeaveListKind arg) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      state = LeaveRequestsState(query: _initialQuery(arg));
    });
    return LeaveRequestsState(query: _initialQuery(arg));
  }

  LeaveRequestQuery _initialQuery(LeaveListKind kind) {
    switch (kind) {
      case LeaveListKind.pendingApproval:
        return const LeaveRequestQuery(status: LeaveRequestStatus.pending);
      case LeaveListKind.history:
      case LeaveListKind.all:
        return const LeaveRequestQuery();
    }
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

  LeaveRequestQuery _sanitize(LeaveRequestQuery query) {
    if (LeaveAccess(ref.read(authorizationProvider)).isSelfService) {
      return query.copyWith(clearEmployee: true);
    }
    return query;
  }

  Future<void> applyFilters(LeaveRequestQuery query) {
    state = state.copyWith(query: _sanitize(query).copyWith(page: 1));
    return loadInitial();
  }

  Future<void> clearFilters() {
    state = state.copyWith(query: _initialQuery(arg).copyWith(page: 1));
    return loadInitial();
  }

  void replaceRequest(LeaveRequest request) {
    final List<LeaveRequest> items = state.items
        .map((LeaveRequest item) => item.id == request.id ? request : item)
        .toList();
    state = state.copyWith(items: items);
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
    final LeaveRequestQuery requested =
        _sanitize(state.query).copyWith(page: page);
    state = state.copyWith(
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isRefreshing: refreshing,
      isLoadingMore: !reset,
      query: requested,
      clearError: true,
    );
    try {
      final LeavePage<LeaveRequest> result =
          await ref.read(getLeaveRequestsUseCaseProvider)(requested);
      if (!_sameQuery(state.query, requested)) {
        return;
      }
      final List<LeaveRequest> merged = reset
          ? result.results
          : _unique(<LeaveRequest>[...state.items, ...result.results]);
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
      if (_sameQuery(state.query, requested)) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          query: reset
              ? requested
              : requested.copyWith(page: requested.page > 1 ? requested.page - 1 : 1),
          error: LeaveErrorMapper.message(error),
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

  bool _sameQuery(LeaveRequestQuery current, LeaveRequestQuery requested) {
    return current.status == requested.status &&
        current.leaveTypeId == requested.leaveTypeId &&
        current.startDate == requested.startDate &&
        current.endDate == requested.endDate &&
        current.employeeId == requested.employeeId &&
        current.ordering == requested.ordering &&
        current.pageSize == requested.pageSize;
  }

  List<LeaveRequest> _unique(List<LeaveRequest> items) {
    final Set<String> seen = <String>{};
    return items.where((LeaveRequest item) => seen.add(item.id)).toList();
  }
}

final leaveRequestsControllerProvider = NotifierProvider.family<
    LeaveRequestsController, LeaveRequestsState, LeaveListKind>(
  LeaveRequestsController.new,
);

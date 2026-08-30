import 'dart:async';

import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_error_mapper.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_base/features/employees/presentation/states/employee_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmployeeListController extends Notifier<EmployeeListState> {
  Timer? _debounce;
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  static const Duration searchDebounce = Duration(milliseconds: 400);

  @override
  EmployeeListState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const EmployeeListState();
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

  Future<void> applyFilters({
    String? departmentId,
    String? positionId,
    EmployeeQuery Function(EmployeeQuery current)? transform,
  }) {
    final EmployeeQuery next = (transform ??
            (EmployeeQuery current) => current.copyWith(
                  departmentId: departmentId,
                  positionId: positionId,
                ))(state.query)
        .copyWith(page: 1);
    state = state.copyWith(query: next);
    return loadInitial();
  }

  Future<void> setOrdering(String ordering) {
    state = state.copyWith(
      query: state.query.copyWith(ordering: ordering, page: 1),
    );
    return loadInitial();
  }

  Future<void> clearFilters() {
    state = state.copyWith(query: state.query.clearedFilters());
    return loadInitial();
  }

  void replaceEmployee(Employee employee) {
    final List<Employee> items = state.items
        .map((Employee item) => item.id == employee.id ? employee : item)
        .toList();
    state = state.copyWith(items: items);
  }

  void removeEmployee(String id) {
    state = state.copyWith(
      items: state.items.where((Employee item) => item.id != id).toList(),
      count: state.count > 0 ? state.count - 1 : 0,
    );
  }

  void prependEmployee(Employee employee) {
    if (state.items.any((Employee item) => item.id == employee.id)) {
      replaceEmployee(employee);
      return;
    }
    state = state.copyWith(
      items: <Employee>[employee, ...state.items],
      count: state.count + 1,
    );
  }

  Future<void> _applySearch(String value) {
    state = state.copyWith(
      query: state.query.copyWith(search: value, page: 1),
    );
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
    final EmployeeQuery requested = state.query.copyWith(page: page);
    state = state.copyWith(
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isRefreshing: refreshing,
      isLoadingMore: !reset,
      query: requested,
      clearError: true,
    );
    try {
      final EmployeePage<Employee> result =
          await ref.read(getEmployeesProvider)(requested);
      if (!_sameListQuery(state.query, requested)) {
        return;
      }
      final List<Employee> merged = reset
          ? result.results
          : _unique(<Employee>[...state.items, ...result.results]);
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
      if (_sameListQuery(state.query, requested)) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          error: EmployeeErrorMapper.message(error),
        );
      }
    } finally {
      _pageRequestInFlight = false;
    }
    if (!_sameListQuery(state.query, requested) || _pendingReload) {
      _pendingReload = false;
      await _load(reset: true, refreshing: false);
    }
  }

  bool _sameListQuery(EmployeeQuery current, EmployeeQuery requested) {
    return current.search == requested.search &&
        current.departmentId == requested.departmentId &&
        current.positionId == requested.positionId &&
        current.status == requested.status &&
        current.employmentType == requested.employmentType &&
        current.managerId == requested.managerId &&
        current.ordering == requested.ordering &&
        current.pageSize == requested.pageSize;
  }

  List<Employee> _unique(List<Employee> items) {
    final Set<String> seen = <String>{};
    return items.where((Employee item) => seen.add(item.id)).toList();
  }
}

final employeeListControllerProvider =
    NotifierProvider<EmployeeListController, EmployeeListState>(
  EmployeeListController.new,
);

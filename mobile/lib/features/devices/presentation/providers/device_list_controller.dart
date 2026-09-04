import 'dart:async';

import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceListController
    extends FamilyNotifier<DeviceListState, DeviceListKind> {
  Timer? _debounce;
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  static const Duration searchDebounce = Duration(milliseconds: 400);

  @override
  DeviceListState build(DeviceListKind arg) {
    ref.onDispose(() => _debounce?.cancel());
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      state = DeviceListState(query: _kindQuery());
      if (next is AuthAuthenticated) {
        Future<void>.microtask(loadInitial);
      }
    });
    return DeviceListState(query: _kindQuery());
  }

  DeviceQuery _kindQuery() {
    if (arg == DeviceListKind.mine) {
      return const DeviceQuery(assigned: true);
    }
    return const DeviceQuery();
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

  Future<void> applyFilters(DeviceQuery query) {
    state = state.copyWith(query: _sanitize(query).copyWith(page: 1));
    return loadInitial();
  }

  Future<void> clearFilters() {
    state = state.copyWith(query: state.query.clearedFilters());
    return loadInitial();
  }

  void replaceDevice(Device device) {
    final List<Device> items = state.items
        .map((Device item) => item.id == device.id ? device : item)
        .toList();
    state = state.copyWith(items: items);
  }

  void removeDevice(String id) {
    state = state.copyWith(
      items: state.items.where((Device item) => item.id != id).toList(),
      count: state.count > 0 ? state.count - 1 : 0,
    );
  }

  void prependDevice(Device device) {
    if (state.items.any((Device item) => item.id == device.id)) {
      replaceDevice(device);
      return;
    }
    state = state.copyWith(
      items: <Device>[device, ...state.items],
      count: state.count + 1,
    );
  }

  Future<void> _applySearch(String value) {
    state = state.copyWith(
      query: state.query.copyWith(search: value, page: 1),
    );
    return loadInitial();
  }

  DeviceQuery _sanitize(DeviceQuery query) {
    DeviceQuery next = query;
    if (arg == DeviceListKind.mine) {
      next = next.copyWith(assigned: true, clearEmployee: true);
    }
    if (!DeviceAccess(ref.read(authorizationProvider)).canFilterByEmployee) {
      return next.copyWith(clearEmployee: true);
    }
    return next;
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
    final DeviceQuery requested = _sanitize(state.query).copyWith(page: page);
    state = state.copyWith(
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isRefreshing: refreshing,
      isLoadingMore: !reset,
      query: requested,
      clearError: true,
    );
    try {
      final DevicePage<Device> result =
          await ref.read(getDevicesUseCaseProvider)(requested);
      if (_sameQuery(state.query, requested)) {
        final List<Device> merged = reset
            ? result.results
            : _unique(<Device>[...state.items, ...result.results]);
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
          error: DeviceErrorMapper.message(error),
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

  bool _sameQuery(DeviceQuery current, DeviceQuery requested) {
    return current.search == requested.search &&
        current.status == requested.status &&
        current.type == requested.type &&
        current.manufacturer == requested.manufacturer &&
        current.assigned == requested.assigned &&
        current.employeeId == requested.employeeId &&
        current.ordering == requested.ordering &&
        current.pageSize == requested.pageSize;
  }

  List<Device> _unique(List<Device> items) {
    final Set<String> seen = <String>{};
    return items.where((Device item) => seen.add(item.id)).toList();
  }
}

final deviceListControllerProvider = NotifierProvider.family<
    DeviceListController, DeviceListState, DeviceListKind>(
  DeviceListController.new,
);

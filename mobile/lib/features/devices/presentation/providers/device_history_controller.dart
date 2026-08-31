import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceHistoryController
    extends FamilyNotifier<DeviceHistoryState, String> {
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  @override
  DeviceHistoryState build(String arg) {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      state = const DeviceHistoryState();
      if (next is AuthAuthenticated) {
        Future<void>.microtask(loadInitial);
      }
    });
    return const DeviceHistoryState();
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
    final DeviceHistoryQuery requested = state.query.copyWith(page: page);
    state = state.copyWith(
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isRefreshing: refreshing,
      isLoadingMore: !reset,
      query: requested,
      clearError: true,
    );
    try {
      final DevicePage<DeviceHistoryItem> result =
          await ref.read(getDeviceHistoryUseCaseProvider)(arg, requested);
      if (state.query.pageSize != requested.pageSize) {
        return;
      }
      final List<DeviceHistoryItem> merged = reset
          ? result.results
          : _unique(<DeviceHistoryItem>[...state.items, ...result.results]);
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
    } finally {
      _pageRequestInFlight = false;
    }
    if (_pendingReload) {
      _pendingReload = false;
      await _load(reset: true, refreshing: false);
    }
  }

  List<DeviceHistoryItem> _unique(List<DeviceHistoryItem> items) {
    final Set<String> seen = <String>{};
    return items.where((DeviceHistoryItem item) => seen.add(item.id)).toList();
  }
}

final deviceHistoryControllerProvider = NotifierProvider.family<
    DeviceHistoryController, DeviceHistoryState, String>(
  DeviceHistoryController.new,
);

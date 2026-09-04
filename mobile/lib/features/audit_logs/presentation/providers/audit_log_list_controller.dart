import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/core/errors/error_mapper.dart';
import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/audit_logs/data/datasources/audit_log_remote_datasource.dart';
import 'package:flutter_base/features/audit_logs/domain/audit_log_access.dart';
import 'package:flutter_base/features/audit_logs/domain/entities/audit_log.dart';
import 'package:flutter_base/features/audit_logs/presentation/states/audit_log_list_state.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditLogRemoteDataSourceProvider = Provider<AuditLogRemoteDataSource>((
  Ref ref,
) {
  return AuditLogRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

class AuditLogListController extends Notifier<AuditLogListState> {
  bool _inFlight = false;
  bool _pendingReload = false;

  @override
  AuditLogListState build() {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      state = const AuditLogListState();
      if (next is AuthAuthenticated) {
        Future<void>.microtask(loadInitial);
      }
    });
    return const AuditLogListState();
  }

  Future<void> loadInitial() => _load(reset: true);

  Future<void> loadMore() {
    if (!state.hasMore ||
        state.isInitialLoading ||
        state.isLoadingMore ||
        _inFlight) {
      return Future<void>.value();
    }
    return _load(reset: false);
  }

  Future<void> refresh() => _load(reset: true);

  Future<void> _load({required bool reset}) async {
    if (!AuditLogAccess(ref.read(authorizationProvider)).canView) {
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        error: "You don't have permission to access this section.",
      );
      return;
    }
    if (_inFlight) {
      if (reset) {
        _pendingReload = true;
      }
      return;
    }
    _inFlight = true;
    if (reset) {
      _pendingReload = false;
    }
    final int page = reset ? 1 : state.page + 1;
    state = state.copyWith(
      isInitialLoading: reset && state.items.isEmpty,
      isLoadingMore: !reset,
      page: page,
      clearError: true,
    );
    try {
      final AuditLogPage<AuditLogEntry> result =
          await ref.read(auditLogRemoteDataSourceProvider).getLogs(page: page);
      final List<AuditLogEntry> merged = reset
          ? result.results
          : _unique(<AuditLogEntry>[...state.items, ...result.results]);
      state = state.copyWith(
        items: merged,
        count: result.count,
        hasMore: result.hasMore,
        isInitialLoading: false,
        isLoadingMore: false,
        page: page,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        page: reset ? page : (page > 1 ? page - 1 : 1),
        error: ErrorMapper.map(error).message,
      );
    } finally {
      _inFlight = false;
    }
    if (_pendingReload) {
      _pendingReload = false;
      await _load(reset: true);
    }
  }

  List<AuditLogEntry> _unique(List<AuditLogEntry> items) {
    final Set<String> seen = <String>{};
    return items.where((AuditLogEntry item) => seen.add(item.id)).toList();
  }
}

final auditLogListControllerProvider =
    NotifierProvider<AuditLogListController, AuditLogListState>(
  AuditLogListController.new,
);

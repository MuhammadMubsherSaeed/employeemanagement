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
    if (!state.hasMore || state.isInitialLoading || state.isLoadingMore) {
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
      return;
    }
    _inFlight = true;
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
          : <AuditLogEntry>[...state.items, ...result.results];
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
        error: ErrorMapper.map(error).message,
      );
    } finally {
      _inFlight = false;
    }
  }
}

final auditLogListControllerProvider =
    NotifierProvider<AuditLogListController, AuditLogListState>(
  AuditLogListController.new,
);

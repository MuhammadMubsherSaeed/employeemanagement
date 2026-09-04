import 'dart:async';

import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_error_mapper.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_providers.dart';
import 'package:flutter_base/features/documents/presentation/states/document_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentListController
    extends AutoDisposeFamilyNotifier<DocumentListState, String> {
  Timer? _debounce;
  bool _pageRequestInFlight = false;
  bool _pendingReload = false;

  static const Duration searchDebounce = Duration(milliseconds: 400);

  @override
  DocumentListState build(String employeeId) {
    ref.watch(authControllerProvider.select((AuthState state) {
      return state is AuthAuthenticated ? state.user.id : null;
    }));
    ref.onDispose(() => _debounce?.cancel());
    return const DocumentListState();
  }

  String get employeeId => arg;

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

  Future<void> setType(DocumentType? type) {
    state = state.copyWith(
      query: state.query.copyWith(
        documentType: type,
        page: 1,
        clearType: type == null,
      ),
    );
    return loadInitial();
  }

  Future<void> _applySearch(String value) {
    state = state.copyWith(
      query: state.query.copyWith(search: value, page: 1),
    );
    return loadInitial();
  }

  void prepend(EmployeeDocument document) {
    state = state.copyWith(
      items: <EmployeeDocument>[document, ...state.items],
      count: state.count + 1,
    );
  }

  void remove(String documentId) {
    state = state.copyWith(
      items: state.items
          .where((EmployeeDocument item) => item.id != documentId)
          .toList(),
      count: state.count > 0 ? state.count - 1 : 0,
    );
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
    final DocumentQuery requested = state.query.copyWith(page: page);
    state = state.copyWith(
      query: requested,
      isInitialLoading: reset && !refreshing && state.items.isEmpty,
      isLoadingMore: !reset,
      isRefreshing: refreshing,
      clearError: true,
    );
    try {
      final DocumentPage<EmployeeDocument> result =
          await ref.read(listEmployeeDocumentsProvider)(
        employeeId: employeeId,
        query: requested,
      );
      if (_sameListQuery(state.query, requested)) {
        final List<EmployeeDocument> items = reset
            ? result.results
            : _unique(<EmployeeDocument>[...state.items, ...result.results]);
        state = state.copyWith(
          items: items,
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
      if (_sameListQuery(state.query, requested)) {
        state = state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          query: reset
              ? requested
              : requested.copyWith(
                  page: requested.page > 1 ? requested.page - 1 : 1,
                ),
          error: DocumentErrorMapper.message(error),
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

  bool _sameListQuery(DocumentQuery current, DocumentQuery requested) {
    return current.search == requested.search &&
        current.documentType == requested.documentType &&
        current.uploadedBy == requested.uploadedBy &&
        current.dateFrom == requested.dateFrom &&
        current.dateTo == requested.dateTo &&
        current.ordering == requested.ordering &&
        current.pageSize == requested.pageSize;
  }

  List<EmployeeDocument> _unique(List<EmployeeDocument> items) {
    final Set<String> seen = <String>{};
    return items
        .where((EmployeeDocument item) => seen.add(item.id))
        .toList();
  }
}

class DocumentMutationController extends Notifier<DocumentMutationState> {
  @override
  DocumentMutationState build() => const DocumentMutationState();

  Future<EmployeeDocument?> upload({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  }) async {
    if (state.uploading) {
      return null;
    }
    state = state.copyWith(uploading: true, clearError: true);
    try {
      final EmployeeDocument document =
          await ref.read(uploadEmployeeDocumentProvider)(
        employeeId: employeeId,
        documentType: documentType,
        file: file,
        title: title,
      );
      ref.read(employeeDocumentsProvider(employeeId).notifier).prepend(document);
      state = state.copyWith(uploading: false);
      return document;
    } catch (error) {
      state = state.copyWith(
        uploading: false,
        error: DocumentErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<bool> delete({
    required String employeeId,
    required String documentId,
  }) async {
    if (state.deleting) {
      return false;
    }
    state = state.copyWith(deleting: true, clearError: true);
    try {
      await ref.read(deleteEmployeeDocumentProvider)(
        employeeId: employeeId,
        documentId: documentId,
      );
      ref.read(employeeDocumentsProvider(employeeId).notifier).remove(documentId);
      state = state.copyWith(deleting: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        deleting: false,
        error: DocumentErrorMapper.message(error),
      );
      return false;
    }
  }

  Future<DownloadedBytes?> download({
    required String employeeId,
    required String documentId,
  }) async {
    if (state.downloading) {
      return null;
    }
    state = state.copyWith(downloading: true, clearError: true);
    try {
      final DownloadedBytes file = await ref.read(downloadEmployeeDocumentProvider)(
        employeeId: employeeId,
        documentId: documentId,
      );
      state = state.copyWith(downloading: false);
      return file;
    } catch (error) {
      state = state.copyWith(
        downloading: false,
        error: DocumentErrorMapper.message(error),
      );
      return null;
    }
  }
}

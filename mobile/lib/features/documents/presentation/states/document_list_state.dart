import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';

class DocumentListState extends Equatable {
  const DocumentListState({
    this.items = const <EmployeeDocument>[],
    this.query = const DocumentQuery(),
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.count = 0,
    this.error,
  });

  final List<EmployeeDocument> items;
  final DocumentQuery query;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int count;
  final String? error;

  bool get isEmpty => !isInitialLoading && items.isEmpty && error == null;

  DocumentListState copyWith({
    List<EmployeeDocument>? items,
    DocumentQuery? query,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? count,
    String? error,
    bool clearError = false,
  }) {
    return DocumentListState(
      items: items ?? this.items,
      query: query ?? this.query,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      count: count ?? this.count,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        items,
        query,
        isInitialLoading,
        isLoadingMore,
        isRefreshing,
        hasMore,
        count,
        error,
      ];
}

class DocumentMutationState extends Equatable {
  const DocumentMutationState({
    this.uploading = false,
    this.deleting = false,
    this.downloading = false,
    this.error,
  });

  final bool uploading;
  final bool deleting;
  final bool downloading;
  final String? error;

  bool get isBusy => uploading || deleting || downloading;

  DocumentMutationState copyWith({
    bool? uploading,
    bool? deleting,
    bool? downloading,
    String? error,
    bool clearError = false,
  }) {
    return DocumentMutationState(
      uploading: uploading ?? this.uploading,
      deleting: deleting ?? this.deleting,
      downloading: downloading ?? this.downloading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[uploading, deleting, downloading, error];
}

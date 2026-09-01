import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:flutter_base/features/documents/data/repositories/document_repository_impl.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/repositories/document_repository.dart';
import 'package:flutter_base/features/documents/domain/services/document_file_picker.dart';
import 'package:flutter_base/features/documents/domain/services/secure_document_file_service.dart';
import 'package:flutter_base/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_list_controller.dart';
import 'package:flutter_base/features/documents/presentation/states/document_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final documentRemoteDataSourceProvider =
    Provider<DocumentRemoteDataSource>((Ref ref) {
  return DocumentRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final documentRepositoryProvider = Provider<DocumentRepository>((Ref ref) {
  return DocumentRepositoryImpl(ref.watch(documentRemoteDataSourceProvider));
});

final documentFilePickerProvider = Provider<DocumentFilePicker>((Ref ref) {
  return FilePickerDocumentFilePicker();
});

final secureDocumentFileServiceProvider =
    Provider<SecureDocumentFileService>((Ref ref) {
  return const PathProviderSecureDocumentFileService();
});

final listEmployeeDocumentsProvider =
    Provider<ListEmployeeDocuments>((Ref ref) {
  return ListEmployeeDocuments(ref.watch(documentRepositoryProvider));
});

final getEmployeeDocumentProvider = Provider<GetEmployeeDocument>((Ref ref) {
  return GetEmployeeDocument(ref.watch(documentRepositoryProvider));
});

final uploadEmployeeDocumentProvider =
    Provider<UploadEmployeeDocument>((Ref ref) {
  return UploadEmployeeDocument(ref.watch(documentRepositoryProvider));
});

final deleteEmployeeDocumentProvider =
    Provider<DeleteEmployeeDocument>((Ref ref) {
  return DeleteEmployeeDocument(ref.watch(documentRepositoryProvider));
});

final downloadEmployeeDocumentProvider =
    Provider<DownloadEmployeeDocument>((Ref ref) {
  return DownloadEmployeeDocument(ref.watch(documentRepositoryProvider));
});

final employeeDocumentsProvider = NotifierProvider.autoDispose
    .family<DocumentListController, DocumentListState, String>(
  DocumentListController.new,
);

final documentMutationControllerProvider =
    NotifierProvider<DocumentMutationController, DocumentMutationState>(
  DocumentMutationController.new,
);

class DocumentLookup {
  const DocumentLookup({required this.employeeId, required this.documentId});

  final String employeeId;
  final String documentId;

  @override
  bool operator ==(Object other) {
    return other is DocumentLookup &&
        other.employeeId == employeeId &&
        other.documentId == documentId;
  }

  @override
  int get hashCode => Object.hash(employeeId, documentId);
}

final documentDetailsProvider = FutureProvider.autoDispose
    .family<EmployeeDocument, DocumentLookup>((Ref ref, DocumentLookup lookup) {
  ref.watch(authControllerProvider);
  return ref.watch(getEmployeeDocumentProvider)(
    employeeId: lookup.employeeId,
    documentId: lookup.documentId,
  );
});

import 'package:flutter_base/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';
import 'package:flutter_base/features/documents/domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._remote);

  final DocumentRemoteDataSource _remote;

  @override
  Future<DocumentPage<EmployeeDocument>> listDocuments({
    required String employeeId,
    required DocumentQuery query,
  }) {
    return _remote.listDocuments(employeeId: employeeId, query: query);
  }

  @override
  Future<EmployeeDocument> getDocument({
    required String employeeId,
    required String documentId,
  }) {
    return _remote.getDocument(
      employeeId: employeeId,
      documentId: documentId,
    );
  }

  @override
  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  }) {
    return _remote.uploadDocument(
      employeeId: employeeId,
      documentType: documentType,
      file: file,
      title: title,
    );
  }

  @override
  Future<void> deleteDocument({
    required String employeeId,
    required String documentId,
  }) {
    return _remote.deleteDocument(
      employeeId: employeeId,
      documentId: documentId,
    );
  }

  @override
  Future<DownloadedBytes> downloadDocument({
    required String employeeId,
    required String documentId,
  }) {
    return _remote.downloadDocument(
      employeeId: employeeId,
      documentId: documentId,
    );
  }
}

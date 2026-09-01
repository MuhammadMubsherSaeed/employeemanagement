import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';
import 'package:flutter_base/features/documents/domain/repositories/document_repository.dart';

class ListEmployeeDocuments {
  const ListEmployeeDocuments(this._repository);

  final DocumentRepository _repository;

  Future<DocumentPage<EmployeeDocument>> call({
    required String employeeId,
    required DocumentQuery query,
  }) {
    return _repository.listDocuments(employeeId: employeeId, query: query);
  }
}

class GetEmployeeDocument {
  const GetEmployeeDocument(this._repository);

  final DocumentRepository _repository;

  Future<EmployeeDocument> call({
    required String employeeId,
    required String documentId,
  }) {
    return _repository.getDocument(
      employeeId: employeeId,
      documentId: documentId,
    );
  }
}

class UploadEmployeeDocument {
  const UploadEmployeeDocument(this._repository);

  final DocumentRepository _repository;

  Future<EmployeeDocument> call({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  }) {
    return _repository.uploadDocument(
      employeeId: employeeId,
      documentType: documentType,
      file: file,
      title: title,
    );
  }
}

class DeleteEmployeeDocument {
  const DeleteEmployeeDocument(this._repository);

  final DocumentRepository _repository;

  Future<void> call({
    required String employeeId,
    required String documentId,
  }) {
    return _repository.deleteDocument(
      employeeId: employeeId,
      documentId: documentId,
    );
  }
}

class DownloadEmployeeDocument {
  const DownloadEmployeeDocument(this._repository);

  final DocumentRepository _repository;

  Future<DownloadedBytes> call({
    required String employeeId,
    required String documentId,
  }) {
    return _repository.downloadDocument(
      employeeId: employeeId,
      documentId: documentId,
    );
  }
}

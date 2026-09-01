import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';

abstract class DocumentRepository {
  Future<DocumentPage<EmployeeDocument>> listDocuments({
    required String employeeId,
    required DocumentQuery query,
  });

  Future<EmployeeDocument> getDocument({
    required String employeeId,
    required String documentId,
  });

  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  });

  Future<void> deleteDocument({
    required String employeeId,
    required String documentId,
  });

  Future<DownloadedBytes> downloadDocument({
    required String employeeId,
    required String documentId,
  });
}

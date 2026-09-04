import 'package:flutter_base/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';
import 'package:flutter_base/features/documents/domain/repositories/document_repository.dart';

Map<String, dynamic> sampleDocumentJson({
  String id = 'doc-1',
  String type = 'CONTRACT',
}) {
  return <String, dynamic>{
    'id': id,
    'company_id': 'co-1',
    'employee_id': 'emp-1',
    'employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
    },
    'document_type': type,
    'title': 'Employment contract',
    'description': '',
    'file_name': 'employment-contract.pdf',
    'file_size': 245678,
    'mime_type': 'application/pdf',
    'status': 'ACTIVE',
    'uploaded_by': <String, dynamic>{'id': 10, 'email': 'admin@example.com'},
    'created_at': '2026-08-01T08:00:00Z',
    'updated_at': '2026-08-01T08:00:00Z',
  };
}

EmployeeDocument sampleDocument({String id = 'doc-1'}) {
  return EmployeeDocument.fromJson(sampleDocumentJson(id: id));
}

class FakeDocumentRemote implements DocumentRemoteDataSource {
  FakeDocumentRemote({this.document});

  EmployeeDocument? document;
  String? lastEmployeeId;
  String? lastUploadName;
  String? deletedId;
  DocumentQuery? lastQuery;

  @override
  Future<DocumentPage<EmployeeDocument>> listDocuments({
    required String employeeId,
    required DocumentQuery query,
  }) async {
    lastEmployeeId = employeeId;
    lastQuery = query;
    return DocumentPage<EmployeeDocument>(
      results: <EmployeeDocument>[document ?? sampleDocument()],
      count: 1,
    );
  }

  @override
  Future<EmployeeDocument> getDocument({
    required String employeeId,
    required String documentId,
  }) async {
    lastEmployeeId = employeeId;
    return document ?? sampleDocument(id: documentId);
  }

  @override
  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  }) async {
    lastEmployeeId = employeeId;
    lastUploadName = file.name;
    return document ?? sampleDocument();
  }

  @override
  Future<void> deleteDocument({
    required String employeeId,
    required String documentId,
  }) async {
    lastEmployeeId = employeeId;
    deletedId = documentId;
  }

  @override
  Future<DownloadedBytes> downloadDocument({
    required String employeeId,
    required String documentId,
  }) async {
    lastEmployeeId = employeeId;
    return const DownloadedBytes(
      bytes: <int>[37, 80, 68, 70],
      filename: 'employment-contract.pdf',
      mimeType: 'application/pdf',
    );
  }
}

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({List<EmployeeDocument>? items})
      : items = items ?? <EmployeeDocument>[sampleDocument()];

  List<EmployeeDocument> items;
  Object? listError;
  Object? uploadError;
  Object? deleteError;
  Object? downloadError;
  bool uploading = false;
  String? lastEmployeeId;
  DocumentQuery? lastQuery;
  Duration delay = Duration.zero;
  final List<DocumentQuery> queries = <DocumentQuery>[];

  @override
  Future<DocumentPage<EmployeeDocument>> listDocuments({
    required String employeeId,
    required DocumentQuery query,
  }) async {
    lastEmployeeId = employeeId;
    lastQuery = query;
    queries.add(query);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (listError != null) {
      throw listError!;
    }
    final String search = query.search.trim().toLowerCase();
    final List<EmployeeDocument> results = search.isEmpty
        ? items
        : items
            .where((EmployeeDocument item) =>
                item.title.toLowerCase().contains(search) ||
                item.fileName.toLowerCase().contains(search))
            .toList();
    return DocumentPage<EmployeeDocument>(
      results: results,
      count: results.length,
      next: query.page == 1 && results.length > 1 ? 'next' : null,
    );
  }

  @override
  Future<EmployeeDocument> getDocument({
    required String employeeId,
    required String documentId,
  }) async {
    return items.firstWhere(
      (EmployeeDocument item) => item.id == documentId,
      orElse: () => items.first,
    );
  }

  @override
  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required DocumentType documentType,
    required DocumentFile file,
    String? title,
  }) async {
    if (uploadError != null) {
      throw uploadError!;
    }
    lastEmployeeId = employeeId;
    return sampleDocument(id: 'doc-new');
  }

  @override
  Future<void> deleteDocument({
    required String employeeId,
    required String documentId,
  }) async {
    if (deleteError != null) {
      throw deleteError!;
    }
    items = items.where((EmployeeDocument item) => item.id != documentId).toList();
  }

  @override
  Future<DownloadedBytes> downloadDocument({
    required String employeeId,
    required String documentId,
  }) async {
    if (downloadError != null) {
      throw downloadError!;
    }
    return const DownloadedBytes(
      bytes: <int>[37, 80, 68, 70],
      filename: 'employment-contract.pdf',
      mimeType: 'application/pdf',
    );
  }
}

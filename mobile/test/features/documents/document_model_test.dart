import 'package:flutter_base/features/documents/data/repositories/document_repository_impl.dart';
import 'package:flutter_base/features/documents/domain/document_access.dart';
import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/domain/entities/document_query.dart';
import 'package:flutter_base/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/document_fakes.dart';
import '../../helpers/employee_fakes.dart';

void main() {
  test('parses document JSON without storing a file URL', () {
    final EmployeeDocument document = EmployeeDocument.fromJson(
      sampleDocumentJson(),
    );
    expect(document.id, 'doc-1');
    expect(document.companyId, 'co-1');
    expect(document.employeeId, 'emp-1');
    expect(document.documentType, DocumentType.contract);
    expect(document.fileName, 'employment-contract.pdf');
    expect(document.fileSize, 245678);
    expect(document.mimeType, 'application/pdf');
    expect(document.uploadedBy?.email, 'admin@example.com');
  });

  test('unknown document types stay usable', () {
    final DocumentType type = DocumentType.fromApi('FUTURE_KIND');
    expect(type.apiValue, 'FUTURE_KIND');
    expect(type.label, isNotEmpty);
    expect(DocumentType.fromApi('CNIC'), DocumentType.cnic);
  });

  test('query parameters match Django filters', () {
    final DocumentQuery query = DocumentQuery(
      search: 'contract',
      documentType: DocumentType.contract,
      uploadedBy: 10,
      dateFrom: DateTime(2026, 8, 1),
      dateTo: DateTime(2026, 8, 31),
      page: 2,
    );
    expect(
      query.toQueryParameters(),
      <String, dynamic>{
        'ordering': '-created_at',
        'page': 2,
        'page_size': 20,
        'search': 'contract',
        'document_type': 'CONTRACT',
        'uploaded_by': 10,
        'date_from': '2026-08-01',
        'date_to': '2026-08-31',
      },
    );
  });

  test('client validation rejects unsafe uploads', () {
    expect(
      validateDocumentFile(name: '../../secret.exe', size: 10),
      isNotNull,
    );
    expect(
      validateDocumentFile(name: 'cnic.pdf', size: kMaxDocumentUploadBytes + 1),
      isNotNull,
    );
    expect(validateDocumentFile(name: 'cnic.pdf', size: 0), isNotNull);
    expect(validateDocumentFile(name: 'cnic.pdf', size: 1200), isNull);
    expect(validateProfileImageFile(name: 'me.png', size: 800), isNull);
    expect(validateProfileImageFile(name: 'me.pdf', size: 800), isNotNull);
  });

  test('repository forwards list, upload, delete, and download', () async {
    final FakeDocumentRemote remote = FakeDocumentRemote();
    final DocumentRepositoryImpl repository = DocumentRepositoryImpl(remote);
    final DocumentPage<EmployeeDocument> page = await repository.listDocuments(
      employeeId: 'emp-1',
      query: const DocumentQuery(search: 'cnic'),
    );
    expect(page.results, isNotEmpty);
    expect(remote.lastEmployeeId, 'emp-1');

    final EmployeeDocument uploaded = await repository.uploadDocument(
      employeeId: 'emp-1',
      documentType: DocumentType.cnic,
      file: const DocumentFile(path: '/tmp/a.pdf', name: 'a.pdf', size: 12),
    );
    expect(uploaded.fileName, 'employment-contract.pdf');
    expect(remote.lastUploadName, 'a.pdf');

    await repository.deleteDocument(employeeId: 'emp-1', documentId: 'doc-1');
    expect(remote.deletedId, 'doc-1');

    final DownloadedBytes bytes = await repository.downloadDocument(
      employeeId: 'emp-1',
      documentId: 'doc-1',
    );
    expect(bytes.filename, 'employment-contract.pdf');
    expect(bytes.bytes, isNotEmpty);
  });

  test('usecases call the repository', () async {
    final FakeDocumentRepository repository = FakeDocumentRepository();
    expect(
      (await ListEmployeeDocuments(repository)(
        employeeId: 'emp-1',
        query: const DocumentQuery(),
      ))
          .results,
      isNotEmpty,
    );
    expect(
      (await GetEmployeeDocument(repository)(
        employeeId: 'emp-1',
        documentId: 'doc-1',
      ))
          .id,
      'doc-1',
    );
  });

  test('RBAC UI gates match backend defaults', () {
    expect(DocumentAccess.of(companyAdminUser).canDelete, isTrue);
    expect(DocumentAccess.of(managerUser).canUpload, isTrue);
    expect(DocumentAccess.of(managerUser).canDelete, isFalse);
    expect(DocumentAccess.of(sampleUser).canUpload, isTrue);
    expect(DocumentAccess.of(sampleUser).canDelete, isFalse);
  });

  test('document routes are nested under the employee', () {
    expect(AppRoutes.employeeDocuments('e1'), '/employees/e1/documents');
    expect(
      AppRoutes.employeeDocument('e1', 'd1'),
      '/employees/e1/documents/d1',
    );
    expect(
      AppRoutes.employeeDocumentPreview('e1', 'd1'),
      '/employees/e1/documents/d1/preview',
    );
    expect(
      AppRoutes.employeeDocumentUpload('e1'),
      '/employees/e1/documents/upload',
    );
  });
}

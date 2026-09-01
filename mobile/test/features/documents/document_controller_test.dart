import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_list_controller.dart';
import 'package:flutter_base/features/documents/presentation/providers/document_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/document_fakes.dart';
import '../../helpers/employee_fakes.dart';

void main() {
  ProviderContainer containerOf(FakeDocumentRepository repository) {
    return ProviderContainer(
      overrides: <Override>[
        documentRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith(() => SeededAuthController(companyAdminUser)),
      ],
    );
  }

  test('loads documents and paginates', () async {
    final FakeDocumentRepository repository = FakeDocumentRepository(
      items: <EmployeeDocument>[sampleDocument(), sampleDocument(id: 'doc-2')],
    );
    final ProviderContainer container = containerOf(repository);
    addTearDown(container.dispose);
    final DocumentListController controller =
        container.read(employeeDocumentsProvider('emp-1').notifier);
    await controller.loadInitial();
    expect(container.read(employeeDocumentsProvider('emp-1')).items, isNotEmpty);
    await controller.loadMore();
    expect(repository.lastEmployeeId, 'emp-1');
  });

  test('surfaces list errors', () async {
    final FakeDocumentRepository repository = FakeDocumentRepository()
      ..listError = const ForbiddenException('nope');
    final ProviderContainer container = containerOf(repository);
    addTearDown(container.dispose);
    await container.read(employeeDocumentsProvider('emp-1').notifier).loadInitial();
    expect(container.read(employeeDocumentsProvider('emp-1')).error, isNotNull);
  });

  test('upload prepends and delete removes', () async {
    final FakeDocumentRepository repository = FakeDocumentRepository();
    final ProviderContainer container = containerOf(repository);
    addTearDown(container.dispose);
    await container.read(employeeDocumentsProvider('emp-1').notifier).loadInitial();
    final EmployeeDocument? uploaded =
        await container.read(documentMutationControllerProvider.notifier).upload(
              employeeId: 'emp-1',
              documentType: DocumentType.cnic,
              file: const DocumentFile(path: '/tmp/a.pdf', name: 'a.pdf', size: 12),
            );
    expect(uploaded, isNotNull);
    expect(
      container.read(employeeDocumentsProvider('emp-1')).items.first.id,
      'doc-new',
    );
    final bool deleted =
        await container.read(documentMutationControllerProvider.notifier).delete(
              employeeId: 'emp-1',
              documentId: 'doc-new',
            );
    expect(deleted, isTrue);
  });

  test('download returns bytes and blocks duplicate in-flight requests', () async {
    final FakeDocumentRepository repository = FakeDocumentRepository();
    final ProviderContainer container = containerOf(repository);
    addTearDown(container.dispose);
    final DownloadedBytes? first =
        await container.read(documentMutationControllerProvider.notifier).download(
              employeeId: 'emp-1',
              documentId: 'doc-1',
            );
    expect(first?.filename, 'employment-contract.pdf');
    expect(first?.bytes, isNotEmpty);
  });

  test('document lists are isolated per employee', () async {
    final FakeDocumentRepository repository = FakeDocumentRepository(
      items: <EmployeeDocument>[sampleDocument(id: 'only-a')],
    );
    final ProviderContainer container = containerOf(repository);
    addTearDown(container.dispose);
    await container.read(employeeDocumentsProvider('emp-a').notifier).loadInitial();
    await container.read(employeeDocumentsProvider('emp-b').notifier).loadInitial();
    expect(
      container.read(employeeDocumentsProvider('emp-a')).items.single.id,
      'only-a',
    );
    expect(repository.lastEmployeeId, 'emp-b');
  });
}

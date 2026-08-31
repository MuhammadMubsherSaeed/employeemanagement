import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_picker.dart';
import 'package:flutter_base/features/leaves/presentation/providers/apply_leave_controller.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/leave_fakes.dart';

ProviderContainer _container({
  required FakeLeaveRepository repository,
  LeaveAttachmentPicker? picker,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(sampleUser)),
      leaveRepositoryProvider.overrideWithValue(repository),
      if (picker != null)
        leaveAttachmentPickerProvider.overrideWithValue(picker),
    ],
  );
}

void main() {
  test('requires type, dates, and reason', () async {
    final ProviderContainer container = _container(
      repository: FakeLeaveRepository(),
    );
    addTearDown(container.dispose);
    final ApplyLeaveController controller =
        container.read(applyLeaveControllerProvider.notifier);

    expect(await controller.submit(), isNull);
    expect(
      container.read(applyLeaveControllerProvider).fieldErrors['leave_type'],
      isNotEmpty,
    );

    controller.setLeaveType('type-1');
    controller.setRange(start: DateTime(2026, 8, 18), end: DateTime(2026, 8, 15));
    controller.setReason('Family event');
    expect(await controller.submit(), isNull);
    expect(
      container.read(applyLeaveControllerProvider).fieldErrors['end_date'],
      contains('before start date'),
    );
  });

  test('successful request clears form, uploads attachment, and refreshes lists',
      () async {
    final FakeLeaveRepository repository = FakeLeaveRepository();
    final FakeLeaveAttachmentPicker picker = FakeLeaveAttachmentPicker(
      file: const LeaveAttachmentFile(
        path: '/tmp/note.pdf',
        name: 'note.pdf',
        size: 1024,
      ),
    );
    final ProviderContainer container = _container(
      repository: repository,
      picker: picker,
    );
    addTearDown(container.dispose);
    final ApplyLeaveController controller =
        container.read(applyLeaveControllerProvider.notifier);

    controller.setLeaveType('type-1');
    controller.setRange(start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 18));
    controller.setReason('Family event');
    expect(await controller.pickAttachment(), isNull);
    expect(container.read(applyLeaveControllerProvider).attachment, isNotNull);

    final LeaveRequest? created = await controller.submit();
    expect(created, isNotNull);
    expect(repository.createCalls, 1);
    expect(repository.lastCreate?.attachment?.name, 'note.pdf');
    expect(container.read(applyLeaveControllerProvider).isSubmitting, isFalse);
    expect(container.read(applyLeaveControllerProvider).leaveTypeId, isNull);
    expect(container.read(applyLeaveControllerProvider).attachment, isNull);
    expect(repository.listCalls, greaterThan(0));
  });

  test('duplicate submission is ignored while a request is in flight', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..delay = const Duration(milliseconds: 40);
    final ProviderContainer container = _container(repository: repository);
    addTearDown(container.dispose);
    final ApplyLeaveController controller =
        container.read(applyLeaveControllerProvider.notifier);
    controller.setLeaveType('type-1');
    controller.setRange(start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 18));
    controller.setReason('Family event');

    final Future<LeaveRequest?> first = controller.submit();
    final Future<LeaveRequest?> second = controller.submit();
    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(repository.createCalls, 1);
  });

  test('maps backend validation errors onto fields', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..createError = const ValidationException(
        'Insufficient leave balance.',
        fieldErrors: <String, List<String>>{
          'start_date': <String>['Insufficient leave balance.'],
        },
      );
    final ProviderContainer container = _container(repository: repository);
    addTearDown(container.dispose);
    final ApplyLeaveController controller =
        container.read(applyLeaveControllerProvider.notifier);
    controller.setLeaveType('type-1');
    controller.setRange(start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 18));
    controller.setReason('Family event');

    expect(await controller.submit(), isNull);
    expect(
      container.read(applyLeaveControllerProvider).error,
      'Insufficient leave balance.',
    );
    expect(
      container.read(applyLeaveControllerProvider).fieldErrors['start_date'],
      'Insufficient leave balance.',
    );
  });

  test('rejects oversized or blocked attachments', () async {
    final FakeLeaveAttachmentPicker picker = FakeLeaveAttachmentPicker(
      file: const LeaveAttachmentFile(
        path: '/tmp/virus.exe',
        name: 'virus.exe',
        size: 10,
      ),
    );
    final ProviderContainer container = _container(
      repository: FakeLeaveRepository(),
      picker: picker,
    );
    addTearDown(container.dispose);
    final String? error = await container
        .read(applyLeaveControllerProvider.notifier)
        .pickAttachment();
    expect(error, contains('PDF, image, or Word'));
    expect(container.read(applyLeaveControllerProvider).attachment, isNull);
  });
}

import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_action_controller.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';
import '../../helpers/leave_fakes.dart';

ProviderContainer _container(FakeLeaveRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        () => SeededAuthController(managerUser),
      ),
      leaveRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void main() {
  test('approve succeeds, blocks double-tap, and refreshes lists', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final LeaveActionController controller =
        container.read(leaveActionControllerProvider.notifier);

    final Future<LeaveRequest?> first = controller.approve('req-1');
    final Future<LeaveRequest?> second = controller.approve('req-1');
    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(repository.approveCalls, 1);
    expect((await first)!.status, LeaveRequestStatus.approved);
    expect(repository.listCalls, greaterThan(0));
  });

  test('cannot approve and reject at the same time', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final LeaveActionController controller =
        container.read(leaveActionControllerProvider.notifier);

    final Future<LeaveRequest?> approve = controller.approve('req-1');
    final Future<LeaveRequest?> reject = controller.reject(
      id: 'req-1',
      rejectionReason: 'Coverage needed',
    );
    expect(await reject, isNull);
    expect(await approve, isNotNull);
    expect(repository.rejectCalls, 0);
    expect(repository.approveCalls, 1);
  });

  test('reject requires a meaningful reason and surfaces backend errors',
      () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..rejectError = const ForbiddenException();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final LeaveActionController controller =
        container.read(leaveActionControllerProvider.notifier);

    expect(
      await controller.reject(id: 'req-1', rejectionReason: '  '),
      isNull,
    );
    expect(repository.rejectCalls, 0);

    expect(
      await controller.reject(id: 'req-1', rejectionReason: 'No'),
      isNull,
    );
    expect(repository.rejectCalls, 0);

    expect(
      await controller.reject(id: 'req-1', rejectionReason: 'Coverage needed'),
      isNull,
    );
    expect(repository.rejectCalls, 1);
    expect(
      container.read(leaveActionControllerProvider).error,
      contains('do not have access'),
    );
  });

  test('cancel succeeds and duplicate taps are ignored', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..delay = const Duration(milliseconds: 20);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final LeaveActionController controller =
        container.read(leaveActionControllerProvider.notifier);

    final Future<LeaveRequest?> first = controller.cancel('req-1');
    final Future<LeaveRequest?> second = controller.cancel('req-1');
    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(repository.cancelCalls, 1);
    expect((await first)!.status, LeaveRequestStatus.cancelled);
  });

  test('allocate only sends allocated days', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    final LeaveBalance? updated = await container
        .read(leaveActionControllerProvider.notifier)
        .allocate(id: 'bal-1', allocatedDays: 20);
    expect(updated, isNotNull);
    expect(repository.lastAllocatedDays, 20);
  });
}

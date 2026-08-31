import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_action_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/device_fakes.dart';
import '../../helpers/employee_fakes.dart';

ProviderContainer _container(FakeDeviceRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        () => SeededAuthController(managerUser),
      ),
      deviceRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void main() {
  test('assign succeeds, blocks double-tap, and refreshes lists', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceActionController controller =
        container.read(deviceActionControllerProvider.notifier);
    const AssignDeviceBody body = AssignDeviceBody(employeeId: 'emp-1');

    final Future<Device?> first = controller.assign(id: 'dev-1', body: body);
    final Future<Device?> second = controller.assign(id: 'dev-1', body: body);
    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(repository.assignCalls, 1);
    expect((await first)!.status.name, 'assigned');
    expect(repository.listCalls, greaterThan(0));
    expect(repository.historyCalls, greaterThan(0));
  });

  test('cannot assign and return at the same time', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceActionController controller =
        container.read(deviceActionControllerProvider.notifier);

    final Future<Device?> assign = controller.assign(
      id: 'dev-1',
      body: const AssignDeviceBody(employeeId: 'emp-1'),
    );
    final Future<Device?> returning = controller.returnDevice(id: 'dev-1');
    expect(await returning, isNull);
    expect(await assign, isNotNull);
    expect(repository.returnCalls, 0);
    expect(repository.assignCalls, 1);
  });

  test('assign requires an employee and surfaces backend errors', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..assignError = const ValidationException(
        'This device is already assigned.',
        fieldErrors: <String, List<String>>{
          'non_field_errors': <String>['This device is already assigned.'],
        },
      );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceActionController controller =
        container.read(deviceActionControllerProvider.notifier);

    expect(
      await controller.assign(
        id: 'dev-1',
        body: const AssignDeviceBody(employeeId: '  '),
      ),
      isNull,
    );
    expect(repository.assignCalls, 0);

    expect(
      await controller.assign(
        id: 'dev-1',
        body: const AssignDeviceBody(employeeId: 'emp-1'),
      ),
      isNull,
    );
    expect(repository.assignCalls, 1);
    expect(
      container.read(deviceActionControllerProvider).error,
      'This device is already assigned.',
    );
  });

  test('permission errors use a safe message', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..assignError = const ForbiddenException();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container.read(deviceActionControllerProvider.notifier).assign(
            id: 'dev-1',
            body: const AssignDeviceBody(employeeId: 'emp-1'),
          ),
      isNull,
    );
    expect(
      container.read(deviceActionControllerProvider).error,
      contains('do not have access'),
    );
  });

  test('return succeeds and duplicate taps are ignored', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..delay = const Duration(milliseconds: 20);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceActionController controller =
        container.read(deviceActionControllerProvider.notifier);
    const ReturnDeviceBody body = ReturnDeviceBody(
      conditionOnReturn: 'Good',
      notes: 'Dock returned',
    );

    final Future<Device?> first = controller.returnDevice(id: 'dev-1', body: body);
    final Future<Device?> second = controller.returnDevice(id: 'dev-1', body: body);
    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(repository.returnCalls, 1);
    expect(repository.lastReturn?.conditionOnReturn, 'Good');
    expect((await first)!.status.name, 'available');
  });

  test('delete succeeds, refreshes inventory, and blocks duplicates', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..delay = const Duration(milliseconds: 20);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceActionController controller =
        container.read(deviceActionControllerProvider.notifier);

    final Future<bool> first = controller.delete('dev-1');
    final Future<bool> second = controller.delete('dev-1');
    expect(await second, isFalse);
    expect(await first, isTrue);
    expect(repository.deleteCalls, 1);
    expect(repository.listCalls, greaterThan(0));
  });

  test('delete surfaces backend history conflicts', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..deleteError = const ValidationException(
        'Devices with assignment history must be retired instead of deleted.',
      );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container.read(deviceActionControllerProvider.notifier).delete('dev-1'),
      isFalse,
    );
    expect(
      container.read(deviceActionControllerProvider).error,
      contains('retired'),
    );
  });
}

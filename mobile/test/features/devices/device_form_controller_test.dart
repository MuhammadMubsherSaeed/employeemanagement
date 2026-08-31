import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_form_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/device_fakes.dart';
import '../../helpers/employee_fakes.dart';

ProviderContainer _container(FakeDeviceRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        () => SeededAuthController(companyAdminUser),
      ),
      deviceRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void main() {
  test('requires asset code, type, and rejects negative cost', () async {
    final ProviderContainer container = _container(FakeDeviceRepository());
    addTearDown(container.dispose);
    final DeviceFormController controller =
        container.read(deviceFormControllerProvider.notifier);

    expect(
      await controller.create(const DeviceWrite(assetCode: '', type: '')),
      isNull,
    );
    expect(
      container.read(deviceFormControllerProvider).fieldErrors['asset_code'],
      isNotEmpty,
    );
    expect(
      container.read(deviceFormControllerProvider).fieldErrors['type'],
      isNotEmpty,
    );

    expect(
      await controller.create(
        const DeviceWrite(assetCode: 'LAP-1', type: 'Laptop', cost: '-1'),
      ),
      isNull,
    );
    expect(
      container.read(deviceFormControllerProvider).fieldErrors['cost'],
      contains('negative'),
    );
  });

  test('rejects warranty before purchase and assigned status updates', () async {
    final ProviderContainer container = _container(FakeDeviceRepository());
    addTearDown(container.dispose);
    final DeviceFormController controller =
        container.read(deviceFormControllerProvider.notifier);

    expect(
      await controller.update(
        'dev-1',
        DeviceWrite(
          assetCode: 'LAP-001',
          type: 'Laptop',
          purchaseDate: DateTime(2026, 2, 1),
          warrantyExpiry: DateTime(2026, 1, 1),
        ),
      ),
      isNull,
    );
    expect(
      container.read(deviceFormControllerProvider).fieldErrors['warranty_expiry'],
      isNotEmpty,
    );

    expect(
      await controller.update(
        'dev-1',
        const DeviceWrite(
          assetCode: 'LAP-001',
          type: 'Laptop',
          status: DeviceStatus.assigned,
        ),
      ),
      isNull,
    );
    expect(
      container.read(deviceFormControllerProvider).fieldErrors['status'],
      contains('Assign'),
    );
  });

  test('create succeeds, blocks double submit, and refreshes inventory',
      () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..delay = const Duration(milliseconds: 40);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final DeviceFormController controller =
        container.read(deviceFormControllerProvider.notifier);
    const DeviceWrite body = DeviceWrite(
      assetCode: 'LAP-009',
      type: 'Laptop',
    );

    final Future<Device?> first = controller.create(body);
    final Future<Device?> second = controller.create(body);
    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(repository.createCalls, 1);
    expect(repository.listCalls, greaterThan(0));
    expect(container.read(deviceFormControllerProvider).isSubmitting, isFalse);
  });

  test('update maps backend field errors and refreshes detail', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository()
      ..updateError = const ValidationException(
        'A device with this asset code already exists in this company.',
        fieldErrors: <String, List<String>>{
          'asset_code': <String>[
            'A device with this asset code already exists in this company.',
          ],
        },
      );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container.read(deviceFormControllerProvider.notifier).update(
            'dev-1',
            const DeviceWrite(assetCode: 'LAP-001', type: 'Laptop'),
          ),
      isNull,
    );
    expect(
      container.read(deviceFormControllerProvider).fieldErrors['asset_code'],
      contains('already exists'),
    );
  });
}

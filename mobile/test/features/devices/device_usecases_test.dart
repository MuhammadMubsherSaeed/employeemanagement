import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/domain/usecases/device_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/device_fakes.dart';

void main() {
  test('use cases delegate to the repository', () async {
    final FakeDeviceRepository repository = FakeDeviceRepository();

    expect(
      (await GetDevices(repository)(const DeviceQuery())).count,
      1,
    );
    expect((await GetDeviceDetail(repository)('dev-1')).id, 'dev-1');
    expect(
      (await CreateDevice(repository)(
        const DeviceWrite(assetCode: 'LAP-009', type: 'Laptop'),
      )).id,
      'dev-new',
    );
    expect(
      (await UpdateDevice(repository)(
        'dev-1',
        const DeviceWrite(assetCode: 'LAP-001', type: 'Laptop'),
      )).id,
      'dev-1',
    );
    await DeleteDevice(repository)('dev-1');
    expect(repository.deleteCalls, 1);
    expect(
      (await AssignDevice(repository)(
        'dev-1',
        const AssignDeviceBody(employeeId: 'emp-1'),
      )).id,
      'dev-1',
    );
    expect(
      (await ReturnDevice(repository)(
        'dev-1',
        const ReturnDeviceBody(),
      )).status.name,
      'available',
    );
    expect(
      (await GetDeviceHistory(repository)('dev-1')).results,
      isNotEmpty,
    );
  });
}

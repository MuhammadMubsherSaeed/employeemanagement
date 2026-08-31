import 'package:flutter_base/features/devices/data/repositories/device_repository_impl.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/device_fakes.dart';

void main() {
  test('repository forwards list, detail, writes, and actions', () async {
    final FakeDeviceRemote remote = FakeDeviceRemote();
    final DeviceRepositoryImpl repository = DeviceRepositoryImpl(remote);
    const DeviceQuery query = DeviceQuery(page: 1, search: 'LAP');

    expect((await repository.getDevices(query)).results, isNotEmpty);
    expect(remote.lastQuery, query);
    expect((await repository.getDeviceDetail('dev-9')).id, 'dev-9');

    final Device created = await repository.createDevice(
      const DeviceWrite(assetCode: 'LAP-009', type: 'Laptop'),
    );
    expect(created.id, 'dev-new');
    expect(remote.lastCreate?.assetCode, 'LAP-009');

    expect(
      (await repository.updateDevice(
        'dev-1',
        const DeviceWrite(assetCode: 'LAP-001', type: 'Laptop'),
      )).id,
      'dev-1',
    );
    await repository.deleteDevice('dev-1');
    expect(remote.lastId, 'dev-1');

    expect(
      (await repository.assignDevice(
        'dev-1',
        const AssignDeviceBody(employeeId: 'emp-1'),
      )).status.name,
      'assigned',
    );
    expect(
      (await repository.returnDevice(
        'dev-1',
        const ReturnDeviceBody(notes: 'ok'),
      )).status.name,
      'available',
    );
    expect(
      (await repository.getDeviceHistory('dev-1', const DeviceHistoryQuery()))
          .results,
      isNotEmpty,
    );
  });
}

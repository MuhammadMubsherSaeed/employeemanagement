import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/device_fakes.dart';

void main() {
  test('parses list JSON without inventing missing sensitive fields', () {
    final Device device = Device.fromJson(sampleDeviceJson());
    expect(device.id, 'dev-1');
    expect(device.assetCode, 'LAP-001');
    expect(device.serialNumber, 'SN-001');
    expect(device.status, DeviceStatus.available);
    expect(device.hasCost, isFalse);
    expect(device.hasNotes, isFalse);
    expect(device.updatedAt, isNull);
  });

  test('parses detail JSON including optional cost and notes when present', () {
    final Device device = Device.fromJson(
      sampleDeviceJson(detail: true, sensitive: true),
    );
    expect(device.cost, '1299.00');
    expect(device.notes, 'Dock included');
    expect(device.updatedAt, isNotNull);
    expect(device.hasCost, isTrue);
    expect(device.hasNotes, isTrue);
  });

  test('maps known statuses and keeps unknown values safe', () {
    expect(DeviceStatus.fromApi('AVAILABLE'), DeviceStatus.available);
    expect(DeviceStatus.fromApi('assigned'), DeviceStatus.assigned);
    expect(DeviceStatus.fromApi('FUTURE_STATUS'), DeviceStatus.unknown);
    expect(DeviceStatus.fromApi(null), DeviceStatus.unknown);
    expect(DeviceStatus.available.canAssign, isTrue);
    expect(DeviceStatus.assigned.canReturn, isTrue);
    expect(
      DeviceStatus.available.allowedUpdateStatuses,
      isNot(contains(DeviceStatus.assigned)),
    );
    expect(
      DeviceStatus.assigned.allowedUpdateStatuses,
      isNot(contains(DeviceStatus.available)),
    );
    expect(DeviceStatus.retired.allowedUpdateStatuses, isEmpty);
    expect(DeviceStatus.lost.allowedUpdateStatuses, isEmpty);
  });

  test('query parameters match the Django device filter contract', () {
    const DeviceQuery query = DeviceQuery(
      search: '  LAP  ',
      status: DeviceStatus.assigned,
      type: 'Laptop',
      manufacturer: 'Lenovo',
      assigned: true,
      employeeId: 'emp-9',
      page: 2,
    );
    expect(
      query.toQueryParameters(),
      <String, dynamic>{
        'search': 'LAP',
        'status': 'ASSIGNED',
        'type': 'Laptop',
        'manufacturer': 'Lenovo',
        'assigned': true,
        'employee': 'emp-9',
        'ordering': 'asset_code',
        'page': 2,
        'page_size': 20,
      },
    );
    expect(
      const DeviceQuery(status: DeviceStatus.unknown).toQueryParameters(),
      <String, dynamic>{
        'ordering': 'asset_code',
        'page': 1,
        'page_size': 20,
      },
    );
  });

  test('create payload omits company, status, and empty optional fields', () {
    const DeviceWrite body = DeviceWrite(
      assetCode: ' lap-002 ',
      type: ' Laptop ',
      manufacturer: ' Apple ',
      model: ' M3 ',
      notes: '  ',
    );
    expect(
      body.toJson(),
      <String, dynamic>{
        'asset_code': 'LAP-002',
        'type': 'Laptop',
        'manufacturer': 'Apple',
        'model': 'M3',
        'notes': '',
      },
    );
    expect(body.toJson().containsKey('company_id'), isFalse);
    expect(body.toJson().containsKey('status'), isFalse);
    expect(
      const DeviceWrite(
        assetCode: 'X',
        type: 'Y',
        status: DeviceStatus.assigned,
      ).toJson(includeStatus: true).containsKey('status'),
      isFalse,
    );
  });

  test('assign and return payloads match the Django action serializers', () {
    expect(
      const AssignDeviceBody(
        employeeId: 'emp-1',
        conditionOnAssignment: ' Good ',
        notes: '  ',
      ).toJson(),
      <String, dynamic>{
        'employee_id': 'emp-1',
        'condition_on_assignment': 'Good',
      },
    );
    expect(
      const ReturnDeviceBody(conditionOnReturn: 'Worn', notes: 'Scratched')
          .toJson(),
      <String, dynamic>{
        'condition_on_return': 'Worn',
        'notes': 'Scratched',
      },
    );
    expect(formatDeviceDateParam(DateTime(2026, 8, 3)), '2026-08-03');
  });

  test('parses history rows and treats a null returned_at as active', () {
    final DeviceHistoryItem active =
        DeviceHistoryItem.fromJson(sampleHistoryJson());
    expect(active.isActive, isTrue);
    expect(active.employee?.fullName, 'Ada Lovelace');
    expect(active.conditionOnReturn, isEmpty);

    final DeviceHistoryItem closed =
        DeviceHistoryItem.fromJson(sampleHistoryJson(active: false));
    expect(closed.isActive, isFalse);
    expect(closed.conditionOnReturn, 'Scratched');
  });
}

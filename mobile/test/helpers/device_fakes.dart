import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/domain/repositories/device_repository.dart';

Device sampleDevice({
  String id = 'dev-1',
  String assetCode = 'LAP-001',
  String type = 'Laptop',
  String manufacturer = 'Lenovo',
  String model = 'ThinkPad T14',
  String? serialNumber = 'SN-001',
  DeviceStatus status = DeviceStatus.available,
  String? cost,
  String? notes,
  DateTime? purchaseDate,
  DateTime? warrantyExpiry,
}) {
  return Device(
    id: id,
    assetCode: assetCode,
    type: type,
    manufacturer: manufacturer,
    model: model,
    serialNumber: serialNumber,
    purchaseDate: purchaseDate ?? DateTime(2026, 1, 15),
    warrantyExpiry: warrantyExpiry ?? DateTime(2028, 1, 15),
    cost: cost,
    status: status,
    notes: notes,
    createdAt: DateTime.parse('2026-01-20T08:00:00Z'),
    updatedAt: DateTime.parse('2026-01-20T08:00:00Z'),
  );
}

DeviceEmployeeRef sampleDeviceEmployee({
  String id = 'emp-1',
  String code = 'EMP-001',
  String firstName = 'Ada',
  String lastName = 'Lovelace',
}) {
  return DeviceEmployeeRef(
    id: id,
    employeeCode: code,
    firstName: firstName,
    lastName: lastName,
  );
}

DeviceHistoryItem sampleHistoryItem({
  String id = 'hist-1',
  DateTime? assignedAt,
  DateTime? returnedAt,
  DeviceEmployeeRef? employee,
  String conditionOnAssignment = 'Good',
  String conditionOnReturn = '',
  String notes = '',
}) {
  return DeviceHistoryItem(
    id: id,
    employee: employee ?? sampleDeviceEmployee(),
    assignedAt: assignedAt ?? DateTime.parse('2026-02-01T09:00:00Z'),
    returnedAt: returnedAt,
    conditionOnAssignment: conditionOnAssignment,
    conditionOnReturn: conditionOnReturn,
    notes: notes,
    createdAt: DateTime.parse('2026-02-01T09:00:00Z'),
  );
}

Map<String, dynamic> sampleDeviceJson({
  String id = 'dev-1',
  String assetCode = 'LAP-001',
  String status = 'AVAILABLE',
  bool detail = false,
  bool sensitive = false,
  String? cost = '1299.00',
  String? notes = 'Dock included',
}) {
  final Map<String, dynamic> json = <String, dynamic>{
    'id': id,
    'asset_code': assetCode,
    'type': 'Laptop',
    'manufacturer': 'Lenovo',
    'model': 'ThinkPad T14',
    'serial_number': 'SN-001',
    'status': status,
    'purchase_date': '2026-01-15',
    'warranty_expiry': '2028-01-15',
    'created_at': '2026-01-20T08:00:00Z',
  };
  if (detail) {
    json['updated_at'] = '2026-01-21T08:00:00Z';
  }
  if (sensitive) {
    json['cost'] = cost;
    json['notes'] = notes;
  }
  return json;
}

Map<String, dynamic> sampleHistoryJson({
  String id = 'hist-1',
  bool active = true,
}) {
  return <String, dynamic>{
    'id': id,
    'employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
    },
    'assigned_at': '2026-02-01T09:00:00Z',
    'returned_at': active ? null : '2026-03-01T09:00:00Z',
    'condition_on_assignment': 'Good',
    'condition_on_return': active ? '' : 'Scratched',
    'notes': 'Team laptop',
    'created_at': '2026-02-01T09:00:00Z',
  };
}

class SwitchingAuthController extends AuthController {
  SwitchingAuthController(this.user);

  User user;

  @override
  AuthState build() => AuthState.authenticated(user);

  void switchTo(User next) {
    user = next;
    state = AuthState.authenticated(next);
  }
}

class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository({
    List<Device>? devices,
    List<DeviceHistoryItem>? history,
  })  : devices = devices ?? <Device>[sampleDevice()],
        history = history ?? <DeviceHistoryItem>[sampleHistoryItem()];

  List<Device> devices;
  List<DeviceHistoryItem> history;
  Duration delay = Duration.zero;
  Object? listError;
  Object? detailError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Object? assignError;
  Object? returnError;
  Object? historyError;
  DeviceWrite? lastCreate;
  DeviceWrite? lastUpdate;
  AssignDeviceBody? lastAssign;
  ReturnDeviceBody? lastReturn;
  String? lastId;
  int listCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int assignCalls = 0;
  int returnCalls = 0;
  int historyCalls = 0;
  final List<DeviceQuery> listQueries = <DeviceQuery>[];
  final List<DeviceHistoryQuery> historyQueries = <DeviceHistoryQuery>[];
  DevicePage<Device> Function(DeviceQuery query)? pageBuilder;
  DevicePage<DeviceHistoryItem> Function(DeviceHistoryQuery query)?
      historyPageBuilder;

  Future<void> _wait() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  @override
  Future<DevicePage<Device>> getDevices(DeviceQuery query) async {
    listCalls += 1;
    listQueries.add(query);
    await _wait();
    if (listError != null) {
      throw listError!;
    }
    if (pageBuilder != null) {
      return pageBuilder!(query);
    }
    return DevicePage<Device>(results: devices, count: devices.length);
  }

  @override
  Future<Device> getDeviceDetail(String id) async {
    await _wait();
    if (detailError != null) {
      throw detailError!;
    }
    lastId = id;
    return devices.firstWhere(
      (Device item) => item.id == id,
      orElse: () => devices.isEmpty ? sampleDevice(id: id) : devices.first,
    );
  }

  @override
  Future<Device> createDevice(DeviceWrite body) async {
    createCalls += 1;
    lastCreate = body;
    await _wait();
    if (createError != null) {
      throw createError!;
    }
    return sampleDevice(id: 'dev-new', assetCode: body.assetCode, type: body.type);
  }

  @override
  Future<Device> updateDevice(String id, DeviceWrite body) async {
    updateCalls += 1;
    lastId = id;
    lastUpdate = body;
    await _wait();
    if (updateError != null) {
      throw updateError!;
    }
    return sampleDevice(
      id: id,
      assetCode: body.assetCode,
      type: body.type,
      status: body.status ?? DeviceStatus.available,
    );
  }

  @override
  Future<void> deleteDevice(String id) async {
    deleteCalls += 1;
    lastId = id;
    await _wait();
    if (deleteError != null) {
      throw deleteError!;
    }
  }

  @override
  Future<Device> assignDevice(String id, AssignDeviceBody body) async {
    assignCalls += 1;
    lastId = id;
    lastAssign = body;
    await _wait();
    if (assignError != null) {
      throw assignError!;
    }
    return sampleDevice(id: id, status: DeviceStatus.assigned);
  }

  @override
  Future<Device> returnDevice(String id, ReturnDeviceBody body) async {
    returnCalls += 1;
    lastId = id;
    lastReturn = body;
    await _wait();
    if (returnError != null) {
      throw returnError!;
    }
    return sampleDevice(id: id, status: DeviceStatus.available);
  }

  @override
  Future<DevicePage<DeviceHistoryItem>> getDeviceHistory(
    String id,
    DeviceHistoryQuery query,
  ) async {
    historyCalls += 1;
    lastId = id;
    historyQueries.add(query);
    await _wait();
    if (historyError != null) {
      throw historyError!;
    }
    if (historyPageBuilder != null) {
      return historyPageBuilder!(query);
    }
    return DevicePage<DeviceHistoryItem>(
      results: history,
      count: history.length,
    );
  }
}

class FakeDeviceRemote implements DeviceRemoteDataSource {
  FakeDeviceRemote({
    DevicePage<Device>? devices,
    DevicePage<DeviceHistoryItem>? history,
    this.detail,
  })  : devices = devices ??
            DevicePage<Device>(
              results: <Device>[sampleDevice()],
              count: 1,
            ),
        history = history ??
            DevicePage<DeviceHistoryItem>(
              results: <DeviceHistoryItem>[sampleHistoryItem()],
              count: 1,
            );

  DevicePage<Device> devices;
  DevicePage<DeviceHistoryItem> history;
  Device? detail;
  DeviceQuery? lastQuery;
  DeviceWrite? lastCreate;
  DeviceWrite? lastUpdate;
  AssignDeviceBody? lastAssign;
  ReturnDeviceBody? lastReturn;
  String? lastId;

  @override
  Future<DevicePage<Device>> getDevices(DeviceQuery query) async {
    lastQuery = query;
    return devices;
  }

  @override
  Future<Device> getDevice(String id) async {
    lastId = id;
    return detail ?? sampleDevice(id: id);
  }

  @override
  Future<Device> createDevice(DeviceWrite body) async {
    lastCreate = body;
    return sampleDevice(id: 'dev-new', assetCode: body.assetCode);
  }

  @override
  Future<Device> updateDevice(String id, DeviceWrite body) async {
    lastId = id;
    lastUpdate = body;
    return sampleDevice(id: id, assetCode: body.assetCode);
  }

  @override
  Future<void> deleteDevice(String id) async {
    lastId = id;
  }

  @override
  Future<Device> assignDevice(String id, AssignDeviceBody body) async {
    lastId = id;
    lastAssign = body;
    return sampleDevice(id: id, status: DeviceStatus.assigned);
  }

  @override
  Future<Device> returnDevice(String id, ReturnDeviceBody body) async {
    lastId = id;
    lastReturn = body;
    return sampleDevice(id: id, status: DeviceStatus.available);
  }

  @override
  Future<DevicePage<DeviceHistoryItem>> getDeviceHistory(
    String id,
    DeviceHistoryQuery query,
  ) async {
    lastId = id;
    return history;
  }
}

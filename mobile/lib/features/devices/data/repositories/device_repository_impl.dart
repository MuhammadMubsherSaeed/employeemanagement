import 'package:flutter_base/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._remote);

  final DeviceRemoteDataSource _remote;

  @override
  Future<DevicePage<Device>> getDevices(DeviceQuery query) {
    return _remote.getDevices(query);
  }

  @override
  Future<Device> getDeviceDetail(String id) {
    return _remote.getDevice(id);
  }

  @override
  Future<Device> createDevice(DeviceWrite body) {
    return _remote.createDevice(body);
  }

  @override
  Future<Device> updateDevice(String id, DeviceWrite body) {
    return _remote.updateDevice(id, body);
  }

  @override
  Future<void> deleteDevice(String id) {
    return _remote.deleteDevice(id);
  }

  @override
  Future<Device> assignDevice(String id, AssignDeviceBody body) {
    return _remote.assignDevice(id, body);
  }

  @override
  Future<Device> returnDevice(String id, ReturnDeviceBody body) {
    return _remote.returnDevice(id, body);
  }

  @override
  Future<DevicePage<DeviceHistoryItem>> getDeviceHistory(
    String id,
    DeviceHistoryQuery query,
  ) {
    return _remote.getDeviceHistory(id, query);
  }
}

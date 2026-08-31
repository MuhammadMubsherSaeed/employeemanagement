import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/domain/repositories/device_repository.dart';

class GetDevices {
  const GetDevices(this._repository);

  final DeviceRepository _repository;

  Future<DevicePage<Device>> call(DeviceQuery query) {
    return _repository.getDevices(query);
  }
}

class GetDeviceDetail {
  const GetDeviceDetail(this._repository);

  final DeviceRepository _repository;

  Future<Device> call(String id) {
    return _repository.getDeviceDetail(id);
  }
}

class CreateDevice {
  const CreateDevice(this._repository);

  final DeviceRepository _repository;

  Future<Device> call(DeviceWrite body) {
    return _repository.createDevice(body);
  }
}

class UpdateDevice {
  const UpdateDevice(this._repository);

  final DeviceRepository _repository;

  Future<Device> call(String id, DeviceWrite body) {
    return _repository.updateDevice(id, body);
  }
}

class DeleteDevice {
  const DeleteDevice(this._repository);

  final DeviceRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteDevice(id);
  }
}

class AssignDevice {
  const AssignDevice(this._repository);

  final DeviceRepository _repository;

  Future<Device> call(String id, AssignDeviceBody body) {
    return _repository.assignDevice(id, body);
  }
}

class ReturnDevice {
  const ReturnDevice(this._repository);

  final DeviceRepository _repository;

  Future<Device> call(String id, ReturnDeviceBody body) {
    return _repository.returnDevice(id, body);
  }
}

class GetDeviceHistory {
  const GetDeviceHistory(this._repository);

  final DeviceRepository _repository;

  Future<DevicePage<DeviceHistoryItem>> call(
    String id, [
    DeviceHistoryQuery query = const DeviceHistoryQuery(),
  ]) {
    return _repository.getDeviceHistory(id, query);
  }
}

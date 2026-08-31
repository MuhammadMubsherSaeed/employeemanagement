import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';

abstract class DeviceRepository {
  Future<DevicePage<Device>> getDevices(DeviceQuery query);

  Future<Device> getDeviceDetail(String id);

  Future<Device> createDevice(DeviceWrite body);

  Future<Device> updateDevice(String id, DeviceWrite body);

  Future<void> deleteDevice(String id);

  Future<Device> assignDevice(String id, AssignDeviceBody body);

  Future<Device> returnDevice(String id, ReturnDeviceBody body);

  Future<DevicePage<DeviceHistoryItem>> getDeviceHistory(
    String id,
    DeviceHistoryQuery query,
  );
}

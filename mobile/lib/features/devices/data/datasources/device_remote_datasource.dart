import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/devices/data/device_endpoints.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';

abstract class DeviceRemoteDataSource {
  Future<DevicePage<Device>> getDevices(DeviceQuery query);

  Future<Device> getDevice(String id);

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

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  DeviceRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<DevicePage<Device>> getDevices(DeviceQuery query) async {
    final response = await _client.get<dynamic>(
      DeviceEndpoints.devices,
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, Device.fromJson);
  }

  @override
  Future<Device> getDevice(String id) async {
    final response = await _client.get<dynamic>(DeviceEndpoints.device(id));
    return Device.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<Device> createDevice(DeviceWrite body) async {
    final response = await _client.post<dynamic>(
      DeviceEndpoints.devices,
      data: body.toJson(),
    );
    return Device.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<Device> updateDevice(String id, DeviceWrite body) async {
    final response = await _client.patch<dynamic>(
      DeviceEndpoints.device(id),
      data: body.toJson(includeStatus: true),
    );
    return Device.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<void> deleteDevice(String id) async {
    await _client.delete<dynamic>(DeviceEndpoints.device(id));
  }

  @override
  Future<Device> assignDevice(String id, AssignDeviceBody body) async {
    final response = await _client.post<dynamic>(
      DeviceEndpoints.assign(id),
      data: body.toJson(),
    );
    return Device.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<Device> returnDevice(String id, ReturnDeviceBody body) async {
    final response = await _client.post<dynamic>(
      DeviceEndpoints.returnDevice(id),
      data: body.toJson(),
    );
    return Device.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<DevicePage<DeviceHistoryItem>> getDeviceHistory(
    String id,
    DeviceHistoryQuery query,
  ) async {
    final response = await _client.get<dynamic>(
      DeviceEndpoints.history(id),
      queryParameters: query.toQueryParameters(),
    );
    return _page(response.data, DeviceHistoryItem.fromJson);
  }

  DevicePage<T> _page<T>(
    dynamic raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final Map<String, dynamic> data = _data(_envelope(raw));
    final Object? results = data['results'];
    final List<T> items = <T>[];
    if (results is List) {
      for (final Object? row in results) {
        if (row is Map) {
          items.add(parse(Map<String, dynamic>.from(row)));
        }
      }
    }
    return DevicePage<T>(
      results: items,
      count: _readInt(data['count'], fallback: items.length),
      next: data['next']?.toString(),
      previous: data['previous']?.toString(),
    );
  }

  Map<String, dynamic> _data(ApiEnvelope envelope) {
    try {
      return envelope.requireDataMap();
    } on FormatException {
      throw const UnknownException();
    }
  }

  ApiEnvelope _envelope(dynamic data) {
    try {
      final ApiEnvelope envelope = ApiEnvelope.parse(data);
      if (!envelope.success && envelope.data == null) {
        throw UnknownException(envelope.message ?? 'Request failed.');
      }
      return envelope;
    } on FormatException {
      throw const UnknownException();
    }
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

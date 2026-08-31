import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:flutter_base/features/devices/data/repositories/device_repository_impl.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/repositories/device_repository.dart';
import 'package:flutter_base/features/devices/domain/usecases/device_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((
  Ref ref,
) {
  return DeviceRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final deviceRepositoryProvider = Provider<DeviceRepository>((Ref ref) {
  return DeviceRepositoryImpl(ref.watch(deviceRemoteDataSourceProvider));
});

final getDevicesUseCaseProvider = Provider<GetDevices>((Ref ref) {
  return GetDevices(ref.watch(deviceRepositoryProvider));
});

final getDeviceDetailUseCaseProvider = Provider<GetDeviceDetail>((Ref ref) {
  return GetDeviceDetail(ref.watch(deviceRepositoryProvider));
});

final createDeviceUseCaseProvider = Provider<CreateDevice>((Ref ref) {
  return CreateDevice(ref.watch(deviceRepositoryProvider));
});

final updateDeviceUseCaseProvider = Provider<UpdateDevice>((Ref ref) {
  return UpdateDevice(ref.watch(deviceRepositoryProvider));
});

final deleteDeviceUseCaseProvider = Provider<DeleteDevice>((Ref ref) {
  return DeleteDevice(ref.watch(deviceRepositoryProvider));
});

final assignDeviceUseCaseProvider = Provider<AssignDevice>((Ref ref) {
  return AssignDevice(ref.watch(deviceRepositoryProvider));
});

final returnDeviceUseCaseProvider = Provider<ReturnDevice>((Ref ref) {
  return ReturnDevice(ref.watch(deviceRepositoryProvider));
});

final getDeviceHistoryUseCaseProvider = Provider<GetDeviceHistory>((Ref ref) {
  return GetDeviceHistory(ref.watch(deviceRepositoryProvider));
});

final deviceDetailProvider =
    FutureProvider.autoDispose.family<Device, String>((Ref ref, String id) {
  ref.watch(authControllerProvider);
  return ref.watch(getDeviceDetailUseCaseProvider)(id);
});

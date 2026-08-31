import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_history_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_list_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceActionController extends Notifier<DeviceActionState> {
  @override
  DeviceActionState build() => const DeviceActionState();

  Future<Device?> assign({
    required String id,
    required AssignDeviceBody body,
  }) async {
    if (state.isBusy) {
      return null;
    }
    if (body.employeeId.trim().isEmpty) {
      state = state.copyWith(
        fieldErrors: const <String, String>{
          'employee_id': 'Select an employee.',
        },
        error: 'Select an employee.',
      );
      return null;
    }
    state = state.copyWith(
      isAssigning: true,
      fieldErrors: const <String, String>{},
      clearError: true,
    );
    try {
      final Device result =
          await ref.read(assignDeviceUseCaseProvider)(id, body);
      state = const DeviceActionState();
      _refresh(id, result);
      return result;
    } catch (error) {
      state = state.copyWith(
        isAssigning: false,
        fieldErrors: DeviceErrorMapper.fieldErrors(error),
        error: DeviceErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<Device?> returnDevice({
    required String id,
    ReturnDeviceBody body = const ReturnDeviceBody(),
  }) async {
    if (state.isBusy) {
      return null;
    }
    state = state.copyWith(
      isReturning: true,
      fieldErrors: const <String, String>{},
      clearError: true,
    );
    try {
      final Device result =
          await ref.read(returnDeviceUseCaseProvider)(id, body);
      state = const DeviceActionState();
      _refresh(id, result);
      return result;
    } catch (error) {
      state = state.copyWith(
        isReturning: false,
        fieldErrors: DeviceErrorMapper.fieldErrors(error),
        error: DeviceErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<bool> delete(String id) async {
    if (state.isBusy) {
      return false;
    }
    state = state.copyWith(isDeleting: true, clearError: true);
    try {
      await ref.read(deleteDeviceUseCaseProvider)(id);
      state = const DeviceActionState();
      for (final DeviceListKind kind in DeviceListKind.values) {
        ref.read(deviceListControllerProvider(kind).notifier).removeDevice(id);
        ref.read(deviceListControllerProvider(kind).notifier).refresh();
      }
      ref.invalidate(deviceDetailProvider(id));
      return true;
    } catch (error) {
      state = state.copyWith(
        isDeleting: false,
        error: DeviceErrorMapper.message(error),
      );
      return false;
    }
  }

  void _refresh(String id, Device result) {
    ref.invalidate(deviceDetailProvider(id));
    ref.read(deviceHistoryControllerProvider(id).notifier).refresh();
    for (final DeviceListKind kind in DeviceListKind.values) {
      ref.read(deviceListControllerProvider(kind).notifier).replaceDevice(result);
      ref.read(deviceListControllerProvider(kind).notifier).refresh();
    }
  }
}

final deviceActionControllerProvider =
    NotifierProvider<DeviceActionController, DeviceActionState>(
  DeviceActionController.new,
);

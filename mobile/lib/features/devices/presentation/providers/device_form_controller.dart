import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_list_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _assetCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9_-]*$');

class DeviceFormController extends Notifier<DeviceFormState> {
  @override
  DeviceFormState build() {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      state = const DeviceFormState();
    });
    return const DeviceFormState();
  }

  Map<String, String> validate(DeviceWrite body) {
    final Map<String, String> errors = <String, String>{};
    final String code = body.assetCode.trim().toUpperCase();
    if (code.isEmpty) {
      errors['asset_code'] = 'Enter an asset code.';
    } else if (!_assetCodePattern.hasMatch(code)) {
      errors['asset_code'] =
          'Use letters, numbers, hyphens, or underscores.';
    }
    if (body.type.trim().length < 2) {
      errors['type'] = 'Enter a device type.';
    }
    if (body.cost != null && body.cost!.trim().isNotEmpty) {
      final double? value = double.tryParse(body.cost!.trim());
      if (value == null) {
        errors['cost'] = 'Enter a valid cost.';
      } else if (value < 0) {
        errors['cost'] = 'Cost cannot be negative.';
      }
    }
    if (body.purchaseDate != null &&
        body.warrantyExpiry != null &&
        body.warrantyExpiry!.isBefore(body.purchaseDate!)) {
      errors['warranty_expiry'] =
          'Warranty expiry must be on or after the purchase date.';
    }
    if (body.status == DeviceStatus.assigned) {
      errors['status'] = 'Assign the device instead of setting this status.';
    }
    return errors;
  }

  Future<Device?> create(DeviceWrite body) async {
    if (state.isSubmitting) {
      return null;
    }
    final Map<String, String> local = validate(body);
    if (local.isNotEmpty) {
      state = state.copyWith(fieldErrors: local, clearError: true);
      return null;
    }
    state = state.copyWith(
      isSubmitting: true,
      fieldErrors: const <String, String>{},
      clearError: true,
    );
    try {
      final Device created =
          await ref.read(createDeviceUseCaseProvider)(body);
      state = const DeviceFormState();
      ref
          .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
          .prependDevice(created);
      await ref
          .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
          .refresh();
      return created;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        fieldErrors: DeviceErrorMapper.fieldErrors(error),
        error: DeviceErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<Device?> update(String id, DeviceWrite body) async {
    if (state.isSubmitting) {
      return null;
    }
    final Map<String, String> local = validate(body);
    if (local.isNotEmpty) {
      state = state.copyWith(fieldErrors: local, clearError: true);
      return null;
    }
    state = state.copyWith(
      isSubmitting: true,
      fieldErrors: const <String, String>{},
      clearError: true,
    );
    try {
      final Device updated =
          await ref.read(updateDeviceUseCaseProvider)(id, body);
      state = const DeviceFormState();
      _refreshLists(updated);
      ref.invalidate(deviceDetailProvider(id));
      return updated;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        fieldErrors: DeviceErrorMapper.fieldErrors(error),
        error: DeviceErrorMapper.message(error),
      );
      return null;
    }
  }

  void _refreshLists(Device device) {
    for (final DeviceListKind kind in DeviceListKind.values) {
      ref.read(deviceListControllerProvider(kind).notifier).replaceDevice(device);
      ref.read(deviceListControllerProvider(kind).notifier).refresh();
    }
  }
}

final deviceFormControllerProvider =
    NotifierProvider<DeviceFormController, DeviceFormState>(
  DeviceFormController.new,
);

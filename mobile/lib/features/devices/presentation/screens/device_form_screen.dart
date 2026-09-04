import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_date_field.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_form_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_filter_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddDeviceScreen extends StatelessWidget {
  const AddDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeviceFormScreen();
  }
}

class EditDeviceScreen extends StatelessWidget {
  const EditDeviceScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return DeviceFormScreen(deviceId: deviceId);
  }
}

class DeviceFormScreen extends ConsumerStatefulWidget {
  const DeviceFormScreen({super.key, this.deviceId});

  final String? deviceId;

  @override
  ConsumerState<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends ConsumerState<DeviceFormScreen> {
  final TextEditingController _assetCode = TextEditingController();
  final TextEditingController _type = TextEditingController();
  final TextEditingController _manufacturer = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _serial = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  DeviceStatus? _status;
  DeviceStatus _currentStatus = DeviceStatus.available;
  bool _seeded = false;

  bool get _isEdit => widget.deviceId != null;

  @override
  void dispose() {
    _assetCode.dispose();
    _type.dispose();
    _manufacturer.dispose();
    _model.dispose();
    _serial.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seed(Device device) {
    if (_seeded) {
      return;
    }
    _seeded = true;
    _assetCode.text = device.assetCode;
    _type.text = device.type;
    _manufacturer.text = device.manufacturer;
    _model.text = device.model;
    _serial.text = device.serialNumber ?? '';
    _cost.text = device.cost ?? '';
    _notes.text = device.notes ?? '';
    _purchaseDate = device.purchaseDate;
    _warrantyExpiry = device.warrantyExpiry;
    _currentStatus = device.status;
    _status = device.status;
  }

  DeviceWrite _body() {
    return DeviceWrite(
      assetCode: _assetCode.text,
      type: _type.text,
      manufacturer: _manufacturer.text,
      model: _model.text,
      serialNumber: _serial.text.trim().isEmpty ? null : _serial.text,
      purchaseDate: _purchaseDate,
      warrantyExpiry: _warrantyExpiry,
      cost: _cost.text.trim().isEmpty ? null : _cost.text,
      notes: _notes.text,
      status: _isEdit ? _status : null,
    );
  }

  Future<void> _pickDate({required bool purchase}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = purchase
        ? (_purchaseDate ?? now)
        : (_warrantyExpiry ?? _purchaseDate ?? now);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (purchase) {
        _purchaseDate = picked;
      } else {
        _warrantyExpiry = picked;
      }
    });
  }

  Future<void> _submit() async {
    final Device? result = _isEdit
        ? await ref
            .read(deviceFormControllerProvider.notifier)
            .update(widget.deviceId!, _body())
        : await ref.read(deviceFormControllerProvider.notifier).create(_body());
    if (!mounted) {
      return;
    }
    if (result != null) {
      context.showSnack(_isEdit ? 'Device updated.' : 'Device created.');
      context.pop();
      return;
    }
    final String? error = ref.read(deviceFormControllerProvider).error;
    if (error != null) {
      context.showSnack(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEdit) {
      return _form();
    }
    final AsyncValue<Device> async =
        ref.watch(deviceDetailProvider(widget.deviceId!));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit device')),
        body: const AppLoader(),
      ),
      error: (Object error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit device')),
        body: AppErrorWidget(
          message: DeviceErrorMapper.message(error),
          onRetry: () =>
              ref.invalidate(deviceDetailProvider(widget.deviceId!)),
        ),
      ),
      data: (Device device) {
        _seed(device);
        return _form();
      },
    );
  }

  Widget _form() {
    final DeviceFormState form = ref.watch(deviceFormControllerProvider);
    final List<DeviceStatus> nextStatuses = _currentStatus.allowedUpdateStatuses;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit device' : 'Add device')),
      body: ListView(
        padding: AppBreakpoints.pagePadding(context),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          AppTextField(
            controller: _assetCode,
            label: 'Asset code',
            errorText: form.fieldErrors['asset_code'],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _type,
            label: 'Device type',
            errorText: form.fieldErrors['type'],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: kSuggestedDeviceTypes
                .map(
                  (String type) => ActionChip(
                    label: Text(type),
                    onPressed: () => setState(() => _type.text = type),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _manufacturer,
            label: 'Manufacturer',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _model,
            label: 'Model',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _serial,
            label: 'Serial number',
            errorText: form.fieldErrors['serial_number'],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDateField(
            label: 'Purchase date',
            value: _purchaseDate,
            hint: 'Not set',
            onTap: () => _pickDate(purchase: true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDateField(
            label: 'Warranty expiry',
            value: _warrantyExpiry,
            hint: 'Not set',
            icon: Icons.event_outlined,
            errorText: form.fieldErrors['warranty_expiry'],
            onTap: () => _pickDate(purchase: false),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _cost,
            label: 'Cost',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: form.fieldErrors['cost'],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _notes,
            label: 'Notes',
            maxLines: 4,
            errorText: form.fieldErrors['notes'],
          ),
          if (_isEdit) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Status changes that assign or return a device are not listed here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (nextStatuses.isEmpty)
              Text(
                'Current status: ${_currentStatus.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              AppDropdown<DeviceStatus>(
                label: 'Status',
                value: nextStatuses.contains(_status) ? _status : _currentStatus,
                errorText: form.fieldErrors['status'],
                items: <AppDropdownItem<DeviceStatus>>[
                  AppDropdownItem<DeviceStatus>(
                    value: _currentStatus,
                    label: _currentStatus.label,
                  ),
                  ...nextStatuses.map(
                    (DeviceStatus item) => AppDropdownItem<DeviceStatus>(
                      value: item,
                      label: item.label,
                    ),
                  ),
                ],
                onChanged: (DeviceStatus? value) {
                  setState(() => _status = value);
                },
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _isEdit ? 'Save' : 'Create',
            isLoading: form.isSubmitting,
            onPressed: form.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_type_form_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/apply_leave_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeaveTypeFormScreen extends ConsumerStatefulWidget {
  const LeaveTypeFormScreen({super.key, this.leaveTypeId});

  final String? leaveTypeId;

  @override
  ConsumerState<LeaveTypeFormScreen> createState() =>
      _LeaveTypeFormScreenState();
}

class _LeaveTypeFormScreenState extends ConsumerState<LeaveTypeFormScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _days = TextEditingController(text: '0');
  bool _isPaid = true;
  bool _carryForward = false;
  LeaveTypeStatus _status = LeaveTypeStatus.active;
  bool _seeded = false;

  bool get _isEdit => widget.leaveTypeId != null;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _days.dispose();
    super.dispose();
  }

  void _seed(LeaveType type) {
    if (_seeded) {
      return;
    }
    _seeded = true;
    _name.text = type.name;
    _code.text = type.code;
    _days.text = '${type.daysAllowed}';
    _isPaid = type.isPaid;
    _carryForward = type.carryForward;
    _status = type.status;
  }

  Future<void> _submit() async {
    final int days = int.tryParse(_days.text.trim()) ?? -1;
    final LeaveTypeWrite body = LeaveTypeWrite(
      name: _name.text.trim(),
      code: _code.text.trim(),
      daysAllowed: days,
      isPaid: _isPaid,
      carryForward: _carryForward,
      status: _status,
    );
    final LeaveType? result = _isEdit
        ? await ref
            .read(leaveTypeFormControllerProvider.notifier)
            .update(widget.leaveTypeId!, body)
        : await ref.read(leaveTypeFormControllerProvider.notifier).create(body);
    if (!mounted) {
      return;
    }
    if (result != null) {
      context.showSnack(
        _isEdit ? 'Leave type updated.' : 'Leave type created.',
      );
      context.pop();
      return;
    }
    final String? error = ref.read(leaveTypeFormControllerProvider).error;
    if (error != null) {
      context.showSnack(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEdit) {
      return _form();
    }
    final AsyncValue<LeaveType> async =
        ref.watch(leaveTypeDetailProvider(widget.leaveTypeId!));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit leave type')),
        body: const AppLoader(),
      ),
      error: (Object error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit leave type')),
        body: AppErrorWidget(
          message: LeaveErrorMapper.message(error),
          onRetry: () =>
              ref.invalidate(leaveTypeDetailProvider(widget.leaveTypeId!)),
        ),
      ),
      data: (LeaveType type) {
        _seed(type);
        return _form();
      },
    );
  }

  Widget _form() {
    final LeaveActionState action = ref.watch(leaveTypeFormControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit leave type' : 'Create leave type'),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: <Widget>[
          AppTextField(
            controller: _name,
            label: 'Name',
            enabled: !action.isBusy,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _code,
            label: 'Code',
            enabled: !action.isBusy,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _days,
            label: 'Days allowed',
            keyboardType: TextInputType.number,
            enabled: !action.isBusy,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Paid'),
            value: _isPaid,
            onChanged: action.isBusy
                ? null
                : (bool value) => setState(() => _isPaid = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Carry forward'),
            value: _carryForward,
            onChanged: action.isBusy
                ? null
                : (bool value) => setState(() => _carryForward = value),
          ),
          AppDropdown<LeaveTypeStatus>(
            key: ValueKey<LeaveTypeStatus>(_status),
            label: 'Status',
            value: _status,
            enabled: !action.isBusy,
            items: LeaveTypeStatus.values
                .where((LeaveTypeStatus item) => item != LeaveTypeStatus.unknown)
                .map(
                  (LeaveTypeStatus item) => AppDropdownItem<LeaveTypeStatus>(
                    value: item,
                    label: item.label,
                  ),
                )
                .toList(),
            onChanged: (LeaveTypeStatus? value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _isEdit ? 'Save' : 'Create',
            isLoading: action.isBusy,
            onPressed: action.isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

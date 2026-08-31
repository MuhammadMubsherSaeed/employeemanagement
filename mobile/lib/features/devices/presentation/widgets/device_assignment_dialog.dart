import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';

Future<AssignDeviceBody?> showDeviceAssignmentDialog({
  required BuildContext context,
  required Employee employee,
  bool isLoading = false,
}) {
  return showDialog<AssignDeviceBody>(
    context: context,
    barrierDismissible: !isLoading,
    builder: (BuildContext context) {
      return DeviceAssignmentDialog(employee: employee);
    },
  );
}

class DeviceAssignmentDialog extends StatefulWidget {
  const DeviceAssignmentDialog({
    super.key,
    required this.employee,
  });

  final Employee employee;

  @override
  State<DeviceAssignmentDialog> createState() => _DeviceAssignmentDialogState();
}

class _DeviceAssignmentDialogState extends State<DeviceAssignmentDialog> {
  final TextEditingController _condition = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _condition.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    Navigator.of(context).pop(
      AssignDeviceBody(
        employeeId: widget.employee.id,
        conditionOnAssignment: _condition.text,
        notes: _notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign device'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Assign to ${widget.employee.fullName}?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _condition,
              label: 'Condition on assignment',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _notes,
              label: 'Notes',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Assign',
          expand: false,
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

Future<ReturnDeviceBody?> showDeviceReturnSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<ReturnDeviceBody>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return const DeviceReturnSheet();
    },
  );
}

class DeviceReturnSheet extends StatefulWidget {
  const DeviceReturnSheet({super.key});

  @override
  State<DeviceReturnSheet> createState() => _DeviceReturnSheetState();
}

class _DeviceReturnSheetState extends State<DeviceReturnSheet> {
  final TextEditingController _condition = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _condition.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    Navigator.of(context).pop(
      ReturnDeviceBody(
        conditionOnReturn: _condition.text,
        notes: _notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Return device',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _condition,
            label: 'Condition on return',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _notes,
            label: 'Notes',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Mark as returned',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

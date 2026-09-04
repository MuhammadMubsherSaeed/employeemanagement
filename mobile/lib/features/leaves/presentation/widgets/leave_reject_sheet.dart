import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_bottom_sheet.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_action_controller.dart';

Future<String?> showLeaveRejectSheet(BuildContext context) {
  return AppBottomSheet.show<String>(
    context: context,
    builder: (BuildContext context) {
      return const LeaveRejectSheet();
    },
  );
}

class LeaveRejectSheet extends StatefulWidget {
  const LeaveRejectSheet({super.key});

  @override
  State<LeaveRejectSheet> createState() => _LeaveRejectSheetState();
}

class _LeaveRejectSheetState extends State<LeaveRejectSheet> {
  final TextEditingController _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _reason.text.trim();
    if (value.length < kLeaveRejectionMinLength) {
      setState(() {
        _error = 'Enter a meaningful rejection reason.';
      });
      return;
    }
    if (value.length > kLeaveRejectionMaxLength) {
      setState(() {
        _error = 'Rejection reason is too long.';
      });
      return;
    }
    Navigator.of(context).pop(value);
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
            'Reject leave request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _reason,
            label: 'Rejection reason',
            maxLines: 4,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Reject',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

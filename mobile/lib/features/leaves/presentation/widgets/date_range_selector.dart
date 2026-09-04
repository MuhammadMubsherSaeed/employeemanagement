import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_date_field.dart';

class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    this.startError,
    this.endError,
    this.enabled = true,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end) onChanged;
  final String? startError;
  final String? endError;
  final bool enabled;

  Future<void> _pick(BuildContext context, {required bool start}) async {
    if (!enabled) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime initial = start
        ? (startDate ?? now)
        : (endDate ?? startDate ?? now);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) {
      return;
    }
    final DateTime day = DateTime(picked.year, picked.month, picked.day);
    if (start) {
      DateTime? nextEnd = endDate;
      if (nextEnd != null && nextEnd.isBefore(day)) {
        nextEnd = day;
      }
      onChanged(day, nextEnd);
      return;
    }
    onChanged(startDate, day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDateField(
          label: 'Start date',
          value: startDate,
          enabled: enabled,
          errorText: startError,
          onTap: () => _pick(context, start: true),
        ),
        const SizedBox(height: AppSpacing.md),
        AppDateField(
          label: 'End date',
          value: endDate,
          enabled: enabled,
          errorText: endError,
          icon: Icons.event_outlined,
          onTap: () => _pick(context, start: false),
        ),
        if (startDate != null || endDate != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Clear dates',
            variant: AppButtonVariant.text,
            expand: false,
            onPressed: enabled ? () => onChanged(null, null) : null,
          ),
        ],
      ],
    );
  }
}

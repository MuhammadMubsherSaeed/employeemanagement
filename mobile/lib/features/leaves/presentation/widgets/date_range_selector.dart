import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_button.dart';

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
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: enabled,
          title: const Text('Start date'),
          subtitle: Text(
            startDate == null ? 'Select a date' : AppDateFormatter.date(startDate!),
          ),
          onTap: () => _pick(context, start: true),
        ),
        if (startError != null)
          Text(
            startError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: enabled,
          title: const Text('End date'),
          subtitle: Text(
            endDate == null ? 'Select a date' : AppDateFormatter.date(endDate!),
          ),
          onTap: () => _pick(context, start: false),
        ),
        if (endError != null)
          Text(
            endError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
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

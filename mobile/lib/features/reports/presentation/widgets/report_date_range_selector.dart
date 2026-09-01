import 'package:flutter/material.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/date_range_selector.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_error_mapper.dart';

class ReportDateRangeSelector extends StatelessWidget {
  const ReportDateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool invalid = startDate != null &&
        endDate != null &&
        DateTime(startDate!.year, startDate!.month, startDate!.day)
            .isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day));
    return DateRangeSelector(
      startDate: startDate,
      endDate: endDate,
      onChanged: onChanged,
      enabled: enabled,
      startError: invalid ? ReportErrorMapper.invalidRange : null,
    );
  }
}

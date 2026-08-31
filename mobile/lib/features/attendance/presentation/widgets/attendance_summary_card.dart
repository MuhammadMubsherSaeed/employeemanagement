import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Monthly summary', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _row(context, 'Total days', '${summary.totalDays}'),
          _row(context, 'Present', '${summary.presentDays}'),
          _row(context, 'Absent', '${summary.absentDays}'),
          _row(context, 'Late', '${summary.lateDays}'),
          _row(context, 'Half day', '${summary.halfDays}'),
          _row(context, 'Leave', '${summary.leaveDays}'),
          _row(context, 'Holiday', '${summary.holidayDays}'),
          _row(context, 'Weekend', '${summary.weekendDays}'),
          _row(
            context,
            'Working',
            WorkingDuration.format(summary.totalWorkingMinutes),
          ),
          if (summary.overtimeMinutes > 0)
            _row(
              context,
              'Overtime',
              WorkingDuration.format(summary.overtimeMinutes),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

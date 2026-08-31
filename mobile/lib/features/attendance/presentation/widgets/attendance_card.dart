import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_status_badge.dart';

class AttendanceCard extends StatelessWidget {
  const AttendanceCard({
    super.key,
    required this.record,
    this.onTap,
    this.showEmployee = false,
  });

  final AttendanceRecord record;
  final VoidCallback? onTap;
  final bool showEmployee;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label: 'Attendance ${AppDateFormatter.date(record.date)}',
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    AppDateFormatter.date(record.date),
                    style: text.titleMedium,
                  ),
                ),
                AttendanceStatusBadge(status: record.status),
              ],
            ),
            if (showEmployee && record.employee != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(record.employee!.fullName, style: text.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check in: ${_time(record.checkIn)}',
              style: text.bodyMedium,
            ),
            Text(
              'Check out: ${_time(record.checkOut)}',
              style: text.bodyMedium,
            ),
            Text(
              'Working: ${WorkingDuration.format(record.totalMinutes)}',
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return AppDateFormatter.time(value.toLocal());
  }
}

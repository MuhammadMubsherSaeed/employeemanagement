import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_info_row.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_status_badge.dart';

class TodayAttendanceCard extends StatelessWidget {
  const TodayAttendanceCard({super.key, this.record});

  final AttendanceRecord? record;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime today = DateTime.now();
    final PunchState punch = record?.punchState ?? PunchState.none;
    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text("Today's attendance", style: text.titleMedium),
              ),
              if (record != null)
                AttendanceStatusBadge(status: record!.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(AppDateFormatter.date(today), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (record == null)
            Text('No attendance for today.', style: text.bodyLarge)
          else ...<Widget>[
            Text(
              PunchLabel.of(punch),
              style: text.titleSmall?.copyWith(
                color: punch == PunchState.checkedIn
                    ? AppColors.successOf(Theme.of(context).brightness)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppInfoRow(label: 'Check in', value: _time(record!.checkIn)),
            AppInfoRow(label: 'Check out', value: _time(record!.checkOut)),
            AppInfoRow(
              label: 'Working',
              value: WorkingDuration.format(record!.totalMinutes),
            ),
          ],
        ],
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

class PunchLabel {
  PunchLabel._();

  static String of(PunchState state) {
    return switch (state) {
      PunchState.none => 'Not checked in',
      PunchState.checkedIn => 'Checked in',
      PunchState.checkedOut => 'Checked out',
    };
  }
}

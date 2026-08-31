import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Today's attendance", style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(AppDateFormatter.date(today), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (record == null)
            Text('No attendance for today.', style: text.bodyLarge)
          else ...<Widget>[
            Text(
              PunchLabel.of(record!.punchState),
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AttendanceStatusBadge(status: record!.status),
            const SizedBox(height: AppSpacing.md),
            _row(context, 'Check in', _time(record!.checkIn)),
            _row(context, 'Check out', _time(record!.checkOut)),
            _row(
              context,
              'Working',
              WorkingDuration.format(record!.totalMinutes),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
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

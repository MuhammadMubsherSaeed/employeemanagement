import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_error_mapper.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceDetailsScreen extends ConsumerWidget {
  const AttendanceDetailsScreen({super.key, required this.attendanceId});

  final String attendanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AttendanceRecord> async =
        ref.watch(attendanceDetailProvider(attendanceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance details')),
      body: async.when(
        loading: () => const AppLoader(message: 'Loading attendance…'),
        error: (Object error, _) => AppErrorWidget(
          message: AttendanceErrorMapper.message(error),
          onRetry: () =>
              ref.invalidate(attendanceDetailProvider(attendanceId)),
        ),
        data: (AttendanceRecord record) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(attendanceDetailProvider(attendanceId));
            await ref.read(attendanceDetailProvider(attendanceId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screen,
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppDateFormatter.date(record.date),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        AttendanceStatusBadge(status: record.status),
                      ],
                    ),
                    if (record.employee != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        record.employee!.fullName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        record.employee!.employeeCode,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _row(context, 'Check in', _time(record.checkIn)),
                    _row(context, 'Check out', _time(record.checkOut)),
                    _row(
                      context,
                      'Working',
                      WorkingDuration.format(record.totalMinutes),
                    ),
                  ],
                ),
              ),
              if (record.hasSensitiveLocation) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (record.checkInIp != null)
                        _row(context, 'Check-in IP', record.checkInIp!),
                      if (record.checkOutIp != null)
                        _row(context, 'Check-out IP', record.checkOutIp!),
                      if (record.checkInLatitude != null &&
                          record.checkInLongitude != null)
                        _row(
                          context,
                          'Check-in GPS',
                          '${record.checkInLatitude}, ${record.checkInLongitude}',
                        ),
                      if (record.checkOutLatitude != null &&
                          record.checkOutLongitude != null)
                        _row(
                          context,
                          'Check-out GPS',
                          '${record.checkOutLatitude}, ${record.checkOutLongitude}',
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
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

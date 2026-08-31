import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_calendar_controller.dart';
import 'package:flutter_base/features/attendance/presentation/states/attendance_calendar_state.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(attendanceCalendarControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AttendanceCalendarState calendar =
        ref.watch(attendanceCalendarControllerProvider);
    final DateTime now = DateTime.now();
    final bool canGoNext = DateTime(calendar.month.year, calendar.month.month)
        .isBefore(DateTime(now.year, now.month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance calendar'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Current month',
            onPressed: () => ref
                .read(attendanceCalendarControllerProvider.notifier)
                .goToCurrentMonth(),
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(attendanceCalendarControllerProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screen,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => ref
                      .read(attendanceCalendarControllerProvider.notifier)
                      .previousMonth(),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    DateFormat.yMMMM().format(calendar.month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: canGoNext
                      ? () => ref
                          .read(attendanceCalendarControllerProvider.notifier)
                          .nextMonth()
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (calendar.isLoading)
              const AppLoader(message: 'Loading calendar…')
            else if (calendar.error != null)
              AppErrorWidget(
                message: calendar.error!,
                onRetry: () => ref
                    .read(attendanceCalendarControllerProvider.notifier)
                    .load(),
              )
            else ...<Widget>[
              _MonthGrid(
                month: calendar.month,
                byDate: calendar.byDate,
              ),
              if (calendar.records.isEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const AppEmptyState(
                  title: 'No attendance for this month.',
                ),
              ] else ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: calendar.records
                      .map((AttendanceRecord item) => item.status)
                      .toSet()
                      .map(
                        (AttendanceStatus status) =>
                            AttendanceStatusBadge(status: status),
                      )
                      .toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.byDate});

  final DateTime month;
  final Map<String, AttendanceRecord> byDate;

  @override
  Widget build(BuildContext context) {
    final DateTime first = monthStart(month);
    final int days = monthEnd(month).day;
    final int leading = first.weekday % 7;
    const List<String> headers = <String>[
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ];

    return Column(
      children: <Widget>[
        Row(
          children: headers
              .map(
                (String label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leading + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (BuildContext context, int index) {
            if (index < leading) {
              return const SizedBox.shrink();
            }
            final int day = index - leading + 1;
            final DateTime date = DateTime(month.year, month.month, day);
            final AttendanceRecord? record = byDate[formatDateParam(date)];
            return _DayCell(
              day: day,
              record: record,
              onTap: record == null
                  ? null
                  : () => context.push(AppRoutes.attendanceDetail(record.id)),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.record,
    this.onTap,
  });

  final int day;
  final AttendanceRecord? record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AttendanceStatus? status = record?.status;
    final Color fill = status == null
        ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
        : AttendanceStatusBadge.colorOf(status).withValues(alpha: 0.22);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: fill,
        ),
        child: Center(
          child: Text('$day', style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}

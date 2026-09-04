import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_error_mapper.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/providers/today_attendance_controller.dart';
import 'package:flutter_base/features/attendance/presentation/states/today_attendance_state.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/today_attendance_card.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AttendanceDashboardScreen extends ConsumerStatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  ConsumerState<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState
    extends ConsumerState<AttendanceDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(todayAttendanceProvider.notifier).load();
    });
  }

  Future<void> _refresh(AttendanceSummaryQuery summaryQuery) async {
    await ref.read(todayAttendanceProvider.notifier).refresh();
    ref.invalidate(attendanceSummaryProvider(summaryQuery));
  }

  Future<void> _checkIn() async {
    final bool ok = await ref.read(todayAttendanceProvider.notifier).checkIn();
    if (!mounted) {
      return;
    }
    if (ok) {
      context.showSnack('Checked in.');
    } else {
      final String? error = ref.read(todayAttendanceProvider).actionError;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  Future<void> _checkOut() async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Check out',
      message: 'Are you sure you want to check out?',
      confirmLabel: 'Check Out',
      cancelLabel: 'Cancel',
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final bool ok = await ref.read(todayAttendanceProvider.notifier).checkOut();
    if (!mounted) {
      return;
    }
    if (ok) {
      context.showSnack('Checked out.');
    } else {
      final String? error = ref.read(todayAttendanceProvider).actionError;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TodayAttendanceState today = ref.watch(todayAttendanceProvider);
    final AttendanceAccess access = AttendanceAccess(
      ref.watch(authorizationProvider),
    );
    final DateTime now = DateTime.now();
    final AttendanceSummaryQuery summaryQuery = AttendanceSummaryQuery(
      startDate: monthStart(now),
      endDate: monthEnd(now),
    );
    final AsyncValue<AttendanceSummary> summary =
        ref.watch(attendanceSummaryProvider(summaryQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: <Widget>[
          IconButton(
            tooltip: 'History',
            onPressed: () => context.push(AppRoutes.attendanceHistory),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Calendar',
            onPressed: () => context.push(AppRoutes.attendanceCalendar),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(summaryQuery),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(summaryQuery),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screen,
          children: <Widget>[
            if (today.isLoading)
              const AppLoader(message: 'Loading attendance…')
            else if (today.error != null)
              AppErrorWidget(
                message: today.error!,
                onRetry: () =>
                    ref.read(todayAttendanceProvider.notifier).load(),
              )
            else ...<Widget>[
              TodayAttendanceCard(record: today.record),
              const SizedBox(height: AppSpacing.md),
              if (access.canCheckIn && today.punchState == PunchState.none)
                AppButton(
                  label: 'Check In',
                  isLoading: today.isCheckingIn,
                  onPressed: today.isBusy ? null : _checkIn,
                ),
              if (access.canCheckOut &&
                  today.punchState == PunchState.checkedIn) ...<Widget>[
                AppButton(
                  label: 'Check Out',
                  isLoading: today.isCheckingOut,
                  onPressed: today.isBusy ? null : _checkOut,
                ),
              ],
              if (access.canCheckIn &&
                  today.punchState == PunchState.checkedOut)
                Text(
                  'You have completed attendance for today.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (!access.canCheckIn)
                Text(
                  'Your role cannot check in or out from this app.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            summary.when(
              loading: () => const AppLoader(message: 'Loading summary…'),
              error: (Object error, _) => AppErrorWidget(
                message: AttendanceErrorMapper.message(error),
                onRetry: () =>
                    ref.invalidate(attendanceSummaryProvider(summaryQuery)),
              ),
              data: (data) => AttendanceSummaryCard(summary: data),
            ),
          ],
        ),
      ),
    );
  }
}

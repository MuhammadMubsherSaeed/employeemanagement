import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_history_controller.dart';
import 'package:flutter_base/features/attendance/presentation/states/attendance_history_state.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_filter_sheet.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(attendanceHistoryControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double max = _scroll.position.maxScrollExtent;
    if (max <= 0) {
      return;
    }
    if (_scroll.position.pixels > max - 240) {
      ref.read(attendanceHistoryControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final AttendanceHistoryState list =
        ref.read(attendanceHistoryControllerProvider);
    final AttendanceAccess access = AttendanceAccess(
      ref.read(authorizationProvider),
    );
    final AttendanceQuery? next = await showAttendanceFilterSheet(
      context: context,
      current: list.query,
      canFilterByEmployee: access.canFilterByEmployee,
    );
    if (next == null) {
      return;
    }
    await ref
        .read(attendanceHistoryControllerProvider.notifier)
        .applyFilters(next);
  }

  @override
  Widget build(BuildContext context) {
    final AttendanceHistoryState list =
        ref.watch(attendanceHistoryControllerProvider);
    final AttendanceAccess access = AttendanceAccess(
      ref.watch(authorizationProvider),
    );
    final int filters = list.query.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance history'),
        actions: <Widget>[
          IconButton(
            tooltip: filters == 0 ? 'Filters' : 'Filters ($filters)',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: filters > 0,
              label: Text('$filters'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: _body(list, access),
    );
  }

  Widget _body(AttendanceHistoryState list, AttendanceAccess access) {
    if (list.isInitialLoading) {
      return const AppLoader(message: 'Loading attendance…');
    }
    if (list.error != null && list.items.isEmpty) {
      return AppErrorWidget(
        message: list.error!,
        onRetry: () =>
            ref.read(attendanceHistoryControllerProvider.notifier).loadInitial(),
      );
    }
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(attendanceHistoryControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 80),
            AppEmptyState(
              title: 'No attendance records found.',
              subtitle: 'Try a different date range or status.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(attendanceHistoryControllerProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scroll,
        padding: AppSpacing.screen,
        itemCount: list.items.length + (list.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index >= list.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final AttendanceRecord record = list.items[index];
          return AttendanceCard(
            record: record,
            showEmployee: access.canViewTeam,
            onTap: () => context.push(AppRoutes.attendanceDetail(record.id)),
          );
        },
      ),
    );
  }
}

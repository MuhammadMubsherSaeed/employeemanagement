import 'package:flutter/material.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_status_badge.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_status_badge.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_opener.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_status_badge.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/domain/report_access.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_export_controller.dart';
import 'package:flutter_base/features/reports/presentation/providers/report_list_controller.dart';
import 'package:flutter_base/features/reports/presentation/states/report_export_state.dart';
import 'package:flutter_base/features/reports/presentation/states/report_list_state.dart';
import 'package:flutter_base/features/reports/presentation/widgets/export_button.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_filter_chip.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_filter_sheet.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_item_cards.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_table.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_type_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key, required this.kind});

  final ReportKind kind;

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      if (!ReportAccess(ref.read(authorizationProvider)).canView) {
        return;
      }
      ref.read(reportListControllerProvider(widget.kind).notifier).loadInitial();
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
      ref.read(reportListControllerProvider(widget.kind).notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final ReportAccess access = _access;
    final ReportListState list =
        ref.read(reportListControllerProvider(widget.kind));
    final List<Department> departments = access.canFilterByDepartment
        ? await ref.read(departmentsProvider.future)
        : const <Department>[];
    final List<Employee> employees = access.canFilterByEmployee
        ? await ref.read(employeeDirectoryProvider.future)
        : const <Employee>[];
    List<LeaveType> leaveTypes = const <LeaveType>[];
    if (widget.kind.supportsLeaveType) {
      leaveTypes = await ref.read(leaveTypesProvider.future);
    }
    if (!mounted) {
      return;
    }
    final ReportQuery? next = await showReportFilterSheet(
      context: context,
      current: list.query,
      canFilterByEmployee: access.canFilterByEmployee,
      canFilterByDepartment: access.canFilterByDepartment,
      departments: departments,
      employees: employees,
      leaveTypes: leaveTypes,
    );
    if (next == null) {
      return;
    }
    await ref
        .read(reportListControllerProvider(widget.kind).notifier)
        .applyFilters(next);
  }

  ReportAccess get _access {
    return ReportAccess(ref.read(authorizationProvider));
  }

  @override
  Widget build(BuildContext context) {
    final ReportAccess access = ReportAccess(
      ref.watch(authorizationProvider),
    );
    if (!access.canOpen(widget.kind)) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.kind.title)),
        body: const Center(child: Text('You do not have access to this report.')),
      );
    }
    final ReportListState list =
        ref.watch(reportListControllerProvider(widget.kind));
    final ReportExportState export =
        ref.watch(reportExportControllerProvider(widget.kind));
    ref.listen<ReportExportState>(
      reportExportControllerProvider(widget.kind),
      (ReportExportState? previous, ReportExportState next) {
        if (!mounted) {
          return;
        }
        if (next.phase == ReportExportPhase.success &&
            next.file != null &&
            previous?.file != next.file) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${next.file!.filename}'),
              action: SnackBarAction(
                label: 'Share',
                onPressed: () {
                  ref
                      .read(reportExportControllerProvider(widget.kind).notifier)
                      .share();
                },
              ),
            ),
          );
        }
        if (next.phase == ReportExportPhase.error && next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
        }
      },
    );
    final int filters = list.query.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.title),
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
          if (access.canExport)
            ExportButton(
              state: export,
              onSelected: (ReportExportFormat format) {
                ref
                    .read(reportExportControllerProvider(widget.kind).notifier)
                    .export(list.query, format);
              },
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: EmployeeSearchBar(
              hintText: 'Search this report',
              initialValue: list.query.search,
              onChanged: (String value) {
                ref
                    .read(reportListControllerProvider(widget.kind).notifier)
                    .setSearch(value);
              },
            ),
          ),
          if (filters > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  children: <Widget>[
                    ReportFilterChip(
                      label: 'Clear filters',
                      onDeleted: () {
                        ref
                            .read(
                              reportListControllerProvider(widget.kind).notifier,
                            )
                            .clearFilters();
                      },
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(reportListControllerProvider(widget.kind).notifier)
                  .refresh(),
              child: ListView(
                controller: _scroll,
                padding: AppSpacing.screen,
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  ReportSummaryCard(count: list.count),
                  const SizedBox(height: AppSpacing.md),
                  if (export.phase == ReportExportPhase.success &&
                      export.file != null) ...<Widget>[
                    ExportActionBar(
                      onShare: () {
                        ref
                            .read(
                              reportExportControllerProvider(widget.kind)
                                  .notifier,
                            )
                            .share();
                      },
                      onOpen: () {
                        ref
                            .read(
                              reportExportControllerProvider(widget.kind)
                                  .notifier,
                            )
                            .open();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ReportTable(
                    columns: _columns(widget.kind),
                    rows: list.items,
                    emptyMessage: widget.kind.emptyMessage,
                    isLoading: list.isInitialLoading,
                    isLoadingMore: list.isLoadingMore,
                    hasMore: list.hasMore,
                    error: list.error,
                    onRetry: () => ref
                        .read(
                          reportListControllerProvider(widget.kind).notifier,
                        )
                        .loadInitial(),
                    onLoadMore: () => ref
                        .read(
                          reportListControllerProvider(widget.kind).notifier,
                        )
                        .loadMore(),
                    cardBuilder: (BuildContext context, Object row) {
                      return switch (row) {
                        AttendanceReportItem item =>
                          AttendanceReportCard(item: item),
                        LeaveReportItem item => LeaveReportCard(item: item),
                        EmployeeReportItem item =>
                          EmployeeReportCard(item: item),
                        DeviceReportItem item => DeviceReportCard(item: item),
                        _ => const SizedBox.shrink(),
                      };
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<ReportColumn> _columns(ReportKind kind) {
  switch (kind) {
    case ReportKind.attendance:
      return <ReportColumn>[
        ReportColumn(
          label: 'Employee',
          value: (Object row) =>
              (row as AttendanceReportItem).employee.fullName,
        ),
        ReportColumn(
          label: 'Code',
          value: (Object row) =>
              (row as AttendanceReportItem).employee.employeeCode,
        ),
        ReportColumn(
          label: 'Department',
          value: (Object row) =>
              (row as AttendanceReportItem).employee.department?.name ?? '—',
        ),
        ReportColumn(
          label: 'Date',
          value: (Object row) {
            final DateTime? date = (row as AttendanceReportItem).date;
            return date == null ? '—' : AppDateFormatter.date(date);
          },
        ),
        ReportColumn(
          label: 'Check-in',
          value: (Object row) => _time((row as AttendanceReportItem).checkIn),
        ),
        ReportColumn(
          label: 'Check-out',
          value: (Object row) => _time((row as AttendanceReportItem).checkOut),
        ),
        ReportColumn(
          label: 'Duration',
          value: (Object row) => WorkingDuration.format(
            (row as AttendanceReportItem).workingMinutes,
          ),
        ),
        ReportColumn(
          label: 'Status',
          value: (Object row) => (row as AttendanceReportItem).status.label,
          cell: (BuildContext context, Object row) => AttendanceStatusBadge(
            status: (row as AttendanceReportItem).status,
          ),
        ),
      ];
    case ReportKind.leaves:
      return <ReportColumn>[
        ReportColumn(
          label: 'Employee',
          value: (Object row) => (row as LeaveReportItem).employee.fullName,
        ),
        ReportColumn(
          label: 'Department',
          value: (Object row) =>
              (row as LeaveReportItem).employee.department?.name ?? '—',
        ),
        ReportColumn(
          label: 'Leave type',
          value: (Object row) => (row as LeaveReportItem).leaveType.name,
        ),
        ReportColumn(
          label: 'Start',
          value: (Object row) {
            final DateTime? date = (row as LeaveReportItem).startDate;
            return date == null ? '—' : AppDateFormatter.date(date);
          },
        ),
        ReportColumn(
          label: 'End',
          value: (Object row) {
            final DateTime? date = (row as LeaveReportItem).endDate;
            return date == null ? '—' : AppDateFormatter.date(date);
          },
        ),
        ReportColumn(
          label: 'Days',
          value: (Object row) =>
              leaveDaysLabel((row as LeaveReportItem).totalDays),
        ),
        ReportColumn(
          label: 'Status',
          value: (Object row) => (row as LeaveReportItem).status.label,
          cell: (BuildContext context, Object row) =>
              LeaveStatusBadge(status: (row as LeaveReportItem).status),
        ),
        ReportColumn(
          label: 'Approved by',
          value: (Object row) =>
              (row as LeaveReportItem).approvedBy?.email ?? '—',
        ),
        ReportColumn(
          label: 'Approved date',
          value: (Object row) {
            final DateTime? date = (row as LeaveReportItem).approvedAt;
            return date == null ? '—' : AppDateFormatter.date(date);
          },
        ),
      ];
    case ReportKind.employees:
      return <ReportColumn>[
        ReportColumn(
          label: 'Code',
          value: (Object row) => (row as EmployeeReportItem).employeeCode,
        ),
        ReportColumn(
          label: 'Name',
          value: (Object row) => (row as EmployeeReportItem).fullName,
        ),
        ReportColumn(
          label: 'Department',
          value: (Object row) =>
              (row as EmployeeReportItem).department?.name ?? '—',
        ),
        ReportColumn(
          label: 'Position',
          value: (Object row) =>
              (row as EmployeeReportItem).position?.title ?? '—',
        ),
        ReportColumn(
          label: 'Employment type',
          value: (Object row) =>
              (row as EmployeeReportItem).employmentType.label,
        ),
        ReportColumn(
          label: 'Joining date',
          value: (Object row) {
            final DateTime? date = (row as EmployeeReportItem).joiningDate;
            return date == null ? '—' : AppDateFormatter.date(date);
          },
        ),
        ReportColumn(
          label: 'Status',
          value: (Object row) => (row as EmployeeReportItem).status.label,
          cell: (BuildContext context, Object row) => EmployeeStatusBadge(
            status: (row as EmployeeReportItem).status,
          ),
        ),
        ReportColumn(
          label: 'Manager',
          value: (Object row) =>
              (row as EmployeeReportItem).manager?.fullName ?? '—',
        ),
      ];
    case ReportKind.devices:
      return <ReportColumn>[
        ReportColumn(
          label: 'Asset code',
          value: (Object row) => (row as DeviceReportItem).assetCode,
        ),
        ReportColumn(
          label: 'Type',
          value: (Object row) => (row as DeviceReportItem).type,
        ),
        ReportColumn(
          label: 'Manufacturer',
          value: (Object row) => (row as DeviceReportItem).manufacturer,
        ),
        ReportColumn(
          label: 'Model',
          value: (Object row) => (row as DeviceReportItem).model,
        ),
        ReportColumn(
          label: 'Serial',
          value: (Object row) => (row as DeviceReportItem).serialNumber ?? '—',
        ),
        ReportColumn(
          label: 'Status',
          value: (Object row) => (row as DeviceReportItem).status.label,
          cell: (BuildContext context, Object row) =>
              DeviceStatusBadge(status: (row as DeviceReportItem).status),
        ),
        ReportColumn(
          label: 'Assigned to',
          value: (Object row) =>
              (row as DeviceReportItem).assignedEmployee?.fullName ?? '—',
        ),
        ReportColumn(
          label: 'Assigned date',
          value: (Object row) {
            final DateTime? date = (row as DeviceReportItem).assignedAt;
            return date == null ? '—' : AppDateFormatter.date(date);
          },
        ),
        ReportColumn(
          label: 'Returned date',
          value: (Object row) {
            final DateTime? date = (row as DeviceReportItem).returnedAt;
            return date == null ? '—' : AppDateFormatter.date(date);
          },
        ),
      ];
  }
}

String _time(DateTime? value) {
  if (value == null) {
    return '—';
  }
  return AppDateFormatter.time(value.toLocal());
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReportAccess access = ReportAccess(
      ref.watch(authorizationProvider),
    );
    final List<_ReportEntry> entries = <_ReportEntry>[
      if (access.canOpen(ReportKind.attendance))
        const _ReportEntry(
          kind: ReportKind.attendance,
          route: AppRoutes.reportsAttendance,
          icon: Icons.schedule_outlined,
          subtitle: 'Check-in, check-out, and working duration.',
        ),
      if (access.canOpen(ReportKind.leaves))
        const _ReportEntry(
          kind: ReportKind.leaves,
          route: AppRoutes.reportsLeaves,
          icon: Icons.event_available_outlined,
          subtitle: 'Leave requests, types, and approvals.',
        ),
      if (access.canOpen(ReportKind.employees))
        const _ReportEntry(
          kind: ReportKind.employees,
          route: AppRoutes.reportsEmployees,
          icon: Icons.groups_outlined,
          subtitle: 'Employee directory without contact fields.',
        ),
      if (access.canOpen(ReportKind.devices))
        const _ReportEntry(
          kind: ReportKind.devices,
          route: AppRoutes.reportsDevices,
          icon: Icons.devices_other_outlined,
          subtitle: 'Assets and current assignments.',
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: entries.isEmpty
          ? const AppEmptyState(
              title: 'No reports available',
              subtitle: 'You do not have access to company reports.',
              icon: Icons.assessment_outlined,
            )
          : ListView.separated(
              padding: AppBreakpoints.pagePadding(context),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final _ReportEntry entry = entries[index];
                return ReportTypeCard(
                  icon: entry.icon,
                  title: entry.kind.title,
                  subtitle: entry.subtitle,
                  onTap: () => context.push(entry.route),
                );
              },
            ),
    );
  }
}

class _ReportEntry {
  const _ReportEntry({
    required this.kind,
    required this.route,
    required this.icon,
    required this.subtitle,
  });

  final ReportKind kind;
  final String route;
  final IconData icon;
  final String subtitle;
}

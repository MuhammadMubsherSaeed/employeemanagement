import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_info_row.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_profile_link.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/documents/domain/document_access.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/documents/presentation/screens/employee_documents_screen.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_error_mapper.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_list_controller.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_profile_photo.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_status_badge.dart';
import 'package:flutter_base/features/employees/presentation/widgets/upcoming_module_placeholder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployeeDetailsScreen extends ConsumerWidget {
  const EmployeeDetailsScreen({
    super.key,
    required this.employeeId,
    this.isSelf = false,
  });

  final String employeeId;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lookup = isSelf ? 'me' : employeeId;
    final AsyncValue<Employee> async = ref.watch(employeeDetailProvider(lookup));
    final EmployeeAccess access = EmployeeAccess(
      ref.watch(authorizationProvider),
    );
    final AttendanceAccess attendance = AttendanceAccess(access.auth);
    final LeaveAccess leave = LeaveAccess(access.auth);
    final DeviceAccess devices = DeviceAccess(access.auth);
    final DocumentAccess documents = DocumentAccess(access.auth);

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Employee')),
        body: const AppLoader(message: 'Loading profile…'),
      ),
      error: (Object error, _) => Scaffold(
        appBar: AppBar(title: const Text('Employee')),
        body: AppErrorWidget(
          message: EmployeeErrorMapper.message(error),
          onRetry: () => ref.invalidate(employeeDetailProvider(lookup)),
        ),
      ),
      data: (Employee employee) {
        final List<Tab> tabs = <Tab>[const Tab(text: 'Overview')];
        final List<Widget> views = <Widget>[
          _OverviewTab(employee: employee, access: documents),
        ];
        if (attendance.canView) {
          tabs.add(const Tab(text: 'Attendance'));
          views.add(
            AttendanceProfileLink(auth: access.auth, isSelf: isSelf),
          );
        }
        if (leave.canView) {
          tabs.add(const Tab(text: 'Leaves'));
          views.add(const UpcomingModulePlaceholder(title: 'Leaves'));
        }
        if (devices.canView) {
          tabs.add(const Tab(text: 'Devices'));
          views.add(const UpcomingModulePlaceholder(title: 'Devices'));
        }
        if (documents.canView) {
          tabs.add(const Tab(text: 'Documents'));
          views.add(
            EmployeeDocumentsScreen(
              employeeId: employee.id,
              embedded: true,
            ),
          );
        }
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isSelf ? 'My profile' : employee.fullName),
              actions: <Widget>[
                if (access.canUpdate && !access.isSelfService)
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () =>
                        context.push(AppRoutes.employeeEdit(employee.id)),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (access.canDelete)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, ref, employee),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
              bottom: TabBar(isScrollable: true, tabs: tabs),
            ),
            body: TabBarView(children: views),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete employee',
      message: 'Delete ${employee.fullName}? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(deleteEmployeeProvider)(employee.id);
      ref.read(employeeListControllerProvider.notifier).removeEmployee(
            employee.id,
          );
      if (context.mounted) {
        context.pop();
      }
    } catch (error) {
      if (context.mounted) {
        context.showSnack(EmployeeErrorMapper.message(error));
      }
    }
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.employee, required this.access});

  final Employee employee;
  final DocumentAccess access;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppBreakpoints.pagePadding(context),
      children: <Widget>[
        AppCard(
          variant: AppCardVariant.elevated,
          child: Row(
            children: <Widget>[
              EmployeeProfilePhoto(
                employee: employee,
                access: access,
                size: AppDimensions.avatarXl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      employee.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      employee.employeeCode,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (employee.position?.title.isNotEmpty == true)
                      Text(
                        employee.position!.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (employee.department?.name.isNotEmpty == true)
                      Text(
                        employee.department!.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    EmployeeStatusBadge(status: employee.status),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Employment information', <AppInfoRow>[
          AppInfoRow(label: 'Employment type', value: employee.employmentType.label),
          AppInfoRow(
            label: 'Joining date',
            value: employee.joiningDate == null
                ? '—'
                : AppDateFormatter.date(employee.joiningDate!),
          ),
          AppInfoRow(
            label: 'Date of birth',
            value: employee.dateOfBirth == null
                ? '—'
                : AppDateFormatter.date(employee.dateOfBirth!),
          ),
          AppInfoRow(label: 'Gender', value: employee.gender.label),
        ]),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Organization', <AppInfoRow>[
          AppInfoRow(label: 'Department', value: employee.department?.name ?? '—'),
          AppInfoRow(label: 'Position', value: employee.position?.title ?? '—'),
          AppInfoRow(label: 'Manager', value: employee.manager?.fullName ?? '—'),
        ]),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Contact information', <AppInfoRow>[
          AppInfoRow(label: 'Email', value: employee.user?.email ?? '—'),
          AppInfoRow(
            label: 'Phone',
            value: employee.phone.isEmpty ? '—' : employee.phone,
          ),
          AppInfoRow(
            label: 'Address',
            value: employee.address.isEmpty ? '—' : employee.address,
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Emergency contact', <AppInfoRow>[
          AppInfoRow(
            label: 'Name',
            value: employee.emergencyContactName.isEmpty
                ? '—'
                : employee.emergencyContactName,
          ),
          AppInfoRow(
            label: 'Relationship',
            value: employee.emergencyContactRelationship.isEmpty
                ? '—'
                : employee.emergencyContactRelationship,
          ),
          AppInfoRow(
            label: 'Phone',
            value: employee.emergencyContactPhone.isEmpty
                ? '—'
                : employee.emergencyContactPhone,
          ),
        ]),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<AppInfoRow> rows) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...rows,
        ],
      ),
    );
  }
}

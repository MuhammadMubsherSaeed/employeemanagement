import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_profile_link.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/documents/domain/document_access.dart';
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
    final AuthState auth = ref.watch(authControllerProvider);
    final EmployeeAccess access = EmployeeAccess(
      auth is AuthAuthenticated ? auth.user.role : UserRole.unknown,
    );

    return async.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (Object error, _) => Scaffold(
        appBar: AppBar(title: const Text('Employee')),
        body: AppErrorWidget(
          message: EmployeeErrorMapper.message(error),
          onRetry: () => ref.invalidate(employeeDetailProvider(lookup)),
        ),
      ),
      data: (Employee employee) {
        return DefaultTabController(
          length: 5,
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
              bottom: const TabBar(
                isScrollable: true,
                tabs: <Widget>[
                  Tab(text: 'Overview'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Leaves'),
                  Tab(text: 'Devices'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                _OverviewTab(
                  employee: employee,
                  access: DocumentAccess(access.role),
                ),
                AttendanceProfileLink(
                  role: access.role,
                  isSelf: isSelf,
                ),
                const UpcomingModulePlaceholder(title: 'Leaves'),
                const UpcomingModulePlaceholder(title: 'Devices'),
                EmployeeDocumentsScreen(
                  employeeId: employee.id,
                  embedded: true,
                ),
              ],
            ),
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
      padding: AppSpacing.screen,
      children: <Widget>[
        AppCard(
          child: Row(
            children: <Widget>[
              EmployeeProfilePhoto(
                employee: employee,
                access: access,
                size: 64,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      employee.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(employee.employeeCode),
                    const SizedBox(height: AppSpacing.xs),
                    EmployeeStatusBadge(status: employee.status),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Employment information', <_Row>[
          _Row('Employment type', employee.employmentType.label),
          _Row(
            'Joining date',
            employee.joiningDate == null
                ? '—'
                : AppDateFormatter.date(employee.joiningDate!),
          ),
          _Row(
            'Date of birth',
            employee.dateOfBirth == null
                ? '—'
                : AppDateFormatter.date(employee.dateOfBirth!),
          ),
          _Row('Gender', employee.gender.label),
        ]),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Organization', <_Row>[
          _Row('Department', employee.department?.name ?? '—'),
          _Row('Position', employee.position?.title ?? '—'),
          _Row('Manager', employee.manager?.fullName ?? '—'),
        ]),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Contact information', <_Row>[
          _Row('Email', employee.user?.email ?? '—'),
          _Row('Phone', employee.phone.isEmpty ? '—' : employee.phone),
          _Row('Address', employee.address.isEmpty ? '—' : employee.address),
        ]),
        const SizedBox(height: AppSpacing.md),
        _section(context, 'Emergency contact', <_Row>[
          _Row(
            'Name',
            employee.emergencyContactName.isEmpty
                ? '—'
                : employee.emergencyContactName,
          ),
          _Row(
            'Relationship',
            employee.emergencyContactRelationship.isEmpty
                ? '—'
                : employee.emergencyContactRelationship,
          ),
          _Row(
            'Phone',
            employee.emergencyContactPhone.isEmpty
                ? '—'
                : employee.emergencyContactPhone,
          ),
        ]),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<_Row> rows) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...rows.map(
            (_Row row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 120,
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Text(row.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

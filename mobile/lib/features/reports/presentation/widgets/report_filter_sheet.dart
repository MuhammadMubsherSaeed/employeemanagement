import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_bottom_sheet.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/presentation/widgets/report_date_range_selector.dart';

Future<ReportQuery?> showReportFilterSheet({
  required BuildContext context,
  required ReportQuery current,
  required bool canFilterByEmployee,
  required bool canFilterByDepartment,
  List<Department> departments = const <Department>[],
  List<Employee> employees = const <Employee>[],
  List<LeaveType> leaveTypes = const <LeaveType>[],
}) {
  return AppBottomSheet.show<ReportQuery>(
    context: context,
    builder: (BuildContext context) {
      return ReportFilterSheet(
        current: current,
        canFilterByEmployee: canFilterByEmployee,
        canFilterByDepartment: canFilterByDepartment,
        departments: departments,
        employees: employees,
        leaveTypes: leaveTypes,
      );
    },
  );
}

class ReportFilterSheet extends StatefulWidget {
  const ReportFilterSheet({
    super.key,
    required this.current,
    required this.canFilterByEmployee,
    required this.canFilterByDepartment,
    this.departments = const <Department>[],
    this.employees = const <Employee>[],
    this.leaveTypes = const <LeaveType>[],
  });

  final ReportQuery current;
  final bool canFilterByEmployee;
  final bool canFilterByDepartment;
  final List<Department> departments;
  final List<Employee> employees;
  final List<LeaveType> leaveTypes;

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late ReportQuery _draft;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
    _search = TextEditingController(text: widget.current.search);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReportKind kind = _draft.kind;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _draft.activeFilterCount == 0
                  ? 'Filters'
                  : 'Filters (${_draft.activeFilterCount})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (kind.supportsDates) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              ReportDateRangeSelector(
                startDate: _draft.dateFrom,
                endDate: _draft.dateTo,
                onChanged: (DateTime? start, DateTime? end) {
                  setState(() {
                    _draft = _draft.copyWith(
                      dateFrom: start,
                      dateTo: end,
                      clearDateFrom: start == null,
                      clearDateTo: end == null,
                    );
                  });
                },
              ),
            ],
            if (widget.canFilterByEmployee) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppDropdown<String?>(
                key: ValueKey<String>('report-employee-${_draft.employeeId}'),
                label: 'Employee',
                value: _draft.employeeId,
                items: <AppDropdownItem<String?>>[
                  const AppDropdownItem<String?>(value: null, label: 'All'),
                  ...widget.employees.map(
                    (Employee employee) => AppDropdownItem<String?>(
                      value: employee.id,
                      label: '${employee.fullName} (${employee.employeeCode})',
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _draft = _draft.copyWith(
                      employeeId: value,
                      clearEmployee: value == null,
                    );
                  });
                },
              ),
            ],
            if (widget.canFilterByDepartment) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppDropdown<String?>(
                key: ValueKey<String>('report-dept-${_draft.departmentId}'),
                label: 'Department',
                value: _draft.departmentId,
                items: <AppDropdownItem<String?>>[
                  const AppDropdownItem<String?>(value: null, label: 'All'),
                  ...widget.departments.map(
                    (Department department) => AppDropdownItem<String?>(
                      value: department.id,
                      label: department.name,
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _draft = _draft.copyWith(
                      departmentId: value,
                      clearDepartment: value == null,
                    );
                  });
                },
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<String?>(
              key: ValueKey<String>('report-status-${_draft.status}'),
              label: 'Status',
              value: _draft.status,
              items: <AppDropdownItem<String?>>[
                const AppDropdownItem<String?>(value: null, label: 'All'),
                ..._statusItems(kind),
              ],
              onChanged: (String? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    status: value,
                    clearStatus: value == null,
                  );
                });
              },
            ),
            if (kind.supportsLeaveType) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppDropdown<String?>(
                key: ValueKey<String>('report-leave-type-${_draft.leaveTypeId}'),
                label: 'Leave type',
                value: _draft.leaveTypeId,
                items: <AppDropdownItem<String?>>[
                  const AppDropdownItem<String?>(value: null, label: 'All'),
                  ...widget.leaveTypes.map(
                    (LeaveType type) => AppDropdownItem<String?>(
                      value: type.id,
                      label: type.name,
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _draft = _draft.copyWith(
                      leaveTypeId: value,
                      clearLeaveType: value == null,
                    );
                  });
                },
              ),
            ],
            if (kind.supportsEmploymentType) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppDropdown<String?>(
                key: ValueKey<String>(
                  'report-employment-${_draft.employmentType}',
                ),
                label: 'Employment type',
                value: _draft.employmentType,
                items: <AppDropdownItem<String?>>[
                  const AppDropdownItem<String?>(value: null, label: 'All'),
                  ...EmploymentType.values
                      .where(
                        (EmploymentType item) =>
                            item != EmploymentType.unknown,
                      )
                      .map(
                        (EmploymentType item) => AppDropdownItem<String?>(
                          value: item.apiValue,
                          label: item.label,
                        ),
                      ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _draft = _draft.copyWith(
                      employmentType: value,
                      clearEmploymentType: value == null,
                    );
                  });
                },
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _search,
              label: 'Search',
              hint: 'Search this report',
              onChanged: (String value) {
                _draft = _draft.copyWith(search: value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Clear',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                setState(() {
                  _draft = _draft.clearedFilters().copyWith(search: '');
                  _search.clear();
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Apply',
              onPressed: () => Navigator.of(context).pop(
                _draft.copyWith(search: _search.text, page: 1),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  List<AppDropdownItem<String?>> _statusItems(ReportKind kind) {
    switch (kind) {
      case ReportKind.attendance:
        return AttendanceStatus.values
            .where((AttendanceStatus item) => item != AttendanceStatus.unknown)
            .map(
              (AttendanceStatus item) => AppDropdownItem<String?>(
                value: item.apiValue,
                label: item.label,
              ),
            )
            .toList();
      case ReportKind.leaves:
        return LeaveRequestStatus.values
            .where(
              (LeaveRequestStatus item) => item != LeaveRequestStatus.unknown,
            )
            .map(
              (LeaveRequestStatus item) => AppDropdownItem<String?>(
                value: item.apiValue,
                label: item.label,
              ),
            )
            .toList();
      case ReportKind.employees:
        return EmployeeStatus.values
            .where((EmployeeStatus item) => item != EmployeeStatus.unknown)
            .map(
              (EmployeeStatus item) => AppDropdownItem<String?>(
                value: item.apiValue,
                label: item.label,
              ),
            )
            .toList();
      case ReportKind.devices:
        return DeviceStatus.values
            .where((DeviceStatus item) => item != DeviceStatus.unknown)
            .map(
              (DeviceStatus item) => AppDropdownItem<String?>(
                value: item.apiValue,
                label: item.label,
              ),
            )
            .toList();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_bottom_sheet.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';

Future<EmployeeQuery?> showEmployeeFilterSheet({
  required BuildContext context,
  required EmployeeQuery current,
  required List<Department> departments,
  required List<Position> positions,
}) {
  return AppBottomSheet.show<EmployeeQuery>(
    context: context,
    builder: (BuildContext context) {
      return EmployeeFilterSheet(
        current: current,
        departments: departments,
        positions: positions,
      );
    },
  );
}

class EmployeeFilterSheet extends StatefulWidget {
  const EmployeeFilterSheet({
    super.key,
    required this.current,
    required this.departments,
    required this.positions,
  });

  final EmployeeQuery current;
  final List<Department> departments;
  final List<Position> positions;

  @override
  State<EmployeeFilterSheet> createState() => _EmployeeFilterSheetState();
}

class _EmployeeFilterSheetState extends State<EmployeeFilterSheet> {
  late EmployeeQuery _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final List<Position> positions = widget.positions
        .where(
          (Position item) =>
              _draft.departmentId == null ||
              item.departmentId == _draft.departmentId,
        )
        .toList();

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
            const SizedBox(height: AppSpacing.md),
            AppDropdown<String?>(
              key: ValueKey<String?>('filter-dept-${_draft.departmentId}'),
              label: 'Department',
              value: _draft.departmentId,
              hint: 'All departments',
              items: <AppDropdownItem<String?>>[
                const AppDropdownItem<String?>(value: null, label: 'All'),
                ...widget.departments.map(
                  (Department item) => AppDropdownItem<String?>(
                    value: item.id,
                    label: item.name,
                  ),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    departmentId: value,
                    clearDepartment: value == null,
                    clearPosition: true,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<String?>(
              key: ValueKey<String?>('filter-pos-${_draft.positionId}'),
              label: 'Position',
              value: _draft.positionId,
              hint: 'All positions',
              items: <AppDropdownItem<String?>>[
                const AppDropdownItem<String?>(value: null, label: 'All'),
                ...positions.map(
                  (Position item) => AppDropdownItem<String?>(
                    value: item.id,
                    label: item.title,
                  ),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    positionId: value,
                    clearPosition: value == null,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<EmployeeStatus?>(
              key: ValueKey<String>('filter-status-${_draft.status}'),
              label: 'Status',
              value: _draft.status,
              items: <AppDropdownItem<EmployeeStatus?>>[
                const AppDropdownItem<EmployeeStatus?>(
                  value: null,
                  label: 'All',
                ),
                ...EmployeeStatus.values
                    .where((EmployeeStatus item) => item != EmployeeStatus.unknown)
                    .map(
                      (EmployeeStatus item) => AppDropdownItem<EmployeeStatus?>(
                        value: item,
                        label: item.label,
                      ),
                    ),
              ],
              onChanged: (EmployeeStatus? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    status: value,
                    clearStatus: value == null,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<EmploymentType?>(
              key: ValueKey<String>(
                'filter-type-${_draft.employmentType}',
              ),
              label: 'Employment type',
              value: _draft.employmentType,
              items: <AppDropdownItem<EmploymentType?>>[
                const AppDropdownItem<EmploymentType?>(
                  value: null,
                  label: 'All',
                ),
                ...EmploymentType.values
                    .where(
                      (EmploymentType item) => item != EmploymentType.unknown,
                    )
                    .map(
                      (EmploymentType item) => AppDropdownItem<EmploymentType?>(
                        value: item,
                        label: item.label,
                      ),
                    ),
              ],
              onChanged: (EmploymentType? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    employmentType: value,
                    clearEmploymentType: value == null,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Clear all',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                setState(() {
                  _draft = _draft.clearedFilters();
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Apply',
              onPressed: () => Navigator.of(context).pop(_draft.copyWith(page: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

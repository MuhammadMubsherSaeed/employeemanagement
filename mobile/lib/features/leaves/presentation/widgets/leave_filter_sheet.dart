import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_bottom_sheet.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';

Future<LeaveRequestQuery?> showLeaveFilterSheet({
  required BuildContext context,
  required LeaveRequestQuery current,
  required List<LeaveType> leaveTypes,
  required bool canFilterByEmployee,
}) {
  return AppBottomSheet.show<LeaveRequestQuery>(
    context: context,
    builder: (BuildContext context) {
      return LeaveFilterSheet(
        current: current,
        leaveTypes: leaveTypes,
        canFilterByEmployee: canFilterByEmployee,
      );
    },
  );
}

class LeaveFilterSheet extends StatefulWidget {
  const LeaveFilterSheet({
    super.key,
    required this.current,
    required this.leaveTypes,
    required this.canFilterByEmployee,
  });

  final LeaveRequestQuery current;
  final List<LeaveType> leaveTypes;
  final bool canFilterByEmployee;

  @override
  State<LeaveFilterSheet> createState() => _LeaveFilterSheetState();
}

class _LeaveFilterSheetState extends State<LeaveFilterSheet> {
  late LeaveRequestQuery _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  Future<void> _pick({required bool start}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = start
        ? (_draft.startDate ?? now)
        : (_draft.endDate ?? now);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _draft = start
          ? _draft.copyWith(startDate: picked)
          : _draft.copyWith(endDate: picked);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            AppDropdown<LeaveRequestStatus?>(
              key: ValueKey<String>('leave-status-${_draft.status}'),
              label: 'Status',
              value: _draft.status,
              items: <AppDropdownItem<LeaveRequestStatus?>>[
                const AppDropdownItem<LeaveRequestStatus?>(
                  value: null,
                  label: 'All',
                ),
                ...LeaveRequestStatus.values
                    .where(
                      (LeaveRequestStatus item) =>
                          item != LeaveRequestStatus.unknown,
                    )
                    .map(
                      (LeaveRequestStatus item) =>
                          AppDropdownItem<LeaveRequestStatus?>(
                        value: item,
                        label: item.label,
                      ),
                    ),
              ],
              onChanged: (LeaveRequestStatus? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    status: value,
                    clearStatus: value == null,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<String?>(
              key: ValueKey<String>('leave-type-filter-${_draft.leaveTypeId}'),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(
                _draft.startDate == null
                    ? 'Any'
                    : AppDateFormatter.date(_draft.startDate!),
              ),
              onTap: () => _pick(start: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date'),
              subtitle: Text(
                _draft.endDate == null
                    ? 'Any'
                    : AppDateFormatter.date(_draft.endDate!),
              ),
              onTap: () => _pick(start: false),
            ),
            if (widget.canFilterByEmployee) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Results include leave requests your role is authorized to view. Employees cannot be selected here.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
              onPressed: () =>
                  Navigator.of(context).pop(_draft.copyWith(page: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

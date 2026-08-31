import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';

Future<AttendanceQuery?> showAttendanceFilterSheet({
  required BuildContext context,
  required AttendanceQuery current,
  required bool canFilterByEmployee,
}) {
  return showModalBottomSheet<AttendanceQuery>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return AttendanceFilterSheet(
        current: current,
        canFilterByEmployee: canFilterByEmployee,
      );
    },
  );
}

class AttendanceFilterSheet extends StatefulWidget {
  const AttendanceFilterSheet({
    super.key,
    required this.current,
    required this.canFilterByEmployee,
  });

  final AttendanceQuery current;
  final bool canFilterByEmployee;

  @override
  State<AttendanceFilterSheet> createState() => _AttendanceFilterSheetState();
}

class _AttendanceFilterSheetState extends State<AttendanceFilterSheet> {
  late AttendanceQuery _draft;

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
      lastDate: DateTime(now.year, now.month, now.day),
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
            AppDropdown<AttendanceStatus?>(
              key: ValueKey<String>('att-status-${_draft.status}'),
              label: 'Status',
              value: _draft.status,
              items: <AppDropdownItem<AttendanceStatus?>>[
                const AppDropdownItem<AttendanceStatus?>(
                  value: null,
                  label: 'All',
                ),
                ...AttendanceStatus.values
                    .where(
                      (AttendanceStatus item) =>
                          item != AttendanceStatus.unknown,
                    )
                    .map(
                      (AttendanceStatus item) =>
                          AppDropdownItem<AttendanceStatus?>(
                        value: item,
                        label: item.label,
                      ),
                    ),
              ],
              onChanged: (AttendanceStatus? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    status: value,
                    clearStatus: value == null,
                  );
                });
              },
            ),
            if (widget.canFilterByEmployee) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Results include attendance your role is authorized to view. Employees cannot be selected here.',
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

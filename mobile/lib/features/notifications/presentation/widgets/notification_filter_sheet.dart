import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_bottom_sheet.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';

Future<NotificationQuery?> showNotificationFilterSheet({
  required BuildContext context,
  required NotificationQuery current,
}) {
  return AppBottomSheet.show<NotificationQuery>(
    context: context,
    builder: (BuildContext context) {
      return NotificationFilterSheet(current: current);
    },
  );
}

class NotificationFilterSheet extends StatefulWidget {
  const NotificationFilterSheet({
    super.key,
    required this.current,
  });

  final NotificationQuery current;

  @override
  State<NotificationFilterSheet> createState() =>
      _NotificationFilterSheetState();
}

class _NotificationFilterSheetState extends State<NotificationFilterSheet> {
  late NotificationQuery _draft;

  static const List<AppNotificationType> _types = <AppNotificationType>[
    AppNotificationType.leaveSubmitted,
    AppNotificationType.leaveApproved,
    AppNotificationType.leaveRejected,
    AppNotificationType.leaveCancelled,
    AppNotificationType.deviceAssigned,
    AppNotificationType.deviceReturned,
    AppNotificationType.attendanceReminder,
    AppNotificationType.attendanceLate,
    AppNotificationType.documentExpiring,
    AppNotificationType.system,
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  Future<void> _pickDate({required bool after}) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: after
          ? (_draft.createdAtAfter ?? now)
          : (_draft.createdAtBefore ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _draft = after
          ? _draft.copyWith(createdAtAfter: picked)
          : _draft.copyWith(
              createdAtBefore: DateTime(
                picked.year,
                picked.month,
                picked.day,
                23,
                59,
                59,
              ),
            );
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
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<AppNotificationType?>(
              label: 'Type',
              hint: 'Any type',
              value: _draft.type,
              items: <AppDropdownItem<AppNotificationType?>>[
                const AppDropdownItem<AppNotificationType?>(
                  value: null,
                  label: 'Any type',
                ),
                ..._types.map(
                  (AppNotificationType type) => AppDropdownItem<AppNotificationType?>(
                    value: type,
                    label: type.label,
                  ),
                ),
              ],
              onChanged: (AppNotificationType? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    type: value,
                    clearType: value == null,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: _draft.createdAtAfter == null
                  ? 'From date'
                  : 'From ${_draft.createdAtAfter!.toIso8601String().substring(0, 10)}',
              variant: AppButtonVariant.outlined,
              onPressed: () => _pickDate(after: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: _draft.createdAtBefore == null
                  ? 'To date'
                  : 'To ${_draft.createdAtBefore!.toIso8601String().substring(0, 10)}',
              variant: AppButtonVariant.outlined,
              onPressed: () => _pickDate(after: false),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Apply filters',
              onPressed: () => Navigator.of(context).pop(_draft.copyWith(page: 1)),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Clear filters',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(
                widget.current.clearedFilters().copyWith(
                      isRead: widget.current.isRead,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

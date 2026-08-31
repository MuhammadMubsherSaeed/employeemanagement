import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveTypeSelector extends ConsumerWidget {
  const LeaveTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LeaveType>> async =
        ref.watch(activeLeaveTypesProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: AppLoader(message: 'Loading leave types…'),
      ),
      error: (Object error, _) => AppErrorWidget(
        message: LeaveErrorMapper.message(error),
        onRetry: () => ref.invalidate(activeLeaveTypesProvider),
      ),
      data: (List<LeaveType> types) {
        if (types.isEmpty) {
          return Text(
            'No leave types available.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return AppDropdown<String>(
          key: ValueKey<String>('leave-type-${value ?? 'none'}'),
          label: 'Leave type',
          value: value,
          enabled: enabled,
          errorText: errorText,
          items: types
              .map(
                (LeaveType type) => AppDropdownItem<String>(
                  value: type.id,
                  label: type.name,
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/presentation/providers/apply_leave_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/apply_leave_state.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/date_range_selector.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_type_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    _reason = TextEditingController(
      text: ref.read(applyLeaveControllerProvider).reason,
    );
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final String? error =
        await ref.read(applyLeaveControllerProvider.notifier).pickAttachment();
    if (!mounted) {
      return;
    }
    if (error != null) {
      context.showSnack(error);
    }
  }

  Future<void> _submit() async {
    final LeaveRequest? created =
        await ref.read(applyLeaveControllerProvider.notifier).submit();
    if (!mounted) {
      return;
    }
    if (created != null) {
      context.showSnack('Leave request submitted successfully.');
      context.go(AppRoutes.leavesRequests);
      return;
    }
    final String? error = ref.read(applyLeaveControllerProvider).error;
    if (error != null) {
      context.showSnack(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ApplyLeaveState state = ref.watch(applyLeaveControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for leave')),
      body: ListView(
        padding: AppSpacing.screen,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          LeaveTypeSelector(
            value: state.leaveTypeId,
            enabled: !state.isSubmitting,
            errorText: state.fieldErrors['leave_type'],
            onChanged: (String? id) =>
                ref.read(applyLeaveControllerProvider.notifier).setLeaveType(id),
          ),
          const SizedBox(height: AppSpacing.md),
          DateRangeSelector(
            startDate: state.startDate,
            endDate: state.endDate,
            enabled: !state.isSubmitting,
            startError: state.fieldErrors['start_date'],
            endError: state.fieldErrors['end_date'],
            onChanged: (DateTime? start, DateTime? end) {
              ref.read(applyLeaveControllerProvider.notifier).setRange(
                    start: start,
                    end: end,
                  );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _reason,
            label: 'Reason',
            maxLines: 4,
            enabled: !state.isSubmitting,
            errorText: state.fieldErrors['reason'],
            onChanged: (String value) =>
                ref.read(applyLeaveControllerProvider.notifier).setReason(value),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.attachment != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(state.attachment!.name),
              subtitle: const Text('Attachment selected'),
              trailing: IconButton(
                tooltip: 'Remove attachment',
                onPressed: state.isSubmitting
                    ? null
                    : () => ref
                        .read(applyLeaveControllerProvider.notifier)
                        .clearAttachment(),
                icon: const Icon(Icons.close),
              ),
            )
          else
            AppButton(
              label: 'Add attachment',
              variant: AppButtonVariant.outlined,
              onPressed: state.isSubmitting ? null : _pickFile,
            ),
          if (state.fieldErrors['attachment'] != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              state.fieldErrors['attachment']!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Submit',
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

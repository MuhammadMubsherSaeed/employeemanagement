import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_invalidation.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_picker.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_requests_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/apply_leave_state.dart';
import 'package:flutter_base/features/leaves/presentation/states/leave_requests_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kLeaveReasonMaxLength = 1000;

class ApplyLeaveController extends Notifier<ApplyLeaveState> {
  @override
  ApplyLeaveState build() {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      state = const ApplyLeaveState();
    });
    return const ApplyLeaveState();
  }

  void setLeaveType(String? id) {
    state = state.copyWith(
      leaveTypeId: id,
      clearLeaveType: id == null,
      fieldErrors: Map<String, String>.from(state.fieldErrors)
        ..remove('leave_type'),
    );
  }

  void setRange({DateTime? start, DateTime? end}) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      clearStart: start == null,
      clearEnd: end == null,
      fieldErrors: Map<String, String>.from(state.fieldErrors)
        ..remove('start_date')
        ..remove('end_date'),
    );
  }

  void setReason(String value) {
    state = state.copyWith(
      reason: value,
      fieldErrors: Map<String, String>.from(state.fieldErrors)..remove('reason'),
    );
  }

  Future<String?> pickAttachment() async {
    final LeaveAttachmentFile? file =
        await ref.read(leaveAttachmentPickerProvider).pick();
    if (file == null) {
      return null;
    }
    final String? error = validateLeaveAttachment(file);
    if (error != null) {
      return error;
    }
    state = state.copyWith(
      attachment: file,
      fieldErrors: Map<String, String>.from(state.fieldErrors)
        ..remove('attachment'),
    );
    return null;
  }

  void clearAttachment() {
    state = state.copyWith(clearAttachment: true);
  }

  void reset() {
    state = const ApplyLeaveState();
  }

  Map<String, String> validateLocal() {
    final Map<String, String> errors = <String, String>{};
    if (state.leaveTypeId == null || state.leaveTypeId!.isEmpty) {
      errors['leave_type'] = 'Select a leave type.';
    }
    if (state.startDate == null) {
      errors['start_date'] = 'Select a start date.';
    }
    if (state.endDate == null) {
      errors['end_date'] = 'Select an end date.';
    }
    if (state.startDate != null &&
        state.endDate != null &&
        state.endDate!.isBefore(state.startDate!)) {
      errors['end_date'] = 'End date must not be before start date.';
    }
    final String reason = state.reason.trim();
    if (reason.isEmpty) {
      errors['reason'] = 'Enter a reason.';
    } else if (reason.length > kLeaveReasonMaxLength) {
      errors['reason'] = 'Reason is too long.';
    }
    return errors;
  }

  Future<LeaveRequest?> submit() async {
    if (state.isSubmitting) {
      return null;
    }
    final Map<String, String> local = validateLocal();
    if (local.isNotEmpty) {
      state = state.copyWith(fieldErrors: local, clearError: true);
      return null;
    }
    state = state.copyWith(
      isSubmitting: true,
      fieldErrors: const <String, String>{},
      clearError: true,
    );
    try {
      final LeaveRequest created =
          await ref.read(createLeaveRequestUseCaseProvider)(
        CreateLeaveRequestBody(
          leaveTypeId: state.leaveTypeId!,
          startDate: state.startDate!,
          endDate: state.endDate!,
          reason: state.reason.trim(),
          attachment: state.attachment,
        ),
      );
      state = const ApplyLeaveState();
      ref.invalidate(leaveBalancesProvider);
      ref.invalidate(leaveRequestDetailProvider);
      invalidateDashboardProviders(ref);
      await ref
          .read(leaveRequestsControllerProvider(LeaveListKind.all).notifier)
          .refresh();
      await ref
          .read(leaveRequestsControllerProvider(LeaveListKind.history).notifier)
          .refresh();
      return created;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        fieldErrors: LeaveErrorMapper.fieldErrors(error),
        error: LeaveErrorMapper.message(error),
      );
      return null;
    }
  }
}

final applyLeaveControllerProvider =
    NotifierProvider<ApplyLeaveController, ApplyLeaveState>(
  ApplyLeaveController.new,
);

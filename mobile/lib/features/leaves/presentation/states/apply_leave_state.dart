import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';

class ApplyLeaveState extends Equatable {
  const ApplyLeaveState({
    this.leaveTypeId,
    this.startDate,
    this.endDate,
    this.reason = '',
    this.attachment,
    this.isSubmitting = false,
    this.fieldErrors = const <String, String>{},
    this.error,
  });

  final String? leaveTypeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String reason;
  final LeaveAttachmentFile? attachment;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final String? error;

  ApplyLeaveState copyWith({
    String? leaveTypeId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    LeaveAttachmentFile? attachment,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? error,
    bool clearLeaveType = false,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearAttachment = false,
    bool clearError = false,
  }) {
    return ApplyLeaveState(
      leaveTypeId: clearLeaveType ? null : (leaveTypeId ?? this.leaveTypeId),
      startDate: clearStart ? null : (startDate ?? this.startDate),
      endDate: clearEnd ? null : (endDate ?? this.endDate),
      reason: reason ?? this.reason,
      attachment: clearAttachment ? null : (attachment ?? this.attachment),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        leaveTypeId,
        startDate,
        endDate,
        reason,
        attachment,
        isSubmitting,
        fieldErrors,
        error,
      ];
}

class LeaveActionState extends Equatable {
  const LeaveActionState({
    this.isApproving = false,
    this.isRejecting = false,
    this.isCancelling = false,
    this.isAllocating = false,
    this.error,
  });

  final bool isApproving;
  final bool isRejecting;
  final bool isCancelling;
  final bool isAllocating;
  final String? error;

  bool get isBusy =>
      isApproving || isRejecting || isCancelling || isAllocating;

  LeaveActionState copyWith({
    bool? isApproving,
    bool? isRejecting,
    bool? isCancelling,
    bool? isAllocating,
    String? error,
    bool clearError = false,
  }) {
    return LeaveActionState(
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
      isCancelling: isCancelling ?? this.isCancelling,
      isAllocating: isAllocating ?? this.isAllocating,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[isApproving, isRejecting, isCancelling, isAllocating, error];
}

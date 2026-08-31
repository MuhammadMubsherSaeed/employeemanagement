import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_requests_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/apply_leave_state.dart';
import 'package:flutter_base/features/leaves/presentation/states/leave_requests_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kLeaveRejectionMinLength = 3;
const int kLeaveRejectionMaxLength = 500;

class LeaveActionController extends Notifier<LeaveActionState> {
  @override
  LeaveActionState build() => const LeaveActionState();

  Future<LeaveRequest?> approve(String id) async {
    if (state.isBusy) {
      return null;
    }
    state = state.copyWith(isApproving: true, clearError: true);
    try {
      final LeaveRequest result =
          await ref.read(approveLeaveRequestUseCaseProvider)(id);
      state = const LeaveActionState();
      _refresh(id, result);
      return result;
    } catch (error) {
      state = state.copyWith(
        isApproving: false,
        error: LeaveErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<LeaveRequest?> reject({
    required String id,
    required String rejectionReason,
  }) async {
    if (state.isBusy) {
      return null;
    }
    final String reason = rejectionReason.trim();
    if (reason.length < kLeaveRejectionMinLength) {
      state = state.copyWith(error: 'Enter a meaningful rejection reason.');
      return null;
    }
    if (reason.length > kLeaveRejectionMaxLength) {
      state = state.copyWith(error: 'Rejection reason is too long.');
      return null;
    }
    state = state.copyWith(isRejecting: true, clearError: true);
    try {
      final LeaveRequest result =
          await ref.read(rejectLeaveRequestUseCaseProvider)(
        id: id,
        rejectionReason: reason,
      );
      state = const LeaveActionState();
      _refresh(id, result);
      return result;
    } catch (error) {
      state = state.copyWith(
        isRejecting: false,
        error: LeaveErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<LeaveRequest?> cancel(String id) async {
    if (state.isBusy) {
      return null;
    }
    state = state.copyWith(isCancelling: true, clearError: true);
    try {
      final LeaveRequest result =
          await ref.read(cancelLeaveRequestUseCaseProvider)(id);
      state = const LeaveActionState();
      _refresh(id, result);
      return result;
    } catch (error) {
      state = state.copyWith(
        isCancelling: false,
        error: LeaveErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<LeaveBalance?> allocate({
    required String id,
    required int allocatedDays,
  }) async {
    if (state.isBusy) {
      return null;
    }
    if (allocatedDays < 0) {
      state = state.copyWith(error: 'Allocated days cannot be negative.');
      return null;
    }
    state = state.copyWith(isAllocating: true, clearError: true);
    try {
      final LeaveBalance result =
          await ref.read(allocateLeaveBalanceUseCaseProvider)(
        id: id,
        allocatedDays: allocatedDays,
      );
      state = const LeaveActionState();
      ref.invalidate(leaveBalancesProvider);
      return result;
    } catch (error) {
      state = state.copyWith(
        isAllocating: false,
        error: LeaveErrorMapper.message(error),
      );
      return null;
    }
  }

  void _refresh(String id, LeaveRequest result) {
    ref.invalidate(leaveRequestDetailProvider(id));
    ref.invalidate(leaveBalancesProvider);
    for (final LeaveListKind kind in LeaveListKind.values) {
      ref
          .read(leaveRequestsControllerProvider(kind).notifier)
          .replaceRequest(result);
      ref.read(leaveRequestsControllerProvider(kind).notifier).refresh();
    }
  }
}

final leaveActionControllerProvider =
    NotifierProvider<LeaveActionController, LeaveActionState>(
  LeaveActionController.new,
);

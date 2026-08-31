import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/states/apply_leave_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveTypeFormController extends Notifier<LeaveActionState> {
  @override
  LeaveActionState build() => const LeaveActionState();

  Map<String, String> validate(LeaveTypeWrite body) {
    final Map<String, String> errors = <String, String>{};
    if (body.name.trim().length < 2) {
      errors['name'] = 'Enter a leave type name.';
    }
    if (body.code.trim().isEmpty) {
      errors['code'] = 'Enter a leave type code.';
    }
    if (body.daysAllowed < 0) {
      errors['days_allowed'] = 'Days allowed cannot be negative.';
    }
    return errors;
  }

  Future<LeaveType?> create(LeaveTypeWrite body) async {
    if (state.isBusy) {
      return null;
    }
    final Map<String, String> local = validate(body);
    if (local.isNotEmpty) {
      state = state.copyWith(error: local.values.first);
      return null;
    }
    state = state.copyWith(isApproving: true, clearError: true);
    try {
      final LeaveType created = await ref.read(createLeaveTypeUseCaseProvider)(
        body.copyWith(code: body.code.trim().toUpperCase()),
      );
      state = const LeaveActionState();
      ref.invalidate(leaveTypesProvider);
      ref.invalidate(activeLeaveTypesProvider);
      return created;
    } catch (error) {
      state = state.copyWith(
        isApproving: false,
        error: LeaveErrorMapper.message(error),
      );
      return null;
    }
  }

  Future<LeaveType?> update(String id, LeaveTypeWrite body) async {
    if (state.isBusy) {
      return null;
    }
    final Map<String, String> local = validate(body);
    if (local.isNotEmpty) {
      state = state.copyWith(error: local.values.first);
      return null;
    }
    state = state.copyWith(isApproving: true, clearError: true);
    try {
      final LeaveType updated = await ref.read(updateLeaveTypeUseCaseProvider)(
        id,
        body.copyWith(code: body.code.trim().toUpperCase()),
      );
      state = const LeaveActionState();
      ref.invalidate(leaveTypesProvider);
      ref.invalidate(activeLeaveTypesProvider);
      ref.invalidate(leaveTypeDetailProvider(id));
      return updated;
    } catch (error) {
      state = state.copyWith(
        isApproving: false,
        error: LeaveErrorMapper.message(error),
      );
      return null;
    }
  }
}

final leaveTypeFormControllerProvider =
    NotifierProvider<LeaveTypeFormController, LeaveActionState>(
  LeaveTypeFormController.new,
);

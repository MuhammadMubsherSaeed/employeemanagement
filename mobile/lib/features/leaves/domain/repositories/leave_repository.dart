import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';

abstract class LeaveRepository {
  Future<LeavePage<LeaveType>> getLeaveTypes(LeaveTypeQuery query);

  Future<LeaveType> getLeaveType(String id);

  Future<LeaveType> createLeaveType(LeaveTypeWrite body);

  Future<LeaveType> updateLeaveType(String id, LeaveTypeWrite body);

  Future<LeavePage<LeaveBalance>> getLeaveBalances(LeaveBalanceQuery query);

  Future<LeaveBalance> allocateLeaveBalance({
    required String id,
    required int allocatedDays,
  });

  Future<LeavePage<LeaveRequest>> getLeaveRequests(LeaveRequestQuery query);

  Future<LeaveRequest> getLeaveRequestDetails(String id);

  Future<LeaveRequest> createLeaveRequest(CreateLeaveRequestBody body);

  Future<LeaveRequest> approveLeaveRequest(String id);

  Future<LeaveRequest> rejectLeaveRequest({
    required String id,
    required String rejectionReason,
  });

  Future<LeaveRequest> cancelLeaveRequest(String id);
}

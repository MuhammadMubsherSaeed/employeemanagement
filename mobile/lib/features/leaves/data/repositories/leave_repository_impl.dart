import 'package:flutter_base/features/leaves/data/datasources/leave_remote_datasource.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/repositories/leave_repository.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  LeaveRepositoryImpl(this._remote);

  final LeaveRemoteDataSource _remote;

  @override
  Future<LeavePage<LeaveType>> getLeaveTypes(LeaveTypeQuery query) {
    return _remote.getLeaveTypes(query);
  }

  @override
  Future<LeaveType> getLeaveType(String id) {
    return _remote.getLeaveType(id);
  }

  @override
  Future<LeaveType> createLeaveType(LeaveTypeWrite body) {
    return _remote.createLeaveType(body);
  }

  @override
  Future<LeaveType> updateLeaveType(String id, LeaveTypeWrite body) {
    return _remote.updateLeaveType(id, body);
  }

  @override
  Future<LeavePage<LeaveBalance>> getLeaveBalances(LeaveBalanceQuery query) {
    return _remote.getLeaveBalances(query);
  }

  @override
  Future<LeaveBalance> allocateLeaveBalance({
    required String id,
    required int allocatedDays,
  }) {
    return _remote.allocateLeaveBalance(id: id, allocatedDays: allocatedDays);
  }

  @override
  Future<LeavePage<LeaveRequest>> getLeaveRequests(LeaveRequestQuery query) {
    return _remote.getLeaveRequests(query);
  }

  @override
  Future<LeaveRequest> getLeaveRequestDetails(String id) {
    return _remote.getLeaveRequest(id);
  }

  @override
  Future<LeaveRequest> createLeaveRequest(CreateLeaveRequestBody body) {
    return _remote.createLeaveRequest(body);
  }

  @override
  Future<LeaveRequest> approveLeaveRequest(String id) {
    return _remote.approveLeaveRequest(id);
  }

  @override
  Future<LeaveRequest> rejectLeaveRequest({
    required String id,
    required String rejectionReason,
  }) {
    return _remote.rejectLeaveRequest(
      id: id,
      rejectionReason: rejectionReason,
    );
  }

  @override
  Future<LeaveRequest> cancelLeaveRequest(String id) {
    return _remote.cancelLeaveRequest(id);
  }
}

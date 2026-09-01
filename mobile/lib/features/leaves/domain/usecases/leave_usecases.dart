import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/repositories/leave_repository.dart';

class GetLeaveTypes {
  const GetLeaveTypes(this._repository);

  final LeaveRepository _repository;

  Future<LeavePage<LeaveType>> call({bool activeOnly = false}) {
    return _repository.getLeaveTypes(
      LeaveTypeQuery(
        status: activeOnly ? LeaveTypeStatus.active : null,
      ),
    );
  }
}

class GetLeaveType {
  const GetLeaveType(this._repository);

  final LeaveRepository _repository;

  Future<LeaveType> call(String id) {
    return _repository.getLeaveType(id);
  }
}

class GetLeaveBalances {
  const GetLeaveBalances(this._repository);

  final LeaveRepository _repository;

  Future<LeavePage<LeaveBalance>> call([LeaveBalanceQuery query = const LeaveBalanceQuery()]) {
    return _repository.getLeaveBalances(query);
  }
}

class GetLeaveRequests {
  const GetLeaveRequests(this._repository);

  final LeaveRepository _repository;

  Future<LeavePage<LeaveRequest>> call(LeaveRequestQuery query) {
    return _repository.getLeaveRequests(query);
  }
}

class GetLeaveRequestDetails {
  const GetLeaveRequestDetails(this._repository);

  final LeaveRepository _repository;

  Future<LeaveRequest> call(String id) {
    return _repository.getLeaveRequestDetails(id);
  }
}

class CreateLeaveRequest {
  const CreateLeaveRequest(this._repository);

  final LeaveRepository _repository;

  Future<LeaveRequest> call(CreateLeaveRequestBody body) {
    return _repository.createLeaveRequest(body);
  }
}

class ApproveLeaveRequest {
  const ApproveLeaveRequest(this._repository);

  final LeaveRepository _repository;

  Future<LeaveRequest> call(String id) {
    return _repository.approveLeaveRequest(id);
  }
}

class RejectLeaveRequest {
  const RejectLeaveRequest(this._repository);

  final LeaveRepository _repository;

  Future<LeaveRequest> call({
    required String id,
    required String rejectionReason,
  }) {
    return _repository.rejectLeaveRequest(
      id: id,
      rejectionReason: rejectionReason,
    );
  }
}

class CancelLeaveRequest {
  const CancelLeaveRequest(this._repository);

  final LeaveRepository _repository;

  Future<LeaveRequest> call(String id) {
    return _repository.cancelLeaveRequest(id);
  }
}

class DownloadLeaveAttachment {
  const DownloadLeaveAttachment(this._repository);

  final LeaveRepository _repository;

  Future<DownloadedBytes> call(String id) {
    return _repository.downloadLeaveAttachment(id);
  }
}

class CreateLeaveType {
  const CreateLeaveType(this._repository);

  final LeaveRepository _repository;

  Future<LeaveType> call(LeaveTypeWrite body) {
    return _repository.createLeaveType(body);
  }
}

class UpdateLeaveType {
  const UpdateLeaveType(this._repository);

  final LeaveRepository _repository;

  Future<LeaveType> call(String id, LeaveTypeWrite body) {
    return _repository.updateLeaveType(id, body);
  }
}

class AllocateLeaveBalance {
  const AllocateLeaveBalance(this._repository);

  final LeaveRepository _repository;

  Future<LeaveBalance> call({
    required String id,
    required int allocatedDays,
  }) {
    return _repository.allocateLeaveBalance(
      id: id,
      allocatedDays: allocatedDays,
    );
  }
}

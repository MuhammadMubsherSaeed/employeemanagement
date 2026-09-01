import 'package:flutter_base/features/documents/domain/entities/document.dart';
import 'package:flutter_base/features/leaves/data/datasources/leave_remote_datasource.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/repositories/leave_repository.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_picker.dart';

LeaveType sampleLeaveType({
  String id = 'type-1',
  String name = 'Annual Leave',
  String code = 'ANNUAL',
  int daysAllowed = 15,
  bool isPaid = true,
  bool carryForward = false,
  LeaveTypeStatus status = LeaveTypeStatus.active,
}) {
  return LeaveType(
    id: id,
    name: name,
    code: code,
    daysAllowed: daysAllowed,
    isPaid: isPaid,
    carryForward: carryForward,
    status: status,
    createdAt: DateTime.parse('2026-01-01T08:00:00Z'),
    updatedAt: DateTime.parse('2026-01-01T08:00:00Z'),
  );
}

LeaveBalance sampleLeaveBalance({
  String id = 'bal-1',
  int year = 2026,
  int allocatedDays = 15,
  int usedDays = 3,
  int remainingDays = 12,
  LeaveType? leaveType,
}) {
  return LeaveBalance(
    id: id,
    employee: const LeaveEmployeeRef(
      id: 'emp-1',
      employeeCode: 'EMP-001',
      firstName: 'Ada',
      lastName: 'Lovelace',
    ),
    leaveType: leaveType ?? sampleLeaveType(),
    year: year,
    allocatedDays: allocatedDays,
    usedDays: usedDays,
    remainingDays: remainingDays,
    createdAt: DateTime.parse('2026-01-01T08:00:00Z'),
  );
}

LeaveRequest sampleLeaveRequest({
  String id = 'req-1',
  LeaveRequestStatus status = LeaveRequestStatus.pending,
  int totalDays = 3,
  String reason = 'Family event',
  String? attachment,
  int? approvedBy,
  DateTime? approvedAt,
  String rejectionReason = '',
  LeaveType? leaveType,
}) {
  return LeaveRequest(
    id: id,
    employee: const LeaveEmployeeRef(
      id: 'emp-1',
      employeeCode: 'EMP-001',
      firstName: 'Ada',
      lastName: 'Lovelace',
    ),
    leaveType: leaveType ?? sampleLeaveType(),
    startDate: DateTime(2026, 8, 15),
    endDate: DateTime(2026, 8, 18),
    totalDays: totalDays,
    status: status,
    reason: reason,
    attachment: attachment,
    approvedBy: approvedBy,
    approvedAt: approvedAt,
    rejectionReason: rejectionReason,
    createdAt: DateTime.parse('2026-08-01T08:00:00Z'),
    updatedAt: DateTime.parse('2026-08-01T08:00:00Z'),
  );
}

Map<String, dynamic> sampleLeaveTypeJson({
  String id = 'type-1',
  String name = 'Annual Leave',
  String code = 'ANNUAL',
  String status = 'ACTIVE',
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'code': code,
    'days_allowed': 15,
    'is_paid': true,
    'carry_forward': false,
    'status': status,
    'created_at': '2026-01-01T08:00:00Z',
    'updated_at': '2026-01-01T08:00:00Z',
  };
}

Map<String, dynamic> sampleLeaveBalanceJson({
  String id = 'bal-1',
  int remainingDays = 12,
  int usedDays = 3,
  int allocatedDays = 15,
}) {
  return <String, dynamic>{
    'id': id,
    'employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
    },
    'leave_type': sampleLeaveTypeJson(),
    'year': 2026,
    'allocated_days': allocatedDays,
    'used_days': usedDays,
    'remaining_days': remainingDays,
    'created_at': '2026-01-01T08:00:00Z',
    'updated_at': '2026-01-01T08:00:00Z',
  };
}

Map<String, dynamic> sampleLeaveRequestJson({
  String id = 'req-1',
  String status = 'PENDING',
  bool detail = false,
  String? attachment,
}) {
  final Map<String, dynamic> json = <String, dynamic>{
    'id': id,
    'employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
    },
    'leave_type': sampleLeaveTypeJson(),
    'start_date': '2026-08-15',
    'end_date': '2026-08-18',
    'total_days': 3,
    'status': status,
    'created_at': '2026-08-01T08:00:00Z',
  };
  if (detail) {
    json.addAll(<String, dynamic>{
      'reason': 'Family event',
      'attachment': attachment,
      'approved_by': status == 'APPROVED' ? 11 : null,
      'approved_at':
          status == 'APPROVED' ? '2026-08-02T09:00:00Z' : null,
      'rejection_reason': status == 'REJECTED' ? 'Coverage needed' : '',
      'updated_at': '2026-08-02T09:00:00Z',
    });
  }
  return json;
}

class FakeLeaveAttachmentPicker implements LeaveAttachmentPicker {
  FakeLeaveAttachmentPicker({this.file});

  LeaveAttachmentFile? file;
  int pickCalls = 0;

  @override
  Future<LeaveAttachmentFile?> pick() async {
    pickCalls += 1;
    return file;
  }
}

class FakeLeaveRepository implements LeaveRepository {
  FakeLeaveRepository({
    List<LeaveType>? types,
    List<LeaveBalance>? balances,
    List<LeaveRequest>? requests,
  })  : types = types ?? <LeaveType>[sampleLeaveType()],
        balances = balances ?? <LeaveBalance>[sampleLeaveBalance()],
        requests = requests ?? <LeaveRequest>[sampleLeaveRequest()];

  List<LeaveType> types;
  List<LeaveBalance> balances;
  List<LeaveRequest> requests;
  Duration delay = Duration.zero;
  Object? typesError;
  Object? balancesError;
  Object? listError;
  Object? detailError;
  Object? createError;
  Object? approveError;
  Object? rejectError;
  Object? cancelError;
  Object? allocateError;
  Object? typeWriteError;
  CreateLeaveRequestBody? lastCreate;
  LeaveTypeWrite? lastTypeWrite;
  String? lastId;
  String? lastRejection;
  int? lastAllocatedDays;
  int listCalls = 0;
  int createCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;
  int cancelCalls = 0;
  final List<LeaveRequestQuery> listQueries = <LeaveRequestQuery>[];
  LeavePage<LeaveRequest> Function(LeaveRequestQuery query)? pageBuilder;

  Future<void> _wait() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  @override
  Future<LeavePage<LeaveType>> getLeaveTypes(LeaveTypeQuery query) async {
    await _wait();
    if (typesError != null) {
      throw typesError!;
    }
    final List<LeaveType> filtered = query.status == null
        ? types
        : types.where((LeaveType item) => item.status == query.status).toList();
    return LeavePage<LeaveType>(results: filtered, count: filtered.length);
  }

  @override
  Future<LeaveType> getLeaveType(String id) async {
    await _wait();
    return types.firstWhere(
      (LeaveType item) => item.id == id,
      orElse: () => types.first,
    );
  }

  @override
  Future<LeaveType> createLeaveType(LeaveTypeWrite body) async {
    await _wait();
    if (typeWriteError != null) {
      throw typeWriteError!;
    }
    lastTypeWrite = body;
    return sampleLeaveType(id: 'type-new', name: body.name, code: body.code);
  }

  @override
  Future<LeaveType> updateLeaveType(String id, LeaveTypeWrite body) async {
    await _wait();
    if (typeWriteError != null) {
      throw typeWriteError!;
    }
    lastId = id;
    lastTypeWrite = body;
    return sampleLeaveType(
      id: id,
      name: body.name,
      code: body.code,
      status: body.status,
    );
  }

  @override
  Future<LeavePage<LeaveBalance>> getLeaveBalances(LeaveBalanceQuery query) async {
    await _wait();
    if (balancesError != null) {
      throw balancesError!;
    }
    return LeavePage<LeaveBalance>(results: balances, count: balances.length);
  }

  @override
  Future<LeaveBalance> allocateLeaveBalance({
    required String id,
    required int allocatedDays,
  }) async {
    await _wait();
    if (allocateError != null) {
      throw allocateError!;
    }
    lastId = id;
    lastAllocatedDays = allocatedDays;
    return sampleLeaveBalance(id: id, allocatedDays: allocatedDays, remainingDays: allocatedDays);
  }

  @override
  Future<LeavePage<LeaveRequest>> getLeaveRequests(LeaveRequestQuery query) async {
    listCalls += 1;
    listQueries.add(query);
    await _wait();
    if (listError != null) {
      throw listError!;
    }
    if (pageBuilder != null) {
      return pageBuilder!(query);
    }
    return LeavePage<LeaveRequest>(results: requests, count: requests.length);
  }

  @override
  Future<LeaveRequest> getLeaveRequestDetails(String id) async {
    await _wait();
    if (detailError != null) {
      throw detailError!;
    }
    lastId = id;
    return requests.firstWhere(
      (LeaveRequest item) => item.id == id,
      orElse: () => requests.isEmpty ? sampleLeaveRequest(id: id) : requests.first,
    );
  }

  @override
  Future<LeaveRequest> createLeaveRequest(CreateLeaveRequestBody body) async {
    createCalls += 1;
    lastCreate = body;
    await _wait();
    if (createError != null) {
      throw createError!;
    }
    return sampleLeaveRequest(id: 'req-new');
  }

  @override
  Future<LeaveRequest> approveLeaveRequest(String id) async {
    approveCalls += 1;
    lastId = id;
    await _wait();
    if (approveError != null) {
      throw approveError!;
    }
    return sampleLeaveRequest(id: id, status: LeaveRequestStatus.approved);
  }

  @override
  Future<LeaveRequest> rejectLeaveRequest({
    required String id,
    required String rejectionReason,
  }) async {
    rejectCalls += 1;
    lastId = id;
    lastRejection = rejectionReason;
    await _wait();
    if (rejectError != null) {
      throw rejectError!;
    }
    return sampleLeaveRequest(
      id: id,
      status: LeaveRequestStatus.rejected,
      rejectionReason: rejectionReason,
    );
  }

  @override
  Future<LeaveRequest> cancelLeaveRequest(String id) async {
    cancelCalls += 1;
    lastId = id;
    await _wait();
    if (cancelError != null) {
      throw cancelError!;
    }
    return sampleLeaveRequest(id: id, status: LeaveRequestStatus.cancelled);
  }

  @override
  Future<DownloadedBytes> downloadLeaveAttachment(String id) async {
    lastId = id;
    return const DownloadedBytes(
      bytes: <int>[37, 80, 68, 70],
      filename: 'note.pdf',
      mimeType: 'application/pdf',
    );
  }
}

class FakeLeaveRemote implements LeaveRemoteDataSource {
  FakeLeaveRemote({
    LeavePage<LeaveType>? types,
    LeavePage<LeaveBalance>? balances,
    LeavePage<LeaveRequest>? requests,
    this.detail,
  })  : types = types ??
            LeavePage<LeaveType>(
              results: <LeaveType>[sampleLeaveType()],
              count: 1,
            ),
        balances = balances ??
            LeavePage<LeaveBalance>(
              results: <LeaveBalance>[sampleLeaveBalance()],
              count: 1,
            ),
        requests = requests ??
            LeavePage<LeaveRequest>(
              results: <LeaveRequest>[sampleLeaveRequest()],
              count: 1,
            );

  LeavePage<LeaveType> types;
  LeavePage<LeaveBalance> balances;
  LeavePage<LeaveRequest> requests;
  LeaveRequest? detail;
  LeaveTypeQuery? lastTypeQuery;
  LeaveRequestQuery? lastRequestQuery;
  CreateLeaveRequestBody? lastCreate;
  String? lastId;
  String? lastRejection;
  int listCalls = 0;

  @override
  Future<LeavePage<LeaveType>> getLeaveTypes(LeaveTypeQuery query) async {
    lastTypeQuery = query;
    return types;
  }

  @override
  Future<LeaveType> getLeaveType(String id) async => sampleLeaveType(id: id);

  @override
  Future<LeaveType> createLeaveType(LeaveTypeWrite body) async =>
      sampleLeaveType(name: body.name, code: body.code);

  @override
  Future<LeaveType> updateLeaveType(String id, LeaveTypeWrite body) async =>
      sampleLeaveType(id: id, name: body.name, status: body.status);

  @override
  Future<LeavePage<LeaveBalance>> getLeaveBalances(LeaveBalanceQuery query) async =>
      balances;

  @override
  Future<LeaveBalance> allocateLeaveBalance({
    required String id,
    required int allocatedDays,
  }) async =>
      sampleLeaveBalance(id: id, allocatedDays: allocatedDays);

  @override
  Future<LeavePage<LeaveRequest>> getLeaveRequests(LeaveRequestQuery query) async {
    listCalls += 1;
    lastRequestQuery = query;
    return requests;
  }

  @override
  Future<LeaveRequest> getLeaveRequest(String id) async {
    lastId = id;
    return detail ?? sampleLeaveRequest(id: id);
  }

  @override
  Future<LeaveRequest> createLeaveRequest(CreateLeaveRequestBody body) async {
    lastCreate = body;
    return sampleLeaveRequest(id: 'req-new');
  }

  @override
  Future<LeaveRequest> approveLeaveRequest(String id) async {
    lastId = id;
    return sampleLeaveRequest(id: id, status: LeaveRequestStatus.approved);
  }

  @override
  Future<LeaveRequest> rejectLeaveRequest({
    required String id,
    required String rejectionReason,
  }) async {
    lastId = id;
    lastRejection = rejectionReason;
    return sampleLeaveRequest(
      id: id,
      status: LeaveRequestStatus.rejected,
      rejectionReason: rejectionReason,
    );
  }

  @override
  Future<LeaveRequest> cancelLeaveRequest(String id) async {
    lastId = id;
    return sampleLeaveRequest(id: id, status: LeaveRequestStatus.cancelled);
  }

  @override
  Future<DownloadedBytes> downloadLeaveAttachment(String id) async {
    lastId = id;
    return const DownloadedBytes(
      bytes: <int>[37, 80, 68, 70],
      filename: 'note.pdf',
      mimeType: 'application/pdf',
    );
  }
}

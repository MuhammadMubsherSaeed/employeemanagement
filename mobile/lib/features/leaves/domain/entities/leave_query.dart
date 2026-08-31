import 'package:equatable/equatable.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';

class LeaveRequestQuery extends Equatable {
  const LeaveRequestQuery({
    this.status,
    this.leaveTypeId,
    this.startDate,
    this.endDate,
    this.employeeId,
    this.ordering = '-start_date',
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  final LeaveRequestStatus? status;
  final String? leaveTypeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? employeeId;
  final String ordering;
  final int page;
  final int pageSize;

  int get activeFilterCount {
    int count = 0;
    if (status != null) {
      count++;
    }
    if (leaveTypeId != null) {
      count++;
    }
    if (startDate != null) {
      count++;
    }
    if (endDate != null) {
      count++;
    }
    if (employeeId != null) {
      count++;
    }
    return count;
  }

  LeaveRequestQuery copyWith({
    LeaveRequestStatus? status,
    String? leaveTypeId,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? ordering,
    int? page,
    int? pageSize,
    bool clearStatus = false,
    bool clearLeaveType = false,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearEmployee = false,
  }) {
    return LeaveRequestQuery(
      status: clearStatus ? null : (status ?? this.status),
      leaveTypeId: clearLeaveType ? null : (leaveTypeId ?? this.leaveTypeId),
      startDate: clearStart ? null : (startDate ?? this.startDate),
      endDate: clearEnd ? null : (endDate ?? this.endDate),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      ordering: ordering ?? this.ordering,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  LeaveRequestQuery clearedFilters() {
    return LeaveRequestQuery(
      ordering: ordering,
      page: 1,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (status != null && status != LeaveRequestStatus.unknown)
        'status': status!.apiValue,
      if (leaveTypeId != null) 'leave_type': leaveTypeId,
      if (startDate != null) 'start_date': formatLeaveDateParam(startDate!),
      if (endDate != null) 'end_date': formatLeaveDateParam(endDate!),
      if (employeeId != null) 'employee': employeeId,
      'ordering': ordering,
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        leaveTypeId,
        startDate,
        endDate,
        employeeId,
        ordering,
        page,
        pageSize,
      ];
}

class LeaveTypeQuery extends Equatable {
  const LeaveTypeQuery({
    this.status,
    this.page = 1,
    this.pageSize = AppConstants.maxPageSize,
    this.ordering = 'name',
  });

  final LeaveTypeStatus? status;
  final int page;
  final int pageSize;
  final String ordering;

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (status != null && status != LeaveTypeStatus.unknown)
        'status': status!.apiValue,
      'page': page,
      'page_size': pageSize,
      'ordering': ordering,
    };
  }

  @override
  List<Object?> get props => <Object?>[status, page, pageSize, ordering];
}

class LeaveBalanceQuery extends Equatable {
  const LeaveBalanceQuery({
    this.year,
    this.leaveTypeId,
    this.employeeId,
    this.page = 1,
    this.pageSize = AppConstants.maxPageSize,
  });

  final int? year;
  final String? leaveTypeId;
  final String? employeeId;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (year != null) 'year': year,
      if (leaveTypeId != null) 'leave_type': leaveTypeId,
      if (employeeId != null) 'employee': employeeId,
      'page': page,
      'page_size': pageSize,
    };
  }

  @override
  List<Object?> get props =>
      <Object?>[year, leaveTypeId, employeeId, page, pageSize];
}

class LeavePage<T> extends Equatable {
  const LeavePage({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.trim().isNotEmpty;

  @override
  List<Object?> get props => <Object?>[results, count, next, previous];
}

class CreateLeaveRequestBody extends Equatable {
  const CreateLeaveRequestBody({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.reason = '',
    this.attachment,
  });

  final String leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveAttachmentFile? attachment;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'leave_type': leaveTypeId,
      'start_date': formatLeaveDateParam(startDate),
      'end_date': formatLeaveDateParam(endDate),
      'reason': reason,
    };
  }

  @override
  List<Object?> get props =>
      <Object?>[leaveTypeId, startDate, endDate, reason, attachment];
}

class LeaveTypeWrite extends Equatable {
  const LeaveTypeWrite({
    required this.name,
    required this.code,
    required this.daysAllowed,
    this.isPaid = true,
    this.carryForward = false,
    this.status = LeaveTypeStatus.active,
  });

  final String name;
  final String code;
  final int daysAllowed;
  final bool isPaid;
  final bool carryForward;
  final LeaveTypeStatus status;

  factory LeaveTypeWrite.fromType(LeaveType type) {
    return LeaveTypeWrite(
      name: type.name,
      code: type.code,
      daysAllowed: type.daysAllowed,
      isPaid: type.isPaid,
      carryForward: type.carryForward,
      status: type.status,
    );
  }

  LeaveTypeWrite copyWith({
    String? name,
    String? code,
    int? daysAllowed,
    bool? isPaid,
    bool? carryForward,
    LeaveTypeStatus? status,
  }) {
    return LeaveTypeWrite(
      name: name ?? this.name,
      code: code ?? this.code,
      daysAllowed: daysAllowed ?? this.daysAllowed,
      isPaid: isPaid ?? this.isPaid,
      carryForward: carryForward ?? this.carryForward,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'days_allowed': daysAllowed,
      'is_paid': isPaid,
      'carry_forward': carryForward,
      'status': status.apiValue,
    };
  }

  @override
  List<Object?> get props =>
      <Object?>[name, code, daysAllowed, isPaid, carryForward, status];
}

String formatLeaveDateParam(DateTime value) {
  final DateTime local = DateTime(value.year, value.month, value.day);
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';

class LeaveEmployeeRef extends Equatable {
  const LeaveEmployeeRef({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();

  factory LeaveEmployeeRef.fromJson(Map<String, dynamic> json) {
    return LeaveEmployeeRef(
      id: _readString(json['id']),
      employeeCode: _readString(json['employee_code']),
      firstName: _readString(json['first_name']),
      lastName: _readString(json['last_name']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, employeeCode, firstName, lastName];
}

class LeaveType extends Equatable {
  const LeaveType({
    required this.id,
    required this.name,
    required this.code,
    required this.daysAllowed,
    required this.isPaid,
    required this.carryForward,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final int daysAllowed;
  final bool isPaid;
  final bool carryForward;
  final LeaveTypeStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == LeaveTypeStatus.active;

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: _readString(json['id']),
      name: _readString(json['name']),
      code: _readString(json['code']),
      daysAllowed: _readInt(json['days_allowed']) ?? 0,
      isPaid: json['is_paid'] == true,
      carryForward: json['carry_forward'] == true,
      status: LeaveTypeStatus.fromApi(_readString(json['status'])),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        code,
        daysAllowed,
        isPaid,
        carryForward,
        status,
        createdAt,
        updatedAt,
      ];
}

class LeaveBalance extends Equatable {
  const LeaveBalance({
    required this.id,
    required this.year,
    required this.allocatedDays,
    required this.usedDays,
    required this.remainingDays,
    this.employee,
    this.leaveType,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final LeaveEmployeeRef? employee;
  final LeaveType? leaveType;
  final int year;
  final int allocatedDays;
  final int usedDays;
  final int remainingDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: _readString(json['id']),
      employee: _readEmployee(json['employee']),
      leaveType: _readLeaveType(json['leave_type']),
      year: _readInt(json['year']) ?? 0,
      allocatedDays: _readInt(json['allocated_days']) ?? 0,
      usedDays: _readInt(json['used_days']) ?? 0,
      remainingDays: _readInt(json['remaining_days']) ?? 0,
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        employee,
        leaveType,
        year,
        allocatedDays,
        usedDays,
        remainingDays,
        createdAt,
        updatedAt,
      ];
}

class LeaveRequest extends Equatable {
  const LeaveRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    this.employee,
    this.leaveType,
    this.reason = '',
    this.attachment,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final LeaveEmployeeRef? employee;
  final LeaveType? leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final LeaveRequestStatus status;
  final String reason;
  final String? attachment;
  final int? approvedBy;
  final DateTime? approvedAt;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status == LeaveRequestStatus.pending;

  bool get isApproved => status == LeaveRequestStatus.approved;

  bool get canAttemptCancel =>
      status == LeaveRequestStatus.pending ||
      status == LeaveRequestStatus.approved;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: _readString(json['id']),
      employee: _readEmployee(json['employee']),
      leaveType: _readLeaveType(json['leave_type']),
      startDate: _readDate(json['start_date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endDate:
          _readDate(json['end_date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      totalDays: _readInt(json['total_days']) ?? 0,
      status: LeaveRequestStatus.fromApi(_readString(json['status'])),
      reason: _readString(json['reason']),
      attachment: _readOptionalString(json['attachment']),
      approvedBy: _readInt(json['approved_by']),
      approvedAt: _readDateTime(json['approved_at']),
      rejectionReason: _readString(json['rejection_reason']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        employee,
        leaveType,
        startDate,
        endDate,
        totalDays,
        status,
        reason,
        attachment,
        approvedBy,
        approvedAt,
        rejectionReason,
        createdAt,
        updatedAt,
      ];
}

class LeaveAttachmentFile extends Equatable {
  const LeaveAttachmentFile({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;

  @override
  List<Object?> get props => <Object?>[path, name, size];
}

LeaveEmployeeRef? _readEmployee(dynamic value) {
  if (value is Map) {
    return LeaveEmployeeRef.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

LeaveType? _readLeaveType(dynamic value) {
  if (value is Map) {
    return LeaveType.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

String _readString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? _readOptionalString(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString();
  return text.isEmpty ? null : text;
}

int? _readInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

DateTime? _readDate(dynamic value) {
  if (value == null) {
    return null;
  }
  final String raw = value.toString();
  final DateTime? parsed = raw.length >= 10
      ? DateTime.tryParse(raw.substring(0, 10))
      : DateTime.tryParse(raw);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

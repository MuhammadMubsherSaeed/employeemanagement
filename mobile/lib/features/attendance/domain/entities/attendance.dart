import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';

class AttendanceEmployeeRef extends Equatable {
  const AttendanceEmployeeRef({
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

  factory AttendanceEmployeeRef.fromJson(Map<String, dynamic> json) {
    return AttendanceEmployeeRef(
      id: _readString(json['id']),
      employeeCode: _readString(json['employee_code']),
      firstName: _readString(json['first_name']),
      lastName: _readString(json['last_name']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, employeeCode, firstName, lastName];
}

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.employee,
    this.checkIn,
    this.checkOut,
    this.totalMinutes,
    this.checkInIp,
    this.checkOutIp,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DateTime date;
  final AttendanceStatus status;
  final AttendanceEmployeeRef? employee;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? totalMinutes;
  final String? checkInIp;
  final String? checkOutIp;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasCheckIn => checkIn != null;

  bool get hasCheckOut => checkOut != null;

  bool get hasSensitiveLocation =>
      checkInIp != null ||
      checkOutIp != null ||
      checkInLatitude != null ||
      checkOutLatitude != null;

  PunchState get punchState {
    if (checkIn == null) {
      return PunchState.none;
    }
    if (checkOut == null) {
      return PunchState.checkedIn;
    }
    return PunchState.checkedOut;
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: _readString(json['id']),
      date: _readDate(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: AttendanceStatus.fromApi(_readString(json['status'])),
      employee: _readEmployee(json['employee']),
      checkIn: _readDateTime(json['check_in']),
      checkOut: _readDateTime(json['check_out']),
      totalMinutes: _readInt(json['total_minutes']),
      checkInIp: _readOptionalString(json['check_in_ip']),
      checkOutIp: _readOptionalString(json['check_out_ip']),
      checkInLatitude: _readDouble(json['check_in_latitude']),
      checkInLongitude: _readDouble(json['check_in_longitude']),
      checkOutLatitude: _readDouble(json['check_out_latitude']),
      checkOutLongitude: _readDouble(json['check_out_longitude']),
      createdAt: _readDateTime(json['created_at']),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        date,
        status,
        employee,
        checkIn,
        checkOut,
        totalMinutes,
        checkInIp,
        checkOutIp,
        checkInLatitude,
        checkInLongitude,
        checkOutLatitude,
        checkOutLongitude,
        createdAt,
        updatedAt,
      ];
}

class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.weekendDays,
    required this.totalWorkingMinutes,
    required this.overtimeMinutes,
    this.employeeId,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String? employeeId;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int halfDays;
  final int leaveDays;
  final int holidayDays;
  final int weekendDays;
  final int totalWorkingMinutes;
  final int overtimeMinutes;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      startDate: _readDate(json['start_date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endDate:
          _readDate(json['end_date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      employeeId: json['employee_id']?.toString(),
      totalDays: _readInt(json['total_days']) ?? 0,
      presentDays: _readInt(json['present_days']) ?? 0,
      absentDays: _readInt(json['absent_days']) ?? 0,
      lateDays: _readInt(json['late_days']) ?? 0,
      halfDays: _readInt(json['half_days']) ?? 0,
      leaveDays: _readInt(json['leave_days']) ?? 0,
      holidayDays: _readInt(json['holiday_days']) ?? 0,
      weekendDays: _readInt(json['weekend_days']) ?? 0,
      totalWorkingMinutes: _readInt(json['total_working_minutes']) ?? 0,
      overtimeMinutes: _readInt(json['overtime_minutes']) ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        startDate,
        endDate,
        employeeId,
        totalDays,
        presentDays,
        absentDays,
        lateDays,
        halfDays,
        leaveDays,
        holidayDays,
        weekendDays,
        totalWorkingMinutes,
        overtimeMinutes,
      ];
}

AttendanceEmployeeRef? _readEmployee(dynamic value) {
  if (value is Map) {
    return AttendanceEmployeeRef.fromJson(Map<String, dynamic>.from(value));
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

double? _readDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
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

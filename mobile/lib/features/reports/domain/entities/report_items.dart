import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/reports/domain/entities/report_json.dart';
import 'package:flutter_base/features/reports/domain/entities/report_refs.dart';

class AttendanceReportItem extends Equatable {
  const AttendanceReportItem({
    required this.id,
    required this.employee,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.workingMinutes,
  });

  final String id;
  final ReportEmployeeRef employee;
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? workingMinutes;
  final AttendanceStatus status;

  factory AttendanceReportItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> employeeJson =
        readReportMap(json['employee']) ?? const <String, dynamic>{};
    return AttendanceReportItem(
      id: readReportString(json['id']),
      employee: ReportEmployeeRef.fromJson(employeeJson),
      date: readReportDate(json['date']),
      checkIn: readReportDate(json['check_in']),
      checkOut: readReportDate(json['check_out']),
      workingMinutes: readReportInt(json['working_minutes']),
      status: AttendanceStatus.fromApi(readReportString(json['status'])),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        employee,
        date,
        checkIn,
        checkOut,
        workingMinutes,
        status,
      ];
}

class LeaveReportItem extends Equatable {
  const LeaveReportItem({
    required this.id,
    required this.employee,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    this.approvedBy,
    this.approvedAt,
  });

  final String id;
  final ReportEmployeeRef employee;
  final ReportLeaveTypeRef leaveType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalDays;
  final LeaveRequestStatus status;
  final ReportApproverRef? approvedBy;
  final DateTime? approvedAt;

  factory LeaveReportItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> employeeJson =
        readReportMap(json['employee']) ?? const <String, dynamic>{};
    final Map<String, dynamic> typeJson =
        readReportMap(json['leave_type']) ?? const <String, dynamic>{};
    final Map<String, dynamic>? approverJson = readReportMap(json['approved_by']);
    return LeaveReportItem(
      id: readReportString(json['id']),
      employee: ReportEmployeeRef.fromJson(employeeJson),
      leaveType: ReportLeaveTypeRef.fromJson(typeJson),
      startDate: readReportDate(json['start_date']),
      endDate: readReportDate(json['end_date']),
      totalDays: readReportInt(json['total_days']) ?? 0,
      status: LeaveRequestStatus.fromApi(readReportString(json['status'])),
      approvedBy: approverJson == null
          ? null
          : ReportApproverRef.fromJson(approverJson),
      approvedAt: readReportDate(json['approved_at']),
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
        approvedBy,
        approvedAt,
      ];
}

class EmployeeReportItem extends Equatable {
  const EmployeeReportItem({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.employmentType,
    required this.status,
    this.department,
    this.position,
    this.manager,
    this.joiningDate,
  });

  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String fullName;
  final Department? department;
  final ReportPositionRef? position;
  final EmployeeManagerRef? manager;
  final EmploymentType employmentType;
  final DateTime? joiningDate;
  final EmployeeStatus status;

  factory EmployeeReportItem.fromJson(Map<String, dynamic> json) {
    final String first = readReportString(json['first_name']);
    final String last = readReportString(json['last_name']);
    final String full = readReportString(json['full_name']);
    final Map<String, dynamic>? departmentJson = readReportMap(json['department']);
    final Map<String, dynamic>? positionJson = readReportMap(json['position']);
    final Map<String, dynamic>? managerJson = readReportMap(json['manager']);
    return EmployeeReportItem(
      id: readReportString(json['id']),
      employeeCode: readReportString(json['employee_code']),
      firstName: first,
      lastName: last,
      fullName: full.isNotEmpty ? full : '$first $last'.trim(),
      department: departmentJson == null
          ? null
          : Department.fromJson(departmentJson),
      position: positionJson == null
          ? null
          : ReportPositionRef.fromJson(positionJson),
      manager: managerJson == null
          ? null
          : EmployeeManagerRef.fromJson(managerJson),
      employmentType: EmploymentType.fromApi(
        readReportString(json['employment_type']),
      ),
      joiningDate: readReportDate(json['joining_date']),
      status: EmployeeStatus.fromApi(readReportString(json['status'])),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        employeeCode,
        firstName,
        lastName,
        fullName,
        department,
        position,
        manager,
        employmentType,
        joiningDate,
        status,
      ];
}

class DeviceReportItem extends Equatable {
  const DeviceReportItem({
    required this.id,
    required this.assetCode,
    required this.type,
    required this.status,
    this.manufacturer = '',
    this.model = '',
    this.serialNumber,
    this.assignedEmployee,
    this.assignedAt,
    this.returnedAt,
    this.cost,
    this.hasCost = false,
  });

  final String id;
  final String assetCode;
  final String type;
  final String manufacturer;
  final String model;
  final String? serialNumber;
  final DeviceStatus status;
  final ReportEmployeeRef? assignedEmployee;
  final DateTime? assignedAt;
  final DateTime? returnedAt;
  final String? cost;
  final bool hasCost;

  factory DeviceReportItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? assigned = readReportMap(json['assigned_employee']);
    return DeviceReportItem(
      id: readReportString(json['id']),
      assetCode: readReportString(json['asset_code']),
      type: readReportString(json['type']),
      manufacturer: readReportString(json['manufacturer']),
      model: readReportString(json['model']),
      serialNumber: readOptionalReportString(json['serial_number']),
      status: DeviceStatus.fromApi(readReportString(json['status'])),
      assignedEmployee:
          assigned == null ? null : ReportEmployeeRef.fromJson(assigned),
      assignedAt: readReportDate(json['assigned_at']),
      returnedAt: readReportDate(json['returned_at']),
      cost: json.containsKey('cost')
          ? readOptionalReportString(json['cost'])
          : null,
      hasCost: json.containsKey('cost'),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        assetCode,
        type,
        manufacturer,
        model,
        serialNumber,
        status,
        assignedEmployee,
        assignedAt,
        returnedAt,
        cost,
        hasCost,
      ];
}

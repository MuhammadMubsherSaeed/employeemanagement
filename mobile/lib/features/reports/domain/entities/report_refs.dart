import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/reports/domain/entities/report_json.dart';

class ReportEmployeeRef extends Equatable {
  const ReportEmployeeRef({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    this.department,
  });

  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final Department? department;

  String get fullName => '$firstName $lastName'.trim();

  factory ReportEmployeeRef.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? departmentJson = readReportMap(json['department']);
    return ReportEmployeeRef(
      id: readReportString(json['id']),
      employeeCode: readReportString(json['employee_code']),
      firstName: readReportString(json['first_name']),
      lastName: readReportString(json['last_name']),
      department: departmentJson == null
          ? null
          : Department.fromJson(departmentJson),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[id, employeeCode, firstName, lastName, department];
}

class ReportLeaveTypeRef extends Equatable {
  const ReportLeaveTypeRef({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;

  factory ReportLeaveTypeRef.fromJson(Map<String, dynamic> json) {
    return ReportLeaveTypeRef(
      id: readReportString(json['id']),
      name: readReportString(json['name']),
      code: readReportString(json['code']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, code];
}

class ReportApproverRef extends Equatable {
  const ReportApproverRef({
    required this.id,
    required this.email,
  });

  final int id;
  final String email;

  factory ReportApproverRef.fromJson(Map<String, dynamic> json) {
    return ReportApproverRef(
      id: readReportInt(json['id']) ?? 0,
      email: readReportString(json['email']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, email];
}

class ReportPositionRef extends Equatable {
  const ReportPositionRef({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final OrgStatus status;

  factory ReportPositionRef.fromJson(Map<String, dynamic> json) {
    return ReportPositionRef(
      id: readReportString(json['id']),
      title: readReportString(json['title']),
      status: OrgStatus.fromApi(readReportString(json['status'])),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, title, status];
}

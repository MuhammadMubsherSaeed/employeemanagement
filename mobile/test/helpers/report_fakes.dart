import 'dart:typed_data';

import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/reports/domain/entities/report_refs.dart';
import 'package:flutter_base/features/reports/domain/repositories/report_repository.dart';
import 'package:flutter_base/features/reports/domain/services/report_file_service.dart';

AttendanceReportItem sampleAttendanceReportItem({
  String id = 'att-1',
  String employeeId = 'emp-1',
}) {
  return AttendanceReportItem(
    id: id,
    employee: ReportEmployeeRef(
      id: employeeId,
      employeeCode: 'EMP-001',
      firstName: 'Ada',
      lastName: 'Lovelace',
      department: const Department(
        id: 'dept-1',
        name: 'Engineering',
        status: OrgStatus.active,
      ),
    ),
    date: DateTime(2026, 9, 1),
    checkIn: DateTime(2026, 9, 1, 9),
    checkOut: DateTime(2026, 9, 1, 17),
    workingMinutes: 480,
    status: AttendanceStatus.present,
  );
}

LeaveReportItem sampleLeaveReportItem({String id = 'leave-1'}) {
  return LeaveReportItem(
    id: id,
    employee: const ReportEmployeeRef(
      id: 'emp-1',
      employeeCode: 'EMP-001',
      firstName: 'Ada',
      lastName: 'Lovelace',
    ),
    leaveType: const ReportLeaveTypeRef(
      id: 'lt-1',
      name: 'Annual',
      code: 'ANNUAL',
    ),
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 9, 3),
    totalDays: 3,
    status: LeaveRequestStatus.approved,
    approvedBy: const ReportApproverRef(id: 10, email: 'admin@example.com'),
    approvedAt: DateTime(2026, 8, 20, 12),
  );
}

EmployeeReportItem sampleEmployeeReportItem({String id = 'emp-1'}) {
  return EmployeeReportItem(
    id: id,
    employeeCode: 'EMP-001',
    firstName: 'Ada',
    lastName: 'Lovelace',
    fullName: 'Ada Lovelace',
    department: const Department(
      id: 'dept-1',
      name: 'Engineering',
      status: OrgStatus.active,
    ),
    position: const ReportPositionRef(
      id: 'pos-1',
      title: 'Engineer',
      status: OrgStatus.active,
    ),
    manager: const EmployeeManagerRef(
      id: 'mgr-1',
      employeeCode: 'EMP-100',
      firstName: 'Grace',
      lastName: 'Hopper',
    ),
    employmentType: EmploymentType.fullTime,
    joiningDate: DateTime(2024, 1, 15),
    status: EmployeeStatus.active,
  );
}

DeviceReportItem sampleDeviceReportItem({
  String id = 'dev-1',
  bool includeCost = false,
}) {
  return DeviceReportItem(
    id: id,
    assetCode: 'LAP-001',
    type: 'Laptop',
    manufacturer: 'Lenovo',
    model: 'T14',
    serialNumber: 'SN-1',
    status: DeviceStatus.assigned,
    assignedEmployee: const ReportEmployeeRef(
      id: 'emp-1',
      employeeCode: 'EMP-001',
      firstName: 'Ada',
      lastName: 'Lovelace',
    ),
    assignedAt: DateTime(2026, 1, 10),
    cost: includeCost ? '1200.00' : null,
    hasCost: includeCost,
  );
}

Map<String, dynamic> sampleAttendanceReportJson() {
  return <String, dynamic>{
    'id': 'att-1',
    'employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
      'department': <String, dynamic>{
        'id': 'dept-1',
        'name': 'Engineering',
        'status': 'ACTIVE',
      },
    },
    'date': '2026-09-01',
    'check_in': '2026-09-01T09:00:00Z',
    'check_out': '2026-09-01T17:00:00Z',
    'working_minutes': 480,
    'status': 'PRESENT',
  };
}

Map<String, dynamic> sampleLeaveReportJson() {
  return <String, dynamic>{
    'id': 'leave-1',
    'employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
      'department': <String, dynamic>{
        'id': 'dept-1',
        'name': 'Engineering',
        'status': 'ACTIVE',
      },
    },
    'leave_type': <String, dynamic>{
      'id': 'lt-1',
      'name': 'Annual',
      'code': 'ANNUAL',
    },
    'start_date': '2026-09-01',
    'end_date': '2026-09-03',
    'total_days': 3,
    'status': 'APPROVED',
    'approved_by': <String, dynamic>{'id': 10, 'email': 'admin@example.com'},
    'approved_at': '2026-08-20T12:00:00Z',
  };
}

Map<String, dynamic> sampleEmployeeReportJson() {
  return <String, dynamic>{
    'id': 'emp-1',
    'employee_code': 'EMP-001',
    'first_name': 'Ada',
    'last_name': 'Lovelace',
    'full_name': 'Ada Lovelace',
    'department': <String, dynamic>{
      'id': 'dept-1',
      'name': 'Engineering',
      'status': 'ACTIVE',
    },
    'position': <String, dynamic>{
      'id': 'pos-1',
      'title': 'Engineer',
      'status': 'ACTIVE',
    },
    'manager': <String, dynamic>{
      'id': 'mgr-1',
      'employee_code': 'EMP-100',
      'first_name': 'Grace',
      'last_name': 'Hopper',
    },
    'employment_type': 'FULL_TIME',
    'joining_date': '2024-01-15',
    'status': 'ACTIVE',
  };
}

Map<String, dynamic> sampleDeviceReportJson({bool includeCost = false}) {
  final Map<String, dynamic> json = <String, dynamic>{
    'id': 'dev-1',
    'asset_code': 'LAP-001',
    'type': 'Laptop',
    'manufacturer': 'Lenovo',
    'model': 'T14',
    'serial_number': 'SN-1',
    'status': 'ASSIGNED',
    'assigned_employee': <String, dynamic>{
      'id': 'emp-1',
      'employee_code': 'EMP-001',
      'first_name': 'Ada',
      'last_name': 'Lovelace',
    },
    'assigned_at': '2026-01-10T08:00:00Z',
    'returned_at': null,
  };
  if (includeCost) {
    json['cost'] = '1200.00';
  }
  return json;
}

Map<String, dynamic> reportListEnvelope(List<Map<String, dynamic>> results) {
  return <String, dynamic>{
    'success': true,
    'message': 'Report generated successfully.',
    'data': <String, dynamic>{
      'count': results.length,
      'next': null,
      'previous': null,
      'results': results,
    },
  };
}

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({
    List<AttendanceReportItem>? attendance,
    List<LeaveReportItem>? leaves,
    List<EmployeeReportItem>? employees,
    List<DeviceReportItem>? devices,
  })  : attendance = attendance ?? <AttendanceReportItem>[sampleAttendanceReportItem()],
        leaves = leaves ?? <LeaveReportItem>[sampleLeaveReportItem()],
        employees = employees ?? <EmployeeReportItem>[sampleEmployeeReportItem()],
        devices = devices ?? <DeviceReportItem>[sampleDeviceReportItem()];

  List<AttendanceReportItem> attendance;
  List<LeaveReportItem> leaves;
  List<EmployeeReportItem> employees;
  List<DeviceReportItem> devices;

  final List<ReportQuery> attendanceQueries = <ReportQuery>[];
  final List<ReportQuery> leaveQueries = <ReportQuery>[];
  final List<ReportQuery> employeeQueries = <ReportQuery>[];
  final List<ReportQuery> deviceQueries = <ReportQuery>[];
  final List<ReportExportFormat> exportFormats = <ReportExportFormat>[];
  final List<ReportQuery> exportQueries = <ReportQuery>[];

  int attendanceCalls = 0;
  int leaveCalls = 0;
  int employeeCalls = 0;
  int deviceCalls = 0;
  int exportCalls = 0;
  Duration delay = Duration.zero;
  Object? listError;
  Object? exportError;
  bool Function(ReportQuery query)? hasMoreFor;

  @override
  Future<ReportPage<AttendanceReportItem>> getAttendanceReport(
    ReportQuery query,
  ) {
    return _list(query, attendance, attendanceQueries, () => attendanceCalls++);
  }

  @override
  Future<ReportPage<LeaveReportItem>> getLeaveReport(ReportQuery query) {
    return _list(query, leaves, leaveQueries, () => leaveCalls++);
  }

  @override
  Future<ReportPage<EmployeeReportItem>> getEmployeeReport(ReportQuery query) {
    return _list(query, employees, employeeQueries, () => employeeCalls++);
  }

  @override
  Future<ReportPage<DeviceReportItem>> getDeviceReport(ReportQuery query) {
    return _list(query, devices, deviceQueries, () => deviceCalls++);
  }

  @override
  Future<ReportExportFile> exportAttendanceReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(query, format);
  }

  @override
  Future<ReportExportFile> exportLeaveReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(query, format);
  }

  @override
  Future<ReportExportFile> exportEmployeeReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(query, format);
  }

  @override
  Future<ReportExportFile> exportDeviceReport(
    ReportQuery query,
    ReportExportFormat format,
  ) {
    return _export(query, format);
  }

  Future<ReportPage<T>> _list<T>(
    ReportQuery query,
    List<T> items,
    List<ReportQuery> log,
    void Function() bump,
  ) async {
    bump();
    log.add(query);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (listError != null) {
      throw listError!;
    }
    final bool hasMore = hasMoreFor?.call(query) ?? false;
    return ReportPage<T>(
      results: items,
      count: items.length,
      next: hasMore ? 'http://example.com/api/v1/reports/?page=${query.page + 1}' : null,
    );
  }

  Future<ReportExportFile> _export(
    ReportQuery query,
    ReportExportFormat format,
  ) async {
    exportCalls += 1;
    exportQueries.add(query);
    exportFormats.add(format);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (exportError != null) {
      throw exportError!;
    }
    return ReportExportFile(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      filename: 'attendance-report-2026-09-01.${format.apiValue}',
      mimeType: format.mimeType,
      format: format,
    );
  }
}

class FakeReportFileService implements ReportFileService {
  final List<ReportExportFile> saved = <ReportExportFile>[];
  final List<ReportSavedFile> shared = <ReportSavedFile>[];
  final List<ReportSavedFile> opened = <ReportSavedFile>[];
  Object? saveError;

  @override
  Future<ReportSavedFile> save(ReportExportFile file) async {
    if (saveError != null) {
      throw saveError!;
    }
    saved.add(file);
    return ReportSavedFile(
      path: '/tmp/${file.filename}',
      filename: file.filename,
      mimeType: file.mimeType,
    );
  }

  @override
  Future<void> share(ReportSavedFile file) async {
    shared.add(file);
  }

  @override
  Future<bool> open(ReportSavedFile file) async {
    opened.add(file);
    return true;
  }
}

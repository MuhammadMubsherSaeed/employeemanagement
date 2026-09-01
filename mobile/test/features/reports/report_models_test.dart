import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/report_fakes.dart';

void main() {
  test('attendance report serializes known and unknown statuses', () {
    final AttendanceReportItem item =
        AttendanceReportItem.fromJson(sampleAttendanceReportJson());
    expect(item.employee.employeeCode, 'EMP-001');
    expect(item.employee.department?.name, 'Engineering');
    expect(item.workingMinutes, 480);
    expect(item.status, AttendanceStatus.present);

    final AttendanceReportItem unknown = AttendanceReportItem.fromJson(
      <String, dynamic>{
        ...sampleAttendanceReportJson(),
        'status': 'FUTURE_STATUS',
        'working_minutes': null,
        'check_out': null,
      },
    );
    expect(unknown.status, AttendanceStatus.unknown);
    expect(unknown.workingMinutes, isNull);
    expect(unknown.checkOut, isNull);
  });

  test('leave report serializes nullable approver', () {
    final LeaveReportItem item =
        LeaveReportItem.fromJson(sampleLeaveReportJson());
    expect(item.leaveType.code, 'ANNUAL');
    expect(item.totalDays, 3);
    expect(item.status, LeaveRequestStatus.approved);
    expect(item.approvedBy?.email, 'admin@example.com');

    final LeaveReportItem pending = LeaveReportItem.fromJson(
      <String, dynamic>{
        ...sampleLeaveReportJson(),
        'status': 'PENDING',
        'approved_by': null,
        'approved_at': null,
      },
    );
    expect(pending.approvedBy, isNull);
    expect(pending.approvedAt, isNull);
  });

  test('employee report omits contact fields', () {
    final EmployeeReportItem item =
        EmployeeReportItem.fromJson(sampleEmployeeReportJson());
    expect(item.fullName, 'Ada Lovelace');
    expect(item.employmentType, EmploymentType.fullTime);
    expect(item.manager?.fullName, 'Grace Hopper');
    expect(item.status, EmployeeStatus.active);
  });

  test('device report keeps cost only when the backend included it', () {
    final DeviceReportItem hidden =
        DeviceReportItem.fromJson(sampleDeviceReportJson());
    expect(hidden.hasCost, isFalse);
    expect(hidden.cost, isNull);
    expect(hidden.status, DeviceStatus.assigned);

    final DeviceReportItem shown = DeviceReportItem.fromJson(
      sampleDeviceReportJson(includeCost: true),
    );
    expect(shown.hasCost, isTrue);
    expect(shown.cost, '1200.00');
  });

  test('pagination parses count, next, and empty results', () {
    final ReportPage<AttendanceReportItem> page =
        ReportPage<AttendanceReportItem>(
      results: <AttendanceReportItem>[sampleAttendanceReportItem()],
      count: 40,
      next: 'http://example.com/api/v1/reports/attendance/?page=2',
    );
    expect(page.hasMore, isTrue);
    expect(
      const ReportPage<AttendanceReportItem>(results: <AttendanceReportItem>[], count: 0)
          .hasMore,
      isFalse,
    );
  });

  test('report query sends only backend-supported filters', () {
    final ReportQuery attendance = ReportQuery(
      kind: ReportKind.attendance,
      dateFrom: DateTime(2026, 9, 2),
      dateTo: DateTime(2026, 9, 1),
      employeeId: 'emp-1',
      departmentId: 'dept-1',
      status: 'PRESENT',
      search: 'Ada',
      employmentType: 'FULL_TIME',
      leaveTypeId: 'lt-1',
    );
    expect(attendance.hasInvalidDateRange, isTrue);
    expect(attendance.toQueryParameters()['date_from'], '2026-09-02');
    expect(attendance.toQueryParameters().containsKey('employment_type'), isFalse);
    expect(attendance.toQueryParameters().containsKey('company_id'), isFalse);

    final ReportQuery employees = ReportQuery(
      kind: ReportKind.employees,
      dateFrom: DateTime(2026, 1, 1),
      employmentType: 'FULL_TIME',
      search: 'Ada',
    );
    expect(employees.toQueryParameters().containsKey('date_from'), isFalse);
    expect(employees.toQueryParameters()['employment_type'], 'FULL_TIME');
    expect(
      employees.toQueryParameters(includePagination: false).containsKey('page'),
      isFalse,
    );
  });
}

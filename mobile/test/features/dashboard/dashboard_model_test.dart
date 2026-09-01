import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dashboard_fakes.dart';

void main() {
  test('parses admin dashboard JSON including nested employees and activity', () {
    final AdminDashboard data = AdminDashboard.fromJson(
      sampleAdminDashboardJson(totalEmployees: 12),
    );

    expect(data.totalEmployees, 12);
    expect(data.activeEmployees, 10);
    expect(data.inactiveEmployees, 2);
    expect(data.presentToday, 8);
    expect(data.absentToday, 1);
    expect(data.lateToday, 1);
    expect(data.onLeaveToday, 2);
    expect(data.pendingLeaveRequests, 4);
    expect(data.recentEmployees.single.employeeCode, 'EMP-001');
    expect(data.recentEmployees.single.fullName, 'Ada Lovelace');
    expect(data.recentEmployees.single.status, EmployeeStatus.active);
    expect(data.recentEmployees.single.department?.name, 'Engineering');
    expect(data.recentActivity.single.resource, 'employees.Employee');
    expect(data.recentActivity.single.actor?.email, 'admin@example.com');
  });

  test('admin dashboard treats missing optional lists as empty', () {
    final AdminDashboard data = AdminDashboard.fromJson(const <String, dynamic>{
      'total_employees': 0,
      'active_employees': 0,
      'inactive_employees': 0,
      'present_today': 0,
      'absent_today': 0,
      'late_today': 0,
      'on_leave_today': 0,
      'pending_leave_requests': 0,
    });

    expect(data.recentEmployees, isEmpty);
    expect(data.recentActivity, isEmpty);
  });

  test('parses manager dashboard JSON', () {
    final ManagerDashboard data = ManagerDashboard.fromJson(
      sampleManagerDashboardJson(),
    );

    expect(data.teamSize, 6);
    expect(data.teamPresent, 4);
    expect(data.teamAbsent, 1);
    expect(data.teamLate, 1);
    expect(data.teamOnLeave, 0);
    expect(data.pendingLeaveRequests, 2);
    expect(data.recentActivity.single.resource, 'leave.LeaveRequest');
  });

  test('parses employee dashboard JSON including null today attendance', () {
    final EmployeeDashboard data = EmployeeDashboard.fromJson(
      sampleEmployeeDashboardJson(),
    );

    expect(data.workingMinutes, 452);
    expect(data.notificationsCount, 3);
    expect(data.todayAttendance?.status, AttendanceStatus.present);
    expect(data.todayAttendance?.employee, isNull);
    expect(data.leaveBalances.single.id, isEmpty);
    expect(data.leaveBalances.single.leaveType?.name, 'Annual Leave');
    expect(data.leaveBalances.single.remainingDays, 12);
    expect(data.recentLeaveRequests.single.status, LeaveRequestStatus.pending);
    expect(data.assignedDevices.single.assetCode, 'LAP-001');
    expect(data.assignedDevices.single.hasCost, isFalse);

    final EmployeeDashboard empty = EmployeeDashboard.fromJson(
      sampleEmployeeDashboardJson(empty: true),
    );
    expect(empty.todayAttendance, isNull);
    expect(empty.leaveBalances, isEmpty);
    expect(empty.assignedDevices, isEmpty);
    expect(empty.notificationsCount, 0);
  });

  test('unknown enums and null actor do not crash', () {
    final AdminDashboard data = AdminDashboard.fromJson(<String, dynamic>{
      'total_employees': '3',
      'recent_employees': <Map<String, dynamic>>[
        sampleDashboardRecentEmployeeJson(status: 'ON_SABBATICAL'),
      ],
      'recent_activity': <Map<String, dynamic>>[
        sampleDashboardActivityJson(actor: null)
          ..['actor'] = null,
      ],
    });

    expect(data.totalEmployees, 3);
    expect(data.recentEmployees.single.status, EmployeeStatus.unknown);
    expect(data.recentActivity.single.actor, isNull);

    final EmployeeDashboard employee = EmployeeDashboard.fromJson(
      <String, dynamic>{
        'today_attendance': sampleDashboardTodayAttendanceJson(
          status: 'MYSTERY',
        ),
        'recent_leave_requests': <Map<String, dynamic>>[
          sampleDashboardLeaveRequestJson(status: 'WEIRD'),
        ],
      },
    );
    expect(employee.todayAttendance?.status, AttendanceStatus.unknown);
    expect(
      employee.recentLeaveRequests.single.status,
      LeaveRequestStatus.unknown,
    );
  });
}

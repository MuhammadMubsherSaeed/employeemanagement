import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/network/auth_endpoints.dart';
import 'package:flutter_base/features/attendance/data/attendance_endpoints.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/audit_logs/data/audit_log_endpoints.dart';
import 'package:flutter_base/features/dashboard/data/dashboard_endpoints.dart';
import 'package:flutter_base/features/devices/data/device_endpoints.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/documents/data/document_endpoints.dart';
import 'package:flutter_base/features/employees/data/employee_endpoints.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/leaves/data/leave_endpoints.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/notifications/data/notification_endpoints.dart';
import 'package:flutter_base/features/reports/data/report_endpoints.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_base/features/settings/data/settings_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression inventory of Flutter paths and query keys vs the Django API.
///
/// Django remains authoritative. These strings must stay aligned with
/// `backend/apps/*/urls.py` and `backend/apps/common/tests/test_flutter_route_parity.py`.
void main() {
  test('Flutter product paths match /api/v1/ Django routes', () {
    expect(ApiPaths.health, '/api/v1/health/');
    expect(AuthEndpoints.login, 'auth/login/');
    expect(AuthEndpoints.refresh, 'auth/refresh/');
    expect(AuthEndpoints.logout, 'auth/logout/');
    expect(AuthEndpoints.me, 'auth/me/');
    expect(AuthEndpoints.forgotPassword, 'auth/forgot-password/');
    expect(AuthEndpoints.resetPassword, 'auth/reset-password/');

    expect(EmployeeEndpoints.employees, 'employees/');
    expect(EmployeeEndpoints.me, 'employees/me/');
    expect(EmployeeEndpoints.employee('abc'), 'employees/abc/');
    expect(
      EmployeeEndpoints.profileImage('abc'),
      'employees/abc/profile-image/',
    );
    expect(EmployeeEndpoints.departments, 'departments/');
    expect(EmployeeEndpoints.positions, 'positions/');

    expect(AttendanceEndpoints.attendance, 'attendance/');
    expect(AttendanceEndpoints.me, 'attendance/me/');
    expect(AttendanceEndpoints.checkIn, 'attendance/check-in/');
    expect(AttendanceEndpoints.checkOut, 'attendance/check-out/');
    expect(AttendanceEndpoints.summary, 'attendance/summary/');
    expect(AttendanceEndpoints.detail('abc'), 'attendance/abc/');

    expect(LeaveEndpoints.types, 'leave/types/');
    expect(LeaveEndpoints.balances, 'leave/balances/');
    expect(LeaveEndpoints.requests, 'leave/requests/');
    expect(LeaveEndpoints.approve('abc'), 'leave/requests/abc/approve/');
    expect(LeaveEndpoints.reject('abc'), 'leave/requests/abc/reject/');
    expect(LeaveEndpoints.cancel('abc'), 'leave/requests/abc/cancel/');
    expect(LeaveEndpoints.attachment('abc'), 'leave/requests/abc/attachment/');

    expect(DeviceEndpoints.devices, 'devices/');
    expect(DeviceEndpoints.assign('abc'), 'devices/abc/assign/');
    expect(DeviceEndpoints.returnDevice('abc'), 'devices/abc/return/');
    expect(DeviceEndpoints.history('abc'), 'devices/abc/history/');

    expect(
      DocumentEndpoints.list('emp-1'),
      'employees/emp-1/documents/',
    );
    expect(
      DocumentEndpoints.download('emp-1', 'doc-1'),
      'employees/emp-1/documents/doc-1/download/',
    );

    expect(NotificationEndpoints.notifications, 'notifications/');
    expect(NotificationEndpoints.unreadCount, 'notifications/unread-count/');
    expect(NotificationEndpoints.markAllRead, 'notifications/mark-all-read/');
    expect(
      NotificationEndpoints.markRead('abc'),
      'notifications/abc/mark-read/',
    );
    expect(NotificationEndpoints.deviceTokens, 'notifications/device-tokens/');

    expect(DashboardEndpoints.admin, 'dashboard/admin/');
    expect(DashboardEndpoints.manager, 'dashboard/manager/');
    expect(DashboardEndpoints.employee, 'dashboard/employee/');

    expect(ReportEndpoints.attendance, 'reports/attendance/');
    expect(ReportEndpoints.attendanceExport, 'reports/attendance/export/');
    expect(ReportEndpoints.leaves, 'reports/leaves/');
    expect(ReportEndpoints.leavesExport, 'reports/leaves/export/');
    expect(ReportEndpoints.employees, 'reports/employees/');
    expect(ReportEndpoints.employeesExport, 'reports/employees/export/');
    expect(ReportEndpoints.devices, 'reports/devices/');
    expect(ReportEndpoints.devicesExport, 'reports/devices/export/');

    expect(AuditLogEndpoints.logs, 'audit-logs/');
    expect(SettingsEndpoints.settings, 'settings/');
  });

  test('login, refresh, and password reset stay public; logout and me do not', () {
    expect(AuthEndpoints.isPublic('auth/login/'), isTrue);
    expect(AuthEndpoints.isPublic('auth/refresh/'), isTrue);
    expect(AuthEndpoints.isPublic('auth/forgot-password/'), isTrue);
    expect(AuthEndpoints.isPublic('auth/reset-password/'), isTrue);
    expect(AuthEndpoints.isPublic('auth/logout/'), isFalse);
    expect(AuthEndpoints.isPublic('auth/me/'), isFalse);
    expect(AuthEndpoints.isPublic('employees/'), isFalse);
  });

  test('list filter query keys match Django FilterSets', () {
    expect(
      const EmployeeQuery(departmentId: 'd', positionId: 'p', managerId: 'm')
          .toQueryParameters()
          .keys,
      containsAll(<String>['department', 'position', 'manager', 'page', 'page_size']),
    );
    expect(
      AttendanceQuery(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        employeeId: 'e',
        departmentId: 'd',
      ).toQueryParameters(),
      containsPair('employee', 'e'),
    );
    expect(
      AttendanceSummaryQuery(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        employeeId: 'e',
      ).toQueryParameters(),
      containsPair('employee_id', 'e'),
    );
    expect(
      const LeaveRequestQuery(leaveTypeId: 't', employeeId: 'e')
          .toQueryParameters(),
      containsPair('leave_type', 't'),
    );
    expect(
      const LeaveRequestQuery(leaveTypeId: 't', employeeId: 'e')
          .toQueryParameters(),
      containsPair('employee', 'e'),
    );
    expect(
      const DeviceQuery(employeeId: 'e', assigned: true).toQueryParameters(),
      containsPair('employee', 'e'),
    );
    expect(
      const AssignDeviceBody(employeeId: 'e').toJson(),
      containsPair('employee_id', 'e'),
    );
    expect(
      CreateLeaveRequestBody(
        leaveTypeId: 't',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 2),
      ).toJson(),
      containsPair('leave_type', 't'),
    );
    expect(
      const ReportQuery(
        kind: ReportKind.attendance,
        employeeId: 'e',
        departmentId: 'd',
      ).toQueryParameters(),
      containsPair('employee', 'e'),
    );
  });

  test('pagination defaults match Django StandardPagination', () {
    expect(AppConstants.defaultPageSize, 20);
    expect(AppConstants.maxPageSize, 100);
  });
}

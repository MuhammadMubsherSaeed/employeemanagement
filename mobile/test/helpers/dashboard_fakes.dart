import 'package:flutter_base/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/domain/repositories/dashboard_repository.dart';

Map<String, dynamic> sampleDashboardRecentEmployeeJson({
  String id = '11111111-1111-1111-1111-111111111111',
  String firstName = 'Ada',
  String lastName = 'Lovelace',
  String status = 'ACTIVE',
}) {
  return <String, dynamic>{
    'id': id,
    'employee_code': 'EMP-001',
    'first_name': firstName,
    'last_name': lastName,
    'profile_image': '',
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
    'status': status,
    'joining_date': '2024-01-15',
    'created_at': '2024-01-15T08:00:00Z',
  };
}

Map<String, dynamic> sampleDashboardActivityJson({
  String id = 'act-1',
  String action = 'Created employee',
  String resource = 'employees.Employee',
  String resourceId = '11111111-1111-1111-1111-111111111111',
  Map<String, dynamic>? actor,
}) {
  return <String, dynamic>{
    'id': id,
    'action': action,
    'resource': resource,
    'resource_id': resourceId,
    'created_at': '2026-08-31T09:00:00Z',
    'actor': actor ?? <String, dynamic>{'id': 10, 'email': 'admin@example.com'},
  };
}

Map<String, dynamic> sampleDashboardTodayAttendanceJson({
  String id = 'att-1',
  String? checkIn = '2026-08-31T09:05:00+05:00',
  String? checkOut,
  int? totalMinutes = 452,
  String status = 'PRESENT',
}) {
  return <String, dynamic>{
    'id': id,
    'date': '2026-08-31',
    'check_in': checkIn,
    'check_out': checkOut,
    'total_minutes': totalMinutes,
    'status': status,
  };
}

Map<String, dynamic> sampleDashboardLeaveBalanceJson() {
  return <String, dynamic>{
    'leave_type': <String, dynamic>{
      'id': 'type-1',
      'name': 'Annual Leave',
      'code': 'ANNUAL',
    },
    'allocated_days': 15,
    'used_days': 3,
    'remaining_days': 12,
    'year': 2026,
  };
}

Map<String, dynamic> sampleDashboardLeaveRequestJson({
  String id = 'req-1',
  String status = 'PENDING',
}) {
  return <String, dynamic>{
    'id': id,
    'leave_type': <String, dynamic>{
      'id': 'type-1',
      'name': 'Annual Leave',
      'code': 'ANNUAL',
    },
    'start_date': '2026-08-15',
    'end_date': '2026-08-18',
    'total_days': 3,
    'status': status,
    'created_at': '2026-08-01T08:00:00Z',
    'rejection_reason': '',
  };
}

Map<String, dynamic> sampleAdminDashboardJson({
  bool empty = false,
  int totalEmployees = 12,
}) {
  return <String, dynamic>{
    'total_employees': totalEmployees,
    'active_employees': 10,
    'inactive_employees': 2,
    'present_today': 8,
    'absent_today': 1,
    'late_today': 1,
    'on_leave_today': 2,
    'pending_leave_requests': empty ? 0 : 4,
    'recent_employees': empty
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[sampleDashboardRecentEmployeeJson()],
    'recent_activity': empty
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[sampleDashboardActivityJson()],
  };
}

Map<String, dynamic> sampleManagerDashboardJson({bool empty = false}) {
  return <String, dynamic>{
    'team_size': 6,
    'team_present': 4,
    'team_absent': 1,
    'team_late': 1,
    'team_on_leave': 0,
    'pending_leave_requests': empty ? 0 : 2,
    'recent_activity': empty
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[
            sampleDashboardActivityJson(
              resource: 'leave.LeaveRequest',
              resourceId: 'req-1',
              action: 'Leave requested',
            ),
          ],
  };
}

Map<String, dynamic> sampleEmployeeDashboardJson({
  bool empty = false,
  int notificationsCount = 3,
  int workingMinutes = 452,
}) {
  return <String, dynamic>{
    'today_attendance': empty ? null : sampleDashboardTodayAttendanceJson(),
    'working_minutes': empty ? 0 : workingMinutes,
    'leave_balances': empty
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[sampleDashboardLeaveBalanceJson()],
    'recent_leave_requests': empty
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[sampleDashboardLeaveRequestJson()],
    'assigned_devices': empty
        ? <Map<String, dynamic>>[]
        : <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'dev-1',
              'asset_code': 'LAP-001',
              'type': 'Laptop',
              'manufacturer': 'Lenovo',
              'model': 'ThinkPad T14',
              'serial_number': 'SN-001',
              'status': 'ASSIGNED',
              'purchase_date': '2026-01-15',
              'warranty_expiry': '2028-01-15',
              'created_at': '2026-01-20T08:00:00Z',
            },
          ],
    'notifications_count': empty ? 0 : notificationsCount,
  };
}

AdminDashboard sampleAdminDashboard({bool empty = false, int total = 12}) {
  return AdminDashboard.fromJson(
    sampleAdminDashboardJson(empty: empty, totalEmployees: total),
  );
}

ManagerDashboard sampleManagerDashboard({bool empty = false}) {
  return ManagerDashboard.fromJson(sampleManagerDashboardJson(empty: empty));
}

EmployeeDashboard sampleEmployeeDashboard({
  bool empty = false,
  int notificationsCount = 3,
}) {
  return EmployeeDashboard.fromJson(
    sampleEmployeeDashboardJson(
      empty: empty,
      notificationsCount: notificationsCount,
    ),
  );
}

class FakeDashboardRemote implements DashboardRemoteDataSource {
  FakeDashboardRemote({
    AdminDashboard? admin,
    ManagerDashboard? manager,
    EmployeeDashboard? employee,
  })  : admin = admin ?? sampleAdminDashboard(),
        manager = manager ?? sampleManagerDashboard(),
        employee = employee ?? sampleEmployeeDashboard();

  AdminDashboard admin;
  ManagerDashboard manager;
  EmployeeDashboard employee;
  Object? adminError;
  Object? managerError;
  Object? employeeError;
  int adminCalls = 0;
  int managerCalls = 0;
  int employeeCalls = 0;

  @override
  Future<AdminDashboard> getAdminDashboard() async {
    adminCalls += 1;
    if (adminError != null) {
      throw adminError!;
    }
    return admin;
  }

  @override
  Future<ManagerDashboard> getManagerDashboard() async {
    managerCalls += 1;
    if (managerError != null) {
      throw managerError!;
    }
    return manager;
  }

  @override
  Future<EmployeeDashboard> getEmployeeDashboard() async {
    employeeCalls += 1;
    if (employeeError != null) {
      throw employeeError!;
    }
    return employee;
  }
}

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({
    AdminDashboard? admin,
    ManagerDashboard? manager,
    EmployeeDashboard? employee,
  })  : admin = admin ?? sampleAdminDashboard(),
        manager = manager ?? sampleManagerDashboard(),
        employee = employee ?? sampleEmployeeDashboard();

  AdminDashboard admin;
  ManagerDashboard manager;
  EmployeeDashboard employee;
  Object? adminError;
  Object? managerError;
  Object? employeeError;
  Duration delay = Duration.zero;
  int adminCalls = 0;
  int managerCalls = 0;
  int employeeCalls = 0;

  Future<void> _wait() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  @override
  Future<AdminDashboard> getAdminDashboard() async {
    adminCalls += 1;
    await _wait();
    if (adminError != null) {
      throw adminError!;
    }
    return admin;
  }

  @override
  Future<ManagerDashboard> getManagerDashboard() async {
    managerCalls += 1;
    await _wait();
    if (managerError != null) {
      throw managerError!;
    }
    return manager;
  }

  @override
  Future<EmployeeDashboard> getEmployeeDashboard() async {
    employeeCalls += 1;
    await _wait();
    if (employeeError != null) {
      throw employeeError!;
    }
    return employee;
  }
}

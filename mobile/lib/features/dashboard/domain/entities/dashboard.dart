import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';

class DashboardActor extends Equatable {
  const DashboardActor({
    this.id,
    this.email,
  });

  final int? id;
  final String? email;

  factory DashboardActor.fromJson(Map<String, dynamic> json) {
    return DashboardActor(
      id: _readInt(json['id']),
      email: _readOptionalString(json['email']),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, email];
}

class DashboardActivity extends Equatable {
  const DashboardActivity({
    required this.id,
    required this.action,
    required this.resource,
    required this.resourceId,
    this.createdAt,
    this.actor,
  });

  final String id;
  final String action;
  final String resource;
  final String resourceId;
  final DateTime? createdAt;
  final DashboardActor? actor;

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: _readString(json['id']),
      action: _readString(json['action']),
      resource: _readString(json['resource']),
      resourceId: _readString(json['resource_id']),
      createdAt: _readDateTime(json['created_at']),
      actor: _readActor(json['actor']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        action,
        resource,
        resourceId,
        createdAt,
        actor,
      ];
}

class AdminDashboard extends Equatable {
  const AdminDashboard({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.inactiveEmployees,
    required this.presentToday,
    required this.absentToday,
    required this.lateToday,
    required this.onLeaveToday,
    required this.pendingLeaveRequests,
    this.recentEmployees = const <Employee>[],
    this.recentActivity = const <DashboardActivity>[],
  });

  final int totalEmployees;
  final int activeEmployees;
  final int inactiveEmployees;
  final int presentToday;
  final int absentToday;
  final int lateToday;
  final int onLeaveToday;
  final int pendingLeaveRequests;
  final List<Employee> recentEmployees;
  final List<DashboardActivity> recentActivity;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalEmployees: _readInt(json['total_employees']) ?? 0,
      activeEmployees: _readInt(json['active_employees']) ?? 0,
      inactiveEmployees: _readInt(json['inactive_employees']) ?? 0,
      presentToday: _readInt(json['present_today']) ?? 0,
      absentToday: _readInt(json['absent_today']) ?? 0,
      lateToday: _readInt(json['late_today']) ?? 0,
      onLeaveToday: _readInt(json['on_leave_today']) ?? 0,
      pendingLeaveRequests: _readInt(json['pending_leave_requests']) ?? 0,
      recentEmployees: _readEmployees(json['recent_employees']),
      recentActivity: _readActivity(json['recent_activity']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        totalEmployees,
        activeEmployees,
        inactiveEmployees,
        presentToday,
        absentToday,
        lateToday,
        onLeaveToday,
        pendingLeaveRequests,
        recentEmployees,
        recentActivity,
      ];
}

class ManagerDashboard extends Equatable {
  const ManagerDashboard({
    required this.teamSize,
    required this.teamPresent,
    required this.teamAbsent,
    required this.teamLate,
    required this.teamOnLeave,
    required this.pendingLeaveRequests,
    this.recentActivity = const <DashboardActivity>[],
  });

  final int teamSize;
  final int teamPresent;
  final int teamAbsent;
  final int teamLate;
  final int teamOnLeave;
  final int pendingLeaveRequests;
  final List<DashboardActivity> recentActivity;

  factory ManagerDashboard.fromJson(Map<String, dynamic> json) {
    return ManagerDashboard(
      teamSize: _readInt(json['team_size']) ?? 0,
      teamPresent: _readInt(json['team_present']) ?? 0,
      teamAbsent: _readInt(json['team_absent']) ?? 0,
      teamLate: _readInt(json['team_late']) ?? 0,
      teamOnLeave: _readInt(json['team_on_leave']) ?? 0,
      pendingLeaveRequests: _readInt(json['pending_leave_requests']) ?? 0,
      recentActivity: _readActivity(json['recent_activity']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        teamSize,
        teamPresent,
        teamAbsent,
        teamLate,
        teamOnLeave,
        pendingLeaveRequests,
        recentActivity,
      ];
}

class EmployeeDashboard extends Equatable {
  const EmployeeDashboard({
    required this.workingMinutes,
    required this.notificationsCount,
    this.todayAttendance,
    this.leaveBalances = const <LeaveBalance>[],
    this.recentLeaveRequests = const <LeaveRequest>[],
    this.assignedDevices = const <Device>[],
  });

  final AttendanceRecord? todayAttendance;
  final int workingMinutes;
  final List<LeaveBalance> leaveBalances;
  final List<LeaveRequest> recentLeaveRequests;
  final List<Device> assignedDevices;
  final int notificationsCount;

  factory EmployeeDashboard.fromJson(Map<String, dynamic> json) {
    return EmployeeDashboard(
      todayAttendance: _readAttendance(json['today_attendance']),
      workingMinutes: _readInt(json['working_minutes']) ?? 0,
      leaveBalances: _readBalances(json['leave_balances']),
      recentLeaveRequests: _readLeaveRequests(json['recent_leave_requests']),
      assignedDevices: _readDevices(json['assigned_devices']),
      notificationsCount: _readInt(json['notifications_count']) ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        todayAttendance,
        workingMinutes,
        leaveBalances,
        recentLeaveRequests,
        assignedDevices,
        notificationsCount,
      ];
}

AttendanceRecord? _readAttendance(dynamic value) {
  if (value is Map) {
    return AttendanceRecord.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

DashboardActor? _readActor(dynamic value) {
  if (value is Map) {
    return DashboardActor.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

List<Employee> _readEmployees(dynamic value) {
  if (value is! List) {
    return const <Employee>[];
  }
  return value
      .whereType<Map>()
      .map((Map row) => Employee.fromJson(Map<String, dynamic>.from(row)))
      .toList();
}

List<DashboardActivity> _readActivity(dynamic value) {
  if (value is! List) {
    return const <DashboardActivity>[];
  }
  return value
      .whereType<Map>()
      .map(
        (Map row) => DashboardActivity.fromJson(Map<String, dynamic>.from(row)),
      )
      .toList();
}

List<LeaveBalance> _readBalances(dynamic value) {
  if (value is! List) {
    return const <LeaveBalance>[];
  }
  return value
      .whereType<Map>()
      .map((Map row) => LeaveBalance.fromJson(Map<String, dynamic>.from(row)))
      .toList();
}

List<LeaveRequest> _readLeaveRequests(dynamic value) {
  if (value is! List) {
    return const <LeaveRequest>[];
  }
  return value
      .whereType<Map>()
      .map((Map row) => LeaveRequest.fromJson(Map<String, dynamic>.from(row)))
      .toList();
}

List<Device> _readDevices(dynamic value) {
  if (value is! List) {
    return const <Device>[];
  }
  return value
      .whereType<Map>()
      .map((Map row) => Device.fromJson(Map<String, dynamic>.from(row)))
      .toList();
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

DateTime? _readDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

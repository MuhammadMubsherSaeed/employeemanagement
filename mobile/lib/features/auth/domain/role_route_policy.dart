import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_base/features/reports/domain/report_access.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';

/// Role → route access. Backend authorization remains mandatory.
class RoleRoutePolicy {
  const RoleRoutePolicy();

  bool canAccess({
    required UserRole role,
    required String path,
  }) {
    final EmployeeAccess access = EmployeeAccess(role);
    if (path == AppRoutes.employeesAdd) {
      return access.canCreate;
    }
    if (path.startsWith('${AppRoutes.employees}/') && path.endsWith('/edit')) {
      return access.canUpdate;
    }
    if (path == AppRoutes.employees ||
        path == AppRoutes.employeesMe ||
        path.startsWith('${AppRoutes.employees}/')) {
      return true;
    }
    if (path == AppRoutes.attendance ||
        path == AppRoutes.attendanceHistory ||
        path == AppRoutes.attendanceCalendar ||
        path.startsWith('${AppRoutes.attendance}/')) {
      return AttendanceAccess(role).canView;
    }
    final LeaveAccess leave = LeaveAccess(role);
    if (path == AppRoutes.leavesApply) {
      return leave.canCreate;
    }
    if (path == AppRoutes.leavesTypes ||
        path == AppRoutes.leavesTypesAdd ||
        path.startsWith('${AppRoutes.leavesTypes}/')) {
      return leave.canManage;
    }
    if (path.startsWith('${AppRoutes.leaves}/approval/')) {
      return leave.canApprove;
    }
    if (path == AppRoutes.leaves ||
        path == AppRoutes.leavesBalances ||
        path == AppRoutes.leavesRequests ||
        path == AppRoutes.leavesHistory ||
        path.startsWith('${AppRoutes.leaves}/')) {
      return leave.canView;
    }
    final DeviceAccess devices = DeviceAccess(role);
    if (path == AppRoutes.devicesAdd) {
      return devices.canCreate;
    }
    if (path.startsWith('${AppRoutes.devices}/') && path.endsWith('/edit')) {
      return devices.canUpdate;
    }
    if (path.startsWith('${AppRoutes.devices}/') && path.endsWith('/assign')) {
      return devices.canAssign;
    }
    if (path == AppRoutes.devices ||
        path == AppRoutes.myDevices ||
        path.startsWith('${AppRoutes.devices}/')) {
      return devices.canView;
    }
    if (path == AppRoutes.notifications ||
        path.startsWith('${AppRoutes.notifications}/')) {
      return NotificationAccess(role).canView;
    }
    if (path == AppRoutes.reports ||
        path.startsWith('${AppRoutes.reports}/')) {
      return ReportAccess(role).canView;
    }
    if (path == AppRoutes.settings ||
        path.startsWith('${AppRoutes.settings}/')) {
      return SettingsAccess(role).canView;
    }
    return true;
  }
}

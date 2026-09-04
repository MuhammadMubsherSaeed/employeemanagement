import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/attendance/domain/attendance_access.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/documents/domain/document_access.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';
import 'package:flutter_base/features/reports/domain/report_access.dart';
import 'package:flutter_base/features/settings/domain/settings_access.dart';

/// Permission-aware route access. Backend authorization remains mandatory.
class RoleRoutePolicy {
  const RoleRoutePolicy();

  bool canAccess({
    required Authorization auth,
    required String path,
  }) {
    if (path == AppRoutes.accessDenied ||
        path == AppRoutes.home ||
        path == AppRoutes.dashboard) {
      return true;
    }
    final EmployeeAccess employees = EmployeeAccess(auth);
    if (path == AppRoutes.employeesAdd) {
      return employees.canCreate;
    }
    if (path.startsWith('${AppRoutes.employees}/') && path.endsWith('/edit')) {
      return employees.canUpdate;
    }
    if (path.contains('/documents')) {
      final DocumentAccess documents = DocumentAccess(auth);
      if (path.endsWith('/upload')) {
        return documents.canUpload;
      }
      if (path.endsWith('/preview')) {
        return documents.canDownload;
      }
      return documents.canView;
    }
    if (path == AppRoutes.employees ||
        path == AppRoutes.employeesMe ||
        path.startsWith('${AppRoutes.employees}/')) {
      return employees.canView;
    }
    if (path == AppRoutes.attendance ||
        path == AppRoutes.attendanceHistory ||
        path == AppRoutes.attendanceCalendar ||
        path.startsWith('${AppRoutes.attendance}/')) {
      return AttendanceAccess(auth).canView;
    }
    final LeaveAccess leave = LeaveAccess(auth);
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
    final DeviceAccess devices = DeviceAccess(auth);
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
      return NotificationAccess(auth).canView;
    }
    if (path == AppRoutes.reports ||
        path.startsWith('${AppRoutes.reports}/')) {
      return ReportAccess(auth).canView;
    }
    if (path == AppRoutes.auditLogs ||
        path.startsWith('${AppRoutes.auditLogs}/')) {
      return auth.hasPermission(Permissions.auditLogsView) && auth.hasTenant;
    }
    if (path == AppRoutes.settings ||
        path.startsWith('${AppRoutes.settings}/')) {
      return SettingsAccess(auth).canView;
    }
    return true;
  }
}

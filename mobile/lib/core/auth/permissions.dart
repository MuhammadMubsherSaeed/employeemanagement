/// Backend permission codes from `apps.accounts.rbac_catalog.PERMISSION_CODES`.
///
/// Do not invent Flutter-only codes. Action availability must use these strings.
class Permissions {
  Permissions._();

  static const String employeesView = 'employees.view';
  static const String employeesCreate = 'employees.create';
  static const String employeesUpdate = 'employees.update';
  static const String employeesDelete = 'employees.delete';

  static const String attendanceView = 'attendance.view';
  static const String attendanceManage = 'attendance.manage';
  static const String attendanceCheckIn = 'attendance.check_in';
  static const String attendanceCheckOut = 'attendance.check_out';

  static const String leaveView = 'leave.view';
  static const String leaveCreate = 'leave.create';
  static const String leaveApprove = 'leave.approve';
  static const String leaveReject = 'leave.reject';
  static const String leaveManage = 'leave.manage';

  static const String devicesView = 'devices.view';
  static const String devicesCreate = 'devices.create';
  static const String devicesUpdate = 'devices.update';
  static const String devicesAssign = 'devices.assign';
  static const String devicesReturn = 'devices.return';
  static const String devicesDelete = 'devices.delete';

  static const String documentsView = 'documents.view';
  static const String documentsCreate = 'documents.create';
  static const String documentsUpdate = 'documents.update';
  static const String documentsDelete = 'documents.delete';
  static const String documentsDownload = 'documents.download';

  static const String notificationsView = 'notifications.view';
  static const String notificationsMarkRead = 'notifications.mark_read';
  static const String notificationsManage = 'notifications.manage';

  static const String dashboardAdminView = 'dashboard.admin.view';
  static const String dashboardManagerView = 'dashboard.manager.view';
  static const String dashboardEmployeeView = 'dashboard.employee.view';

  static const String reportsView = 'reports.view';
  static const String reportsExport = 'reports.export';

  static const String settingsManage = 'settings.manage';

  static const String auditLogsView = 'audit_logs.view';

  /// Full catalog. Used when the API materializes platform-admin codes.
  static const List<String> all = <String>[
    employeesView,
    employeesCreate,
    employeesUpdate,
    employeesDelete,
    attendanceView,
    attendanceManage,
    attendanceCheckIn,
    attendanceCheckOut,
    leaveView,
    leaveCreate,
    leaveApprove,
    leaveReject,
    leaveManage,
    devicesView,
    devicesCreate,
    devicesUpdate,
    devicesAssign,
    devicesReturn,
    devicesDelete,
    documentsView,
    documentsCreate,
    documentsUpdate,
    documentsDelete,
    documentsDownload,
    notificationsView,
    notificationsMarkRead,
    notificationsManage,
    dashboardAdminView,
    dashboardManagerView,
    dashboardEmployeeView,
    reportsView,
    reportsExport,
    settingsManage,
    auditLogsView,
  ];
}

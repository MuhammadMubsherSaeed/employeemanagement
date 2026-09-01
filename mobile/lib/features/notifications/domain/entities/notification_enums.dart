enum AppNotificationType {
  leaveSubmitted('LEAVE_SUBMITTED', 'Leave submitted'),
  leaveApproved('LEAVE_APPROVED', 'Leave approved'),
  leaveRejected('LEAVE_REJECTED', 'Leave rejected'),
  leaveCancelled('LEAVE_CANCELLED', 'Leave cancelled'),
  deviceAssigned('DEVICE_ASSIGNED', 'Device assigned'),
  deviceReturned('DEVICE_RETURNED', 'Device returned'),
  attendanceReminder('ATTENDANCE_REMINDER', 'Attendance reminder'),
  attendanceLate('ATTENDANCE_LATE', 'Attendance late'),
  documentExpiring('DOCUMENT_EXPIRING', 'Document expiring'),
  system('SYSTEM', 'System'),
  unknown('UNKNOWN', 'Notification');

  const AppNotificationType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isLeave =>
      this == AppNotificationType.leaveSubmitted ||
      this == AppNotificationType.leaveApproved ||
      this == AppNotificationType.leaveRejected ||
      this == AppNotificationType.leaveCancelled;

  bool get isDevice =>
      this == AppNotificationType.deviceAssigned ||
      this == AppNotificationType.deviceReturned;

  bool get isAttendance =>
      this == AppNotificationType.attendanceReminder ||
      this == AppNotificationType.attendanceLate;

  bool get isDocument => this == AppNotificationType.documentExpiring;

  static AppNotificationType fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final AppNotificationType item in AppNotificationType.values) {
      if (item != AppNotificationType.unknown && item.apiValue == value) {
        return item;
      }
    }
    return AppNotificationType.unknown;
  }
}

enum NotificationEntityType {
  leaveRequest('leave_request', 'Leave request'),
  device('device', 'Device'),
  attendance('attendance', 'Attendance'),
  employeeDocument('employee_document', 'Document'),
  unknown('', 'Item');

  const NotificationEntityType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static NotificationEntityType fromApi(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return NotificationEntityType.unknown;
    }
    for (final NotificationEntityType item in NotificationEntityType.values) {
      if (item != NotificationEntityType.unknown && item.apiValue == value) {
        return item;
      }
    }
    return NotificationEntityType.unknown;
  }
}

enum DeviceTokenPlatform {
  android('ANDROID', 'Android'),
  ios('IOS', 'iOS'),
  web('WEB', 'Web'),
  unknown('UNKNOWN', 'Unknown');

  const DeviceTokenPlatform(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DeviceTokenPlatform fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final DeviceTokenPlatform item in DeviceTokenPlatform.values) {
      if (item != DeviceTokenPlatform.unknown && item.apiValue == value) {
        return item;
      }
    }
    return DeviceTokenPlatform.unknown;
  }
}

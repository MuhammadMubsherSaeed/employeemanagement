import 'package:flutter/material.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';

class NotificationPresentation {
  NotificationPresentation._();

  static IconData icon(AppNotificationType type) {
    if (type.isLeave) {
      return Icons.event_available_outlined;
    }
    if (type.isDevice) {
      return Icons.devices_other_outlined;
    }
    if (type.isAttendance) {
      return Icons.schedule_outlined;
    }
    if (type.isDocument) {
      return Icons.description_outlined;
    }
    return Icons.notifications_outlined;
  }

  static String category(AppNotificationType type) {
    if (type.isLeave) {
      return 'Leave';
    }
    if (type.isDevice) {
      return 'Device';
    }
    if (type.isAttendance) {
      return 'Attendance';
    }
    if (type.isDocument) {
      return 'Document';
    }
    if (type == AppNotificationType.system) {
      return 'System';
    }
    return 'Notification';
  }
}

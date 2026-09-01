import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/notification_access.dart';

class NotificationDestination {
  const NotificationDestination({
    required this.location,
    this.isInboxFallback = false,
  });

  final String location;
  final bool isInboxFallback;

  bool get isDetails =>
      location.startsWith('${AppRoutes.notifications}/') &&
      location != AppRoutes.notifications;
}

class NotificationNavigationService {
  const NotificationNavigationService();

  NotificationDestination destination({
    required AppNotification notification,
    required UserRole role,
  }) {
    final NotificationAccess access = NotificationAccess(role);
    if (!access.canView) {
      return NotificationDestination(
        location: AppRoutes.notification(notification.id),
        isInboxFallback: true,
      );
    }

    switch (notification.type) {
      case AppNotificationType.leaveSubmitted:
        if (_hasEntity(notification, NotificationEntityType.leaveRequest)) {
          return NotificationDestination(
            location: AppRoutes.leaveRequest(notification.entityId!),
          );
        }
        if (LeaveAccess(role).canApprove) {
          return const NotificationDestination(
            location: AppRoutes.leavesRequests,
          );
        }
        return NotificationDestination(
          location: AppRoutes.notification(notification.id),
          isInboxFallback: true,
        );
      case AppNotificationType.leaveApproved:
      case AppNotificationType.leaveRejected:
      case AppNotificationType.leaveCancelled:
        if (_hasEntity(notification, NotificationEntityType.leaveRequest)) {
          return NotificationDestination(
            location: AppRoutes.leaveRequest(notification.entityId!),
          );
        }
        return NotificationDestination(
          location: AppRoutes.notification(notification.id),
          isInboxFallback: true,
        );
      case AppNotificationType.deviceAssigned:
      case AppNotificationType.deviceReturned:
        if (_hasEntity(notification, NotificationEntityType.device) &&
            access.canOpenDevice) {
          return NotificationDestination(
            location: AppRoutes.device(notification.entityId!),
          );
        }
        return NotificationDestination(
          location: AppRoutes.notification(notification.id),
          isInboxFallback: true,
        );
      case AppNotificationType.attendanceReminder:
        return const NotificationDestination(location: AppRoutes.attendance);
      case AppNotificationType.attendanceLate:
        if (_hasEntity(notification, NotificationEntityType.attendance) &&
            access.canOpenAttendance) {
          return NotificationDestination(
            location: AppRoutes.attendanceDetail(notification.entityId!),
          );
        }
        return const NotificationDestination(location: AppRoutes.attendance);
      case AppNotificationType.documentExpiring:
      case AppNotificationType.system:
      case AppNotificationType.unknown:
        return NotificationDestination(
          location: AppRoutes.notification(notification.id),
          isInboxFallback: true,
        );
    }
  }

  String? relatedActionLabel(AppNotification notification) {
    if (!notification.hasEntity) {
      return null;
    }
    switch (notification.entityType) {
      case NotificationEntityType.leaveRequest:
        return 'View leave request';
      case NotificationEntityType.device:
        return 'View device';
      case NotificationEntityType.attendance:
        return 'View attendance';
      case NotificationEntityType.employeeDocument:
      case NotificationEntityType.unknown:
        return null;
    }
  }

  bool _hasEntity(
    AppNotification notification,
    NotificationEntityType expected,
  ) {
    return notification.entityType == expected &&
        notification.entityId != null &&
        notification.entityId!.trim().isNotEmpty;
  }
}

import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/services/notification_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/notification_fakes.dart';

void main() {
  const NotificationNavigationService navigation =
      NotificationNavigationService();

  test('LEAVE_SUBMITTED goes to leave request details when entity exists', () {
    final NotificationDestination dest = navigation.destination(
      notification: sampleNotification(
        type: AppNotificationType.leaveSubmitted,
        entityType: NotificationEntityType.leaveRequest,
        entityId: 'leave-1',
      ),
      auth: Authorization.fromUser(managerUser),
    );
    expect(dest.location, AppRoutes.leaveRequest('leave-1'));
    expect(dest.isInboxFallback, isFalse);
  });

  test('LEAVE_SUBMITTED without entity goes to team requests for managers', () {
    final NotificationDestination dest = navigation.destination(
      notification: sampleNotification(
        type: AppNotificationType.leaveSubmitted,
      ),
      auth: Authorization.fromUser(managerUser),
    );
    expect(dest.location, AppRoutes.leavesRequests);
  });

  test('LEAVE_APPROVED and REJECTED use leave request details', () {
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              type: AppNotificationType.leaveApproved,
              entityType: NotificationEntityType.leaveRequest,
              entityId: 'leave-2',
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.leaveRequest('leave-2'),
    );
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              type: AppNotificationType.leaveRejected,
              entityType: NotificationEntityType.leaveRequest,
              entityId: 'leave-3',
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.leaveRequest('leave-3'),
    );
  });

  test('device assigned and returned open device details', () {
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              type: AppNotificationType.deviceAssigned,
              entityType: NotificationEntityType.device,
              entityId: 'dev-1',
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.device('dev-1'),
    );
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              type: AppNotificationType.deviceReturned,
              entityType: NotificationEntityType.device,
              entityId: 'dev-1',
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.device('dev-1'),
    );
  });

  test('attendance reminder opens dashboard; late uses detail when present', () {
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              type: AppNotificationType.attendanceReminder,
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.attendance,
    );
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              type: AppNotificationType.attendanceLate,
              entityType: NotificationEntityType.attendance,
              entityId: 'att-1',
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.attendanceDetail('att-1'),
    );
  });

  test('document, system, unknown, and missing entity IDs fall back to details',
      () {
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              id: 'n-doc',
              type: AppNotificationType.documentExpiring,
              entityType: NotificationEntityType.employeeDocument,
              entityId: 'doc-1',
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.notification('n-doc'),
    );
    expect(
      navigation
          .destination(
            notification: sampleNotification(id: 'n-sys'),
            auth: Authorization.fromUser(sampleUser),
          )
          .isInboxFallback,
      isTrue,
    );
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              id: 'n-unknown',
              type: AppNotificationType.unknown,
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .location,
      AppRoutes.notification('n-unknown'),
    );
    expect(
      navigation
          .destination(
            notification: sampleNotification(
              id: 'n-leave',
              type: AppNotificationType.leaveApproved,
            ),
            auth: Authorization.fromUser(sampleUser),
          )
          .isInboxFallback,
      isTrue,
    );
  });

  test('related action labels match supported entity types', () {
    expect(
      navigation.relatedActionLabel(
        sampleNotification(
          entityType: NotificationEntityType.leaveRequest,
          entityId: 'leave-1',
        ),
      ),
      'View leave request',
    );
    expect(
      navigation.relatedActionLabel(
        sampleNotification(
          type: AppNotificationType.documentExpiring,
          entityType: NotificationEntityType.employeeDocument,
          entityId: 'doc-1',
        ),
      ),
      isNull,
    );
  });
}

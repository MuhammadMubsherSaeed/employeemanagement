import 'package:flutter_base/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/notification_fakes.dart';

void main() {
  test('repository forwards inbox, unread, mark-read, and device tokens',
      () async {
    final FakeNotificationRemote remote = FakeNotificationRemote();
    final NotificationRepositoryImpl repository =
        NotificationRepositoryImpl(remote);
    const NotificationQuery query = NotificationQuery(isRead: false);

    expect((await repository.getNotifications(query)).results, isNotEmpty);
    expect(remote.lastQuery, query);
    expect((await repository.getNotificationDetail('n-9')).id, 'n-9');
    expect(await repository.getUnreadCount(), 2);
    expect((await repository.markAsRead('n-1')).isRead, isTrue);
    expect(await repository.markAllAsRead(), 3);

    final DeviceTokenRegistration registered =
        await repository.registerDeviceToken(
      const RegisterDeviceTokenBody(
        token: 'fcm-token-12345678',
        platform: DeviceTokenPlatform.android,
      ),
    );
    expect(registered.id, 'tok-1');
    expect(remote.lastRegister?.token, 'fcm-token-12345678');

    await repository.updateDeviceToken(
      'tok-1',
      const UpdateDeviceTokenBody(deviceName: 'Pixel'),
    );
    expect(remote.lastUpdate?.deviceName, 'Pixel');
    await repository.removeDeviceToken('tok-1');
    expect(remote.lastId, 'tok-1');
  });
}

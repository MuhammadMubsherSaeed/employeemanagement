import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_base/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/notification_fakes.dart';

void main() {
  test('use cases delegate to the repository', () async {
    final FakeNotificationRepository repository = FakeNotificationRepository();

    expect(
      (await GetNotifications(repository)(const NotificationQuery())).count,
      1,
    );
    expect((await GetNotificationDetail(repository)('n-1')).id, 'n-1');
    expect(await GetUnreadNotificationCount(repository)(), 2);
    expect((await MarkNotificationAsRead(repository)('n-1')).isRead, isTrue);
    expect(await MarkAllNotificationsAsRead(repository)(), 1);
    expect(
      (await RegisterDeviceToken(repository)(
        const RegisterDeviceTokenBody(
          token: 'fcm-token-12345678',
          platform: DeviceTokenPlatform.android,
        ),
      )).id,
      'tok-1',
    );
    expect(repository.registerCalls, 1);
    await UpdateDeviceToken(repository)(
      'tok-1',
      const UpdateDeviceTokenBody(token: 'fcm-token-99999999'),
    );
    expect(repository.updateCalls, 1);
    await RemoveDeviceToken(repository)('tok-1');
    expect(repository.removeCalls, 1);
  });
}

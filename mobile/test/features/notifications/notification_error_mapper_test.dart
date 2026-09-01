import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps network, forbidden, and not-found errors', () {
    expect(
      NotificationErrorMapper.message(const NetworkException()),
      contains('internet'),
    );
    expect(
      NotificationErrorMapper.message(const ForbiddenException()),
      'You no longer have access to this item.',
    );
    expect(
      NotificationErrorMapper.message(const NotFoundException()),
      'This notification could not be found.',
    );
    expect(
      NotificationErrorMapper.message(
        const NotFoundException(),
        relatedEntity: true,
      ),
      'This item is no longer available.',
    );
  });
}

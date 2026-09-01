import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/dashboard_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps network, timeout, unauthorized, forbidden, and not found', () {
    expect(
      DashboardErrorMapper.message(const NetworkException()),
      contains('internet'),
    );
    expect(
      DashboardErrorMapper.message(const TimeoutException()),
      contains('timed out'),
    );
    expect(
      DashboardErrorMapper.message(const UnauthorizedException()),
      'Please sign in again.',
    );
    expect(
      DashboardErrorMapper.message(const ForbiddenException()),
      DashboardErrorMapper.forbidden,
    );
    expect(
      DashboardErrorMapper.message(const NotFoundException()),
      DashboardErrorMapper.notFound,
    );
    expect(
      DashboardErrorMapper.message(const ServerException('boom', 500)),
      'boom',
    );
  });
}

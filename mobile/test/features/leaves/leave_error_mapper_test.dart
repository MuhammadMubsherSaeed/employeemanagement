import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps network, forbidden, not found, and backend messages', () {
    expect(
      LeaveErrorMapper.message(const NetworkException()),
      contains('internet'),
    );
    expect(
      LeaveErrorMapper.message(const ForbiddenException()),
      LeaveErrorMapper.forbidden,
    );
    expect(
      LeaveErrorMapper.message(const NotFoundException()),
      LeaveErrorMapper.notFound,
    );
    expect(
      LeaveErrorMapper.message(const UnauthorizedException()),
      'Please sign in again.',
    );
    expect(
      LeaveErrorMapper.message(
        const ValidationException('Insufficient leave balance.'),
      ),
      'Insufficient leave balance.',
    );
    expect(
      LeaveErrorMapper.fieldErrors(
        const ValidationException(
          'Validation failed.',
          fieldErrors: <String, List<String>>{
            'start_date': <String>['End date must not be before start date.'],
          },
        ),
      )['start_date'],
      'End date must not be before start date.',
    );
  });
}

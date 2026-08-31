import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps network, forbidden, not found, and backend messages', () {
    expect(
      DeviceErrorMapper.message(const NetworkException()),
      contains('internet'),
    );
    expect(
      DeviceErrorMapper.message(const ForbiddenException()),
      DeviceErrorMapper.forbidden,
    );
    expect(
      DeviceErrorMapper.message(const NotFoundException()),
      DeviceErrorMapper.notFound,
    );
    expect(
      DeviceErrorMapper.message(const UnauthorizedException()),
      'Please sign in again.',
    );
    expect(
      DeviceErrorMapper.message(
        const ValidationException('This device is already assigned.'),
      ),
      'This device is already assigned.',
    );
    expect(
      DeviceErrorMapper.fieldErrors(
        const ValidationException(
          'Validation failed.',
          fieldErrors: <String, List<String>>{
            'employee_id': <String>['Unknown employee.'],
          },
        ),
      )['employee_id'],
      'Unknown employee.',
    );
  });
}

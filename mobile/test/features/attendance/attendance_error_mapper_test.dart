import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps network, forbidden, not found, and backend messages', () {
    expect(
      AttendanceErrorMapper.message(const NetworkException()),
      contains('internet'),
    );
    expect(
      AttendanceErrorMapper.message(const ForbiddenException()),
      AttendanceErrorMapper.forbidden,
    );
    expect(
      AttendanceErrorMapper.message(const NotFoundException()),
      AttendanceErrorMapper.notFound,
    );
    expect(
      AttendanceErrorMapper.message(const UnauthorizedException()),
      'Please sign in again.',
    );
    expect(
      AttendanceErrorMapper.message(
        const ValidationException(
          'Attendance has already been checked in for today.',
        ),
      ),
      'Attendance has already been checked in for today.',
    );
    expect(
      AttendanceErrorMapper.message(
        const ValidationException(
          'You must check in before checking out.',
        ),
      ),
      'You must check in before checking out.',
    );
  });
}

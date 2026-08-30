import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps network, forbidden, not found, and validation errors', () {
    expect(
      EmployeeErrorMapper.message(const NetworkException()),
      contains('internet'),
    );
    expect(
      EmployeeErrorMapper.message(const ForbiddenException()),
      EmployeeErrorMapper.forbidden,
    );
    expect(
      EmployeeErrorMapper.message(const NotFoundException()),
      EmployeeErrorMapper.notFound,
    );
    expect(
      EmployeeErrorMapper.message(
        const ValidationException(
          'Invalid.',
          fieldErrors: <String, List<String>>{
            'employee_code': <String>['This code is already used.'],
          },
        ),
      ),
      'This code is already used.',
    );
  });

  test('extracts field errors for forms', () {
    expect(
      EmployeeErrorMapper.fieldErrors(
        const ValidationException(
          'Invalid.',
          fieldErrors: <String, List<String>>{
            'first_name': <String>['Required.'],
            'phone': <String>['Invalid phone.'],
          },
        ),
      ),
      <String, String>{
        'first_name': 'Required.',
        'phone': 'Invalid phone.',
      },
    );
    expect(
      EmployeeErrorMapper.fieldErrors(const NetworkException()),
      isEmpty,
    );
  });
}

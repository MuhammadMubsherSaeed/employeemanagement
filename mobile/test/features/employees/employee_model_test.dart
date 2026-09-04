import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';

void main() {
  test('parses list payload and nested relations from snake_case JSON', () {
    final Employee employee = Employee.fromJson(sampleEmployeeJson());

    expect(employee.id, '11111111-1111-1111-1111-111111111111');
    expect(employee.employeeCode, 'EMP-001');
    expect(employee.firstName, 'Ada');
    expect(employee.lastName, 'Lovelace');
    expect(employee.fullName, 'Ada Lovelace');
    expect(employee.employmentType, EmploymentType.fullTime);
    expect(employee.status, EmployeeStatus.active);
    expect(employee.department?.name, 'Engineering');
    expect(employee.position?.title, 'Engineer');
    expect(employee.manager?.fullName, 'Grace Hopper');
    expect(employee.user?.email, 'ada@example.com');
    expect(employee.hasPrivateContact, isFalse);
  });

  test('parses detail-only private fields', () {
    final Employee employee = Employee.fromJson(sampleEmployeeJson(detail: true));

    expect(employee.gender, EmployeeGender.female);
    expect(employee.phone, '5550100');
    expect(employee.address, '1 Analytical Engine Rd');
    expect(employee.emergencyContactName, 'Lord Byron');
    expect(employee.hasPrivateContact, isTrue);
  });

  test('employment and status enums map Django API values', () {
    expect(EmploymentType.fromApi('PART_TIME'), EmploymentType.partTime);
    expect(EmployeeStatus.fromApi('ON_LEAVE'), EmployeeStatus.onLeave);
    expect(OrgStatus.fromApi('INACTIVE'), OrgStatus.inactive);
    expect(EmploymentType.fromApi('nope'), EmploymentType.unknown);
  });

  test('EmployeeQuery serializes filters without dropping search', () {
    const EmployeeQuery query = EmployeeQuery(
      search: 'Ada',
      departmentId: 'dept-1',
      positionId: 'pos-1',
      status: EmployeeStatus.active,
      employmentType: EmploymentType.fullTime,
      managerId: 'mgr-1',
      ordering: 'first_name',
      page: 2,
    );

    expect(query.activeFilterCount, 5);
    expect(
      query.toQueryParameters(),
      <String, dynamic>{
        'search': 'Ada',
        'department': 'dept-1',
        'position': 'pos-1',
        'status': 'ACTIVE',
        'employment_type': 'FULL_TIME',
        'manager': 'mgr-1',
        'ordering': 'first_name',
        'page': 2,
        'page_size': 20,
      },
    );
    expect(query.clearedFilters().search, 'Ada');
    expect(query.clearedFilters().departmentId, isNull);
  });

  test('EmployeeWrite maps Dart fields to Django snake_case', () {
    final EmployeeWrite write = EmployeeWrite(
      employeeCode: 'EMP-009',
      firstName: 'Alan',
      lastName: 'Turing',
      employmentType: EmploymentType.contract,
      status: EmployeeStatus.active,
      joiningDate: DateTime(2023, 5, 1),
      departmentId: 'dept-1',
      gender: EmployeeGender.male,
    );

    expect(write.toJson()['employee_code'], 'EMP-009');
    expect(write.toJson()['employment_type'], 'CONTRACT');
    expect(write.toJson()['joining_date'], '2023-05-01');
    expect(write.toJson()['department'], 'dept-1');
    expect(write.toJson()['position'], isNull);
    expect(write.toJson().containsKey('profile_image'), isFalse);
  });

  test('EmployeeWrite omits blank profile_image so PATCH cannot wipe storage keys', () {
    const EmployeeWrite blank = EmployeeWrite(
      employeeCode: 'EMP-010',
      firstName: 'Grace',
      lastName: 'Hopper',
      employmentType: EmploymentType.fullTime,
      status: EmployeeStatus.active,
      profileImage: '',
    );
    const EmployeeWrite storageKey = EmployeeWrite(
      employeeCode: 'EMP-011',
      firstName: 'Grace',
      lastName: 'Hopper',
      employmentType: EmploymentType.fullTime,
      status: EmployeeStatus.active,
      profileImage: 'companies/acme/employees/1/profile/x.png',
    );
    const EmployeeWrite publicUrl = EmployeeWrite(
      employeeCode: 'EMP-012',
      firstName: 'Grace',
      lastName: 'Hopper',
      employmentType: EmploymentType.fullTime,
      status: EmployeeStatus.active,
      profileImage: 'https://cdn.example.com/photo.png',
    );

    expect(blank.toJson().containsKey('profile_image'), isFalse);
    expect(storageKey.toJson().containsKey('profile_image'), isFalse);
    expect(publicUrl.toJson()['profile_image'], 'https://cdn.example.com/photo.png');
  });
}

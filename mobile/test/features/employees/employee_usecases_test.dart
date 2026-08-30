import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/domain/usecases/employee_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';

void main() {
  late FakeEmployeeRepository repository;

  setUp(() {
    repository = FakeEmployeeRepository();
  });

  test('employee use cases delegate to the repository', () async {
    final EmployeePage<Employee> page =
        await GetEmployees(repository)(const EmployeeQuery(search: 'Ada'));
    expect(page.results, isNotEmpty);
    expect(repository.listQueries.single.search, 'Ada');

    expect((await GetEmployee(repository)('id-1')).firstName, 'Ada');
    expect((await GetMyEmployee(repository)()).employeeCode, 'EMP-001');

    const EmployeeWrite write = EmployeeWrite(
      employeeCode: 'EMP-002',
      firstName: 'Alan',
      lastName: 'Turing',
      employmentType: EmploymentType.fullTime,
      status: EmployeeStatus.active,
    );
    expect((await CreateEmployee(repository)(write)).id, 'created-1');
    expect((await UpdateEmployee(repository)('id-1', write)).id, 'id-1');
    await DeleteEmployee(repository)('id-1');
    expect(repository.deletedId, 'id-1');
  });

  test('department and position use cases list supporting data', () async {
    expect(
      (await GetDepartments(FakeDepartmentRepository())()).single.name,
      'Engineering',
    );
    expect(
      (await GetPositions(FakePositionRepository())()).single.title,
      'Engineer',
    );
  });
}

import 'package:flutter_base/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';

void main() {
  test('employee repository forwards list, detail, me, and writes', () async {
    final FakeEmployeeRemote remote = FakeEmployeeRemote();
    final EmployeeRepositoryImpl repository = EmployeeRepositoryImpl(remote);
    const EmployeeQuery query = EmployeeQuery(search: 'Ada');

    final EmployeePage<Employee> page = await repository.getEmployees(query);
    expect(page.results, isNotEmpty);
    expect(remote.lastQuery, query);

    final Employee byId = await repository.getEmployeeById('emp-9');
    expect(byId.id, 'emp-9');
    expect(remote.lastId, 'emp-9');

    final Employee me = await repository.getMyEmployeeProfile();
    expect(me.employeeCode, 'EMP-001');

    const EmployeeWrite write = EmployeeWrite(
      employeeCode: 'EMP-002',
      firstName: 'Alan',
      lastName: 'Turing',
      employmentType: EmploymentType.fullTime,
      status: EmployeeStatus.active,
    );
    await repository.createEmployee(write);
    expect(remote.lastWrite, write);

    await repository.updateEmployee('emp-9', write);
    expect(remote.lastId, 'emp-9');

    await repository.deleteEmployee('emp-9');
    expect(remote.lastId, 'emp-9');
  });

  test('department and position repositories list from the shared remote',
      () async {
    final FakeEmployeeRemote remote = FakeEmployeeRemote();
    final DepartmentRepositoryImpl departments =
        DepartmentRepositoryImpl(remote);
    final PositionRepositoryImpl positions = PositionRepositoryImpl(remote);

    expect((await departments.getDepartments()).first.name, 'Engineering');
    expect((await positions.getPositions()).first.title, 'Engineer');
  });
}

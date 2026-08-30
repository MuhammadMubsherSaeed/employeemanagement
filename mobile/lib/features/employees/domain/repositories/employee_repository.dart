import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';

abstract class EmployeeRepository {
  Future<EmployeePage<Employee>> getEmployees(EmployeeQuery query);

  Future<Employee> getEmployeeById(String id);

  Future<Employee> getMyEmployeeProfile();

  Future<Employee> createEmployee(EmployeeWrite body);

  Future<Employee> updateEmployee(String id, EmployeeWrite body);

  Future<void> deleteEmployee(String id);
}

abstract class DepartmentRepository {
  Future<List<Department>> getDepartments({String? status});
}

abstract class PositionRepository {
  Future<List<Position>> getPositions({String? departmentId, String? status});
}

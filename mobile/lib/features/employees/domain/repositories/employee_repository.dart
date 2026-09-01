import 'dart:typed_data';

import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';

abstract class EmployeeRepository {
  Future<EmployeePage<Employee>> getEmployees(EmployeeQuery query);

  Future<Employee> getEmployeeById(String id);

  Future<Employee> getMyEmployeeProfile();

  Future<Employee> createEmployee(EmployeeWrite body);

  Future<Employee> updateEmployee(String id, EmployeeWrite body);

  Future<void> deleteEmployee(String id);

  Future<Uint8List?> getProfileImage(String id);

  Future<Employee> uploadProfileImage({
    required String id,
    required String path,
    required String filename,
  });

  Future<Employee> deleteProfileImage(String id);
}

abstract class DepartmentRepository {
  Future<List<Department>> getDepartments({String? status});
}

abstract class PositionRepository {
  Future<List<Position>> getPositions({String? departmentId, String? status});
}

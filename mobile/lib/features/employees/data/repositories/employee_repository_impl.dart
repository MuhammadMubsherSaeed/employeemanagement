import 'dart:typed_data';

import 'package:flutter_base/features/employees/data/datasources/employee_remote_datasource.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl(this._remote);

  final EmployeeRemoteDataSource _remote;

  @override
  Future<EmployeePage<Employee>> getEmployees(EmployeeQuery query) {
    return _remote.getEmployees(query);
  }

  @override
  Future<Employee> getEmployeeById(String id) {
    return _remote.getEmployeeById(id);
  }

  @override
  Future<Employee> getMyEmployeeProfile() {
    return _remote.getMyEmployeeProfile();
  }

  @override
  Future<Employee> createEmployee(EmployeeWrite body) {
    return _remote.createEmployee(body);
  }

  @override
  Future<Employee> updateEmployee(String id, EmployeeWrite body) {
    return _remote.updateEmployee(id, body);
  }

  @override
  Future<void> deleteEmployee(String id) {
    return _remote.deleteEmployee(id);
  }

  @override
  Future<Uint8List?> getProfileImage(String id) {
    return _remote.getProfileImage(id);
  }

  @override
  Future<Employee> uploadProfileImage({
    required String id,
    required String path,
    required String filename,
  }) {
    return _remote.uploadProfileImage(id: id, path: path, filename: filename);
  }

  @override
  Future<Employee> deleteProfileImage(String id) {
    return _remote.deleteProfileImage(id);
  }
}

class DepartmentRepositoryImpl implements DepartmentRepository {
  DepartmentRepositoryImpl(this._remote);

  final EmployeeRemoteDataSource _remote;

  @override
  Future<List<Department>> getDepartments({String? status}) {
    return _remote.getDepartments(status: status);
  }
}

class PositionRepositoryImpl implements PositionRepository {
  PositionRepositoryImpl(this._remote);

  final EmployeeRemoteDataSource _remote;

  @override
  Future<List<Position>> getPositions({String? departmentId, String? status}) {
    return _remote.getPositions(departmentId: departmentId, status: status);
  }
}

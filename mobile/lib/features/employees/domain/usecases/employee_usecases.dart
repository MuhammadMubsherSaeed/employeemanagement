import 'dart:typed_data';

import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/domain/repositories/employee_repository.dart';

class GetEmployees {
  const GetEmployees(this._repository);

  final EmployeeRepository _repository;

  Future<EmployeePage<Employee>> call(EmployeeQuery query) {
    return _repository.getEmployees(query);
  }
}

class GetEmployee {
  const GetEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Employee> call(String id) {
    return _repository.getEmployeeById(id);
  }
}

class GetMyEmployee {
  const GetMyEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Employee> call() {
    return _repository.getMyEmployeeProfile();
  }
}

class CreateEmployee {
  const CreateEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Employee> call(EmployeeWrite body) {
    return _repository.createEmployee(body);
  }
}

class UpdateEmployee {
  const UpdateEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Employee> call(String id, EmployeeWrite body) {
    return _repository.updateEmployee(id, body);
  }
}

class DeleteEmployee {
  const DeleteEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteEmployee(id);
  }
}

class GetProfileImage {
  const GetProfileImage(this._repository);

  final EmployeeRepository _repository;

  Future<Uint8List?> call(String id) {
    return _repository.getProfileImage(id);
  }
}

class UploadProfileImage {
  const UploadProfileImage(this._repository);

  final EmployeeRepository _repository;

  Future<Employee> call({
    required String id,
    required String path,
    required String filename,
  }) {
    return _repository.uploadProfileImage(
      id: id,
      path: path,
      filename: filename,
    );
  }
}

class DeleteProfileImage {
  const DeleteProfileImage(this._repository);

  final EmployeeRepository _repository;

  Future<Employee> call(String id) {
    return _repository.deleteProfileImage(id);
  }
}

class GetDepartments {
  const GetDepartments(this._repository);

  final DepartmentRepository _repository;

  Future<List<Department>> call({String? status}) {
    return _repository.getDepartments(status: status);
  }
}

class GetPositions {
  const GetPositions(this._repository);

  final PositionRepository _repository;

  Future<List<Position>> call({String? departmentId, String? status}) {
    return _repository.getPositions(
      departmentId: departmentId,
      status: status,
    );
  }
}

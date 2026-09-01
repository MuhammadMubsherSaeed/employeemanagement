import 'dart:typed_data';

import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/employees/data/datasources/employee_remote_datasource.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/domain/repositories/employee_repository.dart';

const User companyAdminUser = User(
  id: 10,
  email: 'admin@example.com',
  firstName: 'Ada',
  lastName: 'Admin',
  fullName: 'Ada Admin',
  role: UserRole.companyAdmin,
  roleValue: 'COMPANY_ADMIN',
  isActive: true,
);

const User managerUser = User(
  id: 11,
  email: 'manager@example.com',
  firstName: 'Moe',
  lastName: 'Manager',
  fullName: 'Moe Manager',
  role: UserRole.manager,
  roleValue: 'MANAGER',
  isActive: true,
);

const User superAdminUser = User(
  id: 12,
  email: 'super@example.com',
  firstName: 'Sue',
  lastName: 'Super',
  fullName: 'Sue Super',
  role: UserRole.superAdmin,
  roleValue: 'SUPER_ADMIN',
  isActive: true,
);

class SeededAuthController extends AuthController {
  SeededAuthController(this.user);

  final User user;

  @override
  AuthState build() => AuthState.authenticated(user);
}

Employee sampleEmployee({
  String id = '11111111-1111-1111-1111-111111111111',
  String code = 'EMP-001',
  String firstName = 'Ada',
  String lastName = 'Lovelace',
  EmployeeStatus status = EmployeeStatus.active,
  EmploymentType employmentType = EmploymentType.fullTime,
  String departmentName = 'Engineering',
  String positionTitle = 'Engineer',
  String phone = '',
  String address = '',
}) {
  return Employee(
    id: id,
    employeeCode: code,
    firstName: firstName,
    lastName: lastName,
    fullName: '$firstName $lastName',
    employmentType: employmentType,
    status: status,
    phone: phone,
    address: address,
    department: Department(
      id: 'dept-1',
      name: departmentName,
      status: OrgStatus.active,
    ),
    position: Position(
      id: 'pos-1',
      title: positionTitle,
      status: OrgStatus.active,
      departmentId: 'dept-1',
    ),
    joiningDate: DateTime(2024, 1, 15),
  );
}

Map<String, dynamic> sampleEmployeeJson({
  bool detail = false,
  String id = '11111111-1111-1111-1111-111111111111',
}) {
  final Map<String, dynamic> json = <String, dynamic>{
    'id': id,
    'employee_code': 'EMP-001',
    'first_name': 'Ada',
    'last_name': 'Lovelace',
    'full_name': 'Ada Lovelace',
    'profile_image': '',
    'department': <String, dynamic>{
      'id': 'dept-1',
      'name': 'Engineering',
      'status': 'ACTIVE',
    },
    'position': <String, dynamic>{
      'id': 'pos-1',
      'title': 'Engineer',
      'status': 'ACTIVE',
    },
    'manager': <String, dynamic>{
      'id': 'mgr-1',
      'employee_code': 'EMP-100',
      'first_name': 'Grace',
      'last_name': 'Hopper',
    },
    'user': <String, dynamic>{'id': 7, 'email': 'ada@example.com'},
    'joining_date': '2024-01-15',
    'employment_type': 'FULL_TIME',
    'status': 'ACTIVE',
    'created_at': '2024-01-15T08:00:00Z',
  };
  if (detail) {
    json.addAll(<String, dynamic>{
      'gender': 'FEMALE',
      'date_of_birth': '1990-12-10',
      'phone': '5550100',
      'address': '1 Analytical Engine Rd',
      'emergency_contact_name': 'Lord Byron',
      'emergency_contact_relationship': 'Parent',
      'emergency_contact_phone': '5550199',
      'updated_at': '2024-02-01T08:00:00Z',
    });
  }
  return json;
}

class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository({
    List<Employee>? employees,
  }) : employees = employees ?? <Employee>[sampleEmployee()];

  List<Employee> employees;
  final List<EmployeeQuery> listQueries = <EmployeeQuery>[];
  Duration delay = Duration.zero;
  Object? listError;
  Object? detailError;
  Object? meError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Employee? created;
  Employee? updated;
  String? deletedId;
  int listCalls = 0;

  EmployeePage<Employee> Function(EmployeeQuery query)? pageBuilder;

  @override
  Future<EmployeePage<Employee>> getEmployees(EmployeeQuery query) async {
    listCalls += 1;
    listQueries.add(query);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (listError != null) {
      throw listError!;
    }
    if (pageBuilder != null) {
      return pageBuilder!(query);
    }
    return EmployeePage<Employee>(
      results: employees,
      count: employees.length,
    );
  }

  @override
  Future<Employee> getEmployeeById(String id) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (detailError != null) {
      throw detailError!;
    }
    return employees.firstWhere(
      (Employee item) => item.id == id,
      orElse: () => employees.first,
    );
  }

  @override
  Future<Employee> getMyEmployeeProfile() async {
    if (meError != null) {
      throw meError!;
    }
    return employees.first;
  }

  @override
  Future<Employee> createEmployee(EmployeeWrite body) async {
    if (createError != null) {
      throw createError!;
    }
    created = sampleEmployee(
      id: 'created-1',
      code: body.employeeCode,
      firstName: body.firstName,
      lastName: body.lastName,
      status: body.status,
      employmentType: body.employmentType,
    );
    return created!;
  }

  @override
  Future<Employee> updateEmployee(String id, EmployeeWrite body) async {
    if (updateError != null) {
      throw updateError!;
    }
    updated = sampleEmployee(
      id: id,
      code: body.employeeCode,
      firstName: body.firstName,
      lastName: body.lastName,
      status: body.status,
      employmentType: body.employmentType,
    );
    return updated!;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    if (deleteError != null) {
      throw deleteError!;
    }
    deletedId = id;
  }

  @override
  Future<Uint8List?> getProfileImage(String id) async => null;

  @override
  Future<Employee> uploadProfileImage({
    required String id,
    required String path,
    required String filename,
  }) async {
    return sampleEmployee(id: id);
  }

  @override
  Future<Employee> deleteProfileImage(String id) async {
    return sampleEmployee(id: id);
  }
}

class FakeEmployeeRemote implements EmployeeRemoteDataSource {
  FakeEmployeeRemote({
    EmployeePage<Employee>? page,
    this.employee,
    List<Department>? departments,
    List<Position>? positions,
  })  : page = page ??
            EmployeePage<Employee>(
              results: <Employee>[sampleEmployee()],
              count: 1,
            ),
        departments = departments ??
            <Department>[
              const Department(
                id: 'dept-1',
                name: 'Engineering',
                status: OrgStatus.active,
              ),
            ],
        positions = positions ??
            <Position>[
              const Position(
                id: 'pos-1',
                title: 'Engineer',
                status: OrgStatus.active,
                departmentId: 'dept-1',
              ),
            ];

  EmployeePage<Employee> page;
  Employee? employee;
  List<Department> departments;
  List<Position> positions;
  EmployeeQuery? lastQuery;
  EmployeeWrite? lastWrite;
  String? lastId;
  int listCalls = 0;

  @override
  Future<EmployeePage<Employee>> getEmployees(EmployeeQuery query) async {
    listCalls += 1;
    lastQuery = query;
    return page;
  }

  @override
  Future<Employee> getEmployeeById(String id) async {
    lastId = id;
    return employee ?? sampleEmployee(id: id);
  }

  @override
  Future<Employee> getMyEmployeeProfile() async {
    return employee ?? sampleEmployee();
  }

  @override
  Future<Employee> createEmployee(EmployeeWrite body) async {
    lastWrite = body;
    return employee ?? sampleEmployee();
  }

  @override
  Future<Employee> updateEmployee(String id, EmployeeWrite body) async {
    lastId = id;
    lastWrite = body;
    return employee ?? sampleEmployee(id: id);
  }

  @override
  Future<void> deleteEmployee(String id) async {
    lastId = id;
  }

  @override
  Future<Uint8List?> getProfileImage(String id) async => null;

  @override
  Future<Employee> uploadProfileImage({
    required String id,
    required String path,
    required String filename,
  }) async {
    lastId = id;
    return employee ?? sampleEmployee(id: id);
  }

  @override
  Future<Employee> deleteProfileImage(String id) async {
    lastId = id;
    return employee ?? sampleEmployee(id: id);
  }

  @override
  Future<List<Department>> getDepartments({String? status}) async {
    return departments;
  }

  @override
  Future<List<Position>> getPositions({
    String? departmentId,
    String? status,
  }) async {
    return positions;
  }
}

class FakeDepartmentRepository implements DepartmentRepository {
  FakeDepartmentRepository([List<Department>? items])
      : items = items ??
            <Department>[
              const Department(
                id: 'dept-1',
                name: 'Engineering',
                status: OrgStatus.active,
              ),
            ];

  List<Department> items;

  @override
  Future<List<Department>> getDepartments({String? status}) async => items;
}

class FakePositionRepository implements PositionRepository {
  FakePositionRepository([List<Position>? items])
      : items = items ??
            <Position>[
              const Position(
                id: 'pos-1',
                title: 'Engineer',
                status: OrgStatus.active,
                departmentId: 'dept-1',
              ),
            ];

  List<Position> items;

  @override
  Future<List<Position>> getPositions({
    String? departmentId,
    String? status,
  }) async =>
      items;
}

import 'dart:typed_data';

import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/network/api_client_provider.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/employees/data/datasources/employee_remote_datasource.dart';
import 'package:flutter_base/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/domain/repositories/employee_repository.dart';
import 'package:flutter_base/features/employees/domain/usecases/employee_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final employeeRemoteDataSourceProvider =
    Provider<EmployeeRemoteDataSource>((Ref ref) {
  return EmployeeRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((Ref ref) {
  return EmployeeRepositoryImpl(ref.watch(employeeRemoteDataSourceProvider));
});

final departmentRepositoryProvider = Provider<DepartmentRepository>((Ref ref) {
  return DepartmentRepositoryImpl(ref.watch(employeeRemoteDataSourceProvider));
});

final positionRepositoryProvider = Provider<PositionRepository>((Ref ref) {
  return PositionRepositoryImpl(ref.watch(employeeRemoteDataSourceProvider));
});

final getEmployeesProvider = Provider<GetEmployees>((Ref ref) {
  return GetEmployees(ref.watch(employeeRepositoryProvider));
});

final getEmployeeProvider = Provider<GetEmployee>((Ref ref) {
  return GetEmployee(ref.watch(employeeRepositoryProvider));
});

final getMyEmployeeProvider = Provider<GetMyEmployee>((Ref ref) {
  return GetMyEmployee(ref.watch(employeeRepositoryProvider));
});

final createEmployeeProvider = Provider<CreateEmployee>((Ref ref) {
  return CreateEmployee(ref.watch(employeeRepositoryProvider));
});

final updateEmployeeProvider = Provider<UpdateEmployee>((Ref ref) {
  return UpdateEmployee(ref.watch(employeeRepositoryProvider));
});

final deleteEmployeeProvider = Provider<DeleteEmployee>((Ref ref) {
  return DeleteEmployee(ref.watch(employeeRepositoryProvider));
});

final getProfileImageUseCaseProvider = Provider<GetProfileImage>((Ref ref) {
  return GetProfileImage(ref.watch(employeeRepositoryProvider));
});

final uploadProfileImageUseCaseProvider =
    Provider<UploadProfileImage>((Ref ref) {
  return UploadProfileImage(ref.watch(employeeRepositoryProvider));
});

final deleteProfileImageUseCaseProvider =
    Provider<DeleteProfileImage>((Ref ref) {
  return DeleteProfileImage(ref.watch(employeeRepositoryProvider));
});

final getDepartmentsProvider = Provider<GetDepartments>((Ref ref) {
  return GetDepartments(ref.watch(departmentRepositoryProvider));
});

final getPositionsProvider = Provider<GetPositions>((Ref ref) {
  return GetPositions(ref.watch(positionRepositoryProvider));
});

final departmentsProvider = FutureProvider<List<Department>>((Ref ref) {
  return ref.watch(getDepartmentsProvider)();
});

final positionsProvider = FutureProvider<List<Position>>((Ref ref) {
  return ref.watch(getPositionsProvider)();
});

final employeeDirectoryProvider = FutureProvider<List<Employee>>((Ref ref) {
  return ref
      .watch(getEmployeesProvider)(
        const EmployeeQuery(pageSize: AppConstants.maxPageSize),
      )
      .then((EmployeePage<Employee> page) => page.results);
});

final employeeDetailProvider =
    FutureProvider.autoDispose.family<Employee, String>((Ref ref, String id) {
  ref.watch(authControllerProvider);
  if (id == 'me') {
    return ref.watch(getMyEmployeeProvider)();
  }
  return ref.watch(getEmployeeProvider)(id);
});

final employeeProfileImageProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>((Ref ref, String id) {
  ref.watch(authControllerProvider);
  return ref.watch(getProfileImageUseCaseProvider)(id);
});

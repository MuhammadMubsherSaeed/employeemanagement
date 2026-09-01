import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetAdminDashboard {
  const GetAdminDashboard(this._repository);

  final DashboardRepository _repository;

  Future<AdminDashboard> call() => _repository.getAdminDashboard();
}

class GetManagerDashboard {
  const GetManagerDashboard(this._repository);

  final DashboardRepository _repository;

  Future<ManagerDashboard> call() => _repository.getManagerDashboard();
}

class GetEmployeeDashboard {
  const GetEmployeeDashboard(this._repository);

  final DashboardRepository _repository;

  Future<EmployeeDashboard> call() => _repository.getEmployeeDashboard();
}

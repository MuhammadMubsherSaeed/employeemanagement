import 'package:flutter_base/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_base/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<AdminDashboard> getAdminDashboard() {
    return _remote.getAdminDashboard();
  }

  @override
  Future<ManagerDashboard> getManagerDashboard() {
    return _remote.getManagerDashboard();
  }

  @override
  Future<EmployeeDashboard> getEmployeeDashboard() {
    return _remote.getEmployeeDashboard();
  }
}

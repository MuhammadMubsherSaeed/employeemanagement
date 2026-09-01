import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';

abstract class DashboardRepository {
  Future<AdminDashboard> getAdminDashboard();

  Future<ManagerDashboard> getManagerDashboard();

  Future<EmployeeDashboard> getEmployeeDashboard();
}

import 'package:flutter_base/features/dashboard/presentation/providers/admin_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/employee_dashboard_controller.dart';
import 'package:flutter_base/features/dashboard/presentation/providers/manager_dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void invalidateDashboardProviders(Ref ref) {
  if (ref.exists(adminDashboardControllerProvider)) {
    ref.invalidate(adminDashboardControllerProvider);
  }
  if (ref.exists(managerDashboardControllerProvider)) {
    ref.invalidate(managerDashboardControllerProvider);
  }
  if (ref.exists(employeeDashboardControllerProvider)) {
    ref.invalidate(employeeDashboardControllerProvider);
  }
}

void invalidateEmployeeDashboard(Ref ref) {
  if (ref.exists(employeeDashboardControllerProvider)) {
    ref.invalidate(employeeDashboardControllerProvider);
  }
}

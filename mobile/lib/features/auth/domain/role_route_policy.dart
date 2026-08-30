import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';

/// Role → route access. Backend authorization remains mandatory.
class RoleRoutePolicy {
  const RoleRoutePolicy();

  bool canAccess({
    required UserRole role,
    required String path,
  }) {
    final EmployeeAccess access = EmployeeAccess(role);
    if (path == AppRoutes.employeesAdd) {
      return access.canCreate;
    }
    if (path.endsWith('/edit')) {
      return access.canUpdate;
    }
    if (path == AppRoutes.employees ||
        path == AppRoutes.employeesMe ||
        path.startsWith('${AppRoutes.employees}/')) {
      return true;
    }
    return true;
  }
}

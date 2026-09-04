import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/features/auth/domain/role_route_policy.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';

class AuthRedirect {
  AuthRedirect._();

  static const RoleRoutePolicy _policy = RoleRoutePolicy();

  static String? resolve({
    required AuthState auth,
    required String location,
    RoleRoutePolicy policy = _policy,
  }) {
    final String loc = location.isEmpty ? AppRoutes.root : location;
    final bool onSplash = loc == AppRoutes.splash || loc == AppRoutes.root;
    final bool onLogin = loc == AppRoutes.login;
    final bool onForgot = loc == AppRoutes.forgotPassword;
    final bool onReset = loc == AppRoutes.resetPassword;
    final bool onPublicAuth = onLogin || onForgot || onReset;
    final bool onAccessDenied = loc == AppRoutes.accessDenied;

    if (auth.isResolving) {
      return _nav(AppRoutes.splash, loc, unless: onSplash);
    }

    if (auth is AuthAuthenticated) {
      final Authorization authorization = Authorization.fromUser(auth.user);
      if (onAccessDenied) {
        return null;
      }
      if (!_policyAllows(policy, authorization, loc)) {
        if (EmployeeAccess(authorization).isSelfService &&
            loc.startsWith(AppRoutes.employees)) {
          return _nav(AppRoutes.employeesMe, loc);
        }
        return _nav(AppRoutes.accessDenied, loc);
      }
      if (EmployeeAccess(authorization).isSelfService) {
        if (loc == AppRoutes.employees ||
            loc == AppRoutes.employeesAdd ||
            (loc.startsWith('${AppRoutes.employees}/') &&
                loc != AppRoutes.employeesMe &&
                !loc.contains('/documents') &&
                !loc.endsWith('/edit'))) {
          return _nav(AppRoutes.employeesMe, loc);
        }
      }
      if (DeviceAccess(authorization).isSelfService) {
        if (loc == AppRoutes.devices || loc == AppRoutes.devicesAdd) {
          return _nav(AppRoutes.myDevices, loc);
        }
      }
      if (onLogin || onForgot || onSplash) {
        return _nav(AppRoutes.dashboard, loc);
      }
      return null;
    }

    if (onPublicAuth) {
      return null;
    }
    return _nav(AppRoutes.login, loc);
  }

  static bool _policyAllows(
    RoleRoutePolicy policy,
    Authorization auth,
    String path,
  ) {
    return policy.canAccess(auth: auth, path: path);
  }

  static String? _nav(String target, String loc, {bool unless = false}) {
    if (unless || target == loc) {
      return null;
    }
    return target;
  }
}

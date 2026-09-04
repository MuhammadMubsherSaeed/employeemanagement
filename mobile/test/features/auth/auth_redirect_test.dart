import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/router/auth_redirect.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';

void main() {
  test('initial and loading stay on splash', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.initial(),
        location: AppRoutes.login,
      ),
      AppRoutes.splash,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.loading(),
        location: AppRoutes.splash,
      ),
      isNull,
    );
  });

  test('unauthenticated users are sent to login and cannot open home', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.home,
      ),
      AppRoutes.login,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.dashboard,
      ),
      AppRoutes.login,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.login,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.forgotPassword,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.resetPassword,
      ),
      isNull,
    );
  });

  test('authenticated users go to the dashboard and cannot open login', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.login,
      ),
      AppRoutes.dashboard,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.forgotPassword,
      ),
      AppRoutes.dashboard,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.home,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.splash,
      ),
      AppRoutes.dashboard,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.dashboard,
      ),
      isNull,
    );
  });

  test('EMPLOYEE is sent to their own profile instead of the directory', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.employees,
      ),
      AppRoutes.employeesMe,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.employeesAdd,
      ),
      AppRoutes.employeesMe,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.employee('other-id'),
      ),
      AppRoutes.employeesMe,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.employeeEdit('other-id'),
      ),
      AppRoutes.employeesMe,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.employeesMe,
      ),
      isNull,
    );
  });

  test('authenticated employees can open leave routes they are allowed to use', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.leaves,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.leavesApply,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.leavesTypes,
      ),
      AppRoutes.accessDenied,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.leaves,
      ),
      AppRoutes.login,
    );
  });

  test('authenticated employees use my-devices instead of company inventory', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.devices,
      ),
      AppRoutes.myDevices,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.myDevices,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.device('dev-1'),
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.devicesAdd,
      ),
      AppRoutes.accessDenied,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.deviceAssign('dev-1'),
      ),
      AppRoutes.accessDenied,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.devices,
      ),
      AppRoutes.login,
    );
  });

  test('authenticated employees can open their attendance routes', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.attendance,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.attendanceHistory,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.attendance,
      ),
      AppRoutes.login,
    );
  });

  test('employees cannot open company reports', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.reports,
      ),
      AppRoutes.accessDenied,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.reportsAttendance,
      ),
      AppRoutes.accessDenied,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.reportsEmployees,
      ),
      AppRoutes.accessDenied,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.reports,
      ),
      AppRoutes.login,
    );
  });

  test('company members can open settings; unknown roles cannot', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.settings,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.settingsAttendance,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.settings,
      ),
      AppRoutes.login,
    );
  });

  test('redirect never returns the current location', () {
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.unauthenticated(),
        location: AppRoutes.login,
      ),
      isNull,
    );
    expect(
      AuthRedirect.resolve(
        auth: const AuthState.authenticated(sampleUser),
        location: AppRoutes.accessDenied,
      ),
      isNull,
    );
  });
}

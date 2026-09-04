import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';
import '../../helpers/rbac_fixtures.dart';

void main() {
  test('hasPermission fails closed for anonymous and empty codes', () {
    const Authorization anon = Authorization.anonymous();
    expect(anon.hasPermission(Permissions.employeesView), isFalse);
    expect(anon.hasAnyPermission(<String>[Permissions.employeesView]), isFalse);
    expect(anon.hasAllPermissions(<String>[Permissions.employeesView]), isFalse);
    expect(anon.hasRole(UserRole.employee), isFalse);

    final Authorization empty = Authorization.fromUser(
      sampleUserFrom(
        role: UserRole.unknown,
        roleValue: 'HR',
        permissions: const <String>[],
      ),
    );
    expect(empty.hasPermission(Permissions.employeesView), isFalse);
    expect(empty.hasPermission(''), isFalse);
    expect(empty.hasPermission('not.a.real.code'), isFalse);
    expect(empty.hasRoleValue('HR'), isTrue);
  });

  test('hasAny and hasAll match explicit permission lists', () {
    final Authorization auth = Authorization.fromUser(managerUser);
    expect(auth.hasPermission(Permissions.employeesView), isTrue);
    expect(auth.hasPermission(Permissions.employeesDelete), isFalse);
    expect(
      auth.hasAnyPermission(<String>[
        Permissions.employeesDelete,
        Permissions.leaveApprove,
      ]),
      isTrue,
    );
    expect(
      auth.hasAllPermissions(<String>[
        Permissions.leaveApprove,
        Permissions.leaveReject,
      ]),
      isTrue,
    );
    expect(
      auth.hasAllPermissions(<String>[
        Permissions.leaveApprove,
        Permissions.settingsManage,
      ]),
      isFalse,
    );
    expect(auth.hasRole(UserRole.manager), isTrue);
    expect(
      auth.hasAnyRole(<UserRole>[UserRole.employee, UserRole.manager]),
      isTrue,
    );
  });

  test('SUPER_ADMIN with empty codes mirrors backend bypass', () {
    final Authorization auth = Authorization.fromUser(superAdminUser);
    expect(auth.hasPermission(Permissions.settingsManage), isTrue);
    expect(auth.hasPermission(Permissions.employeesDelete), isTrue);
    expect(auth.hasTenant, isFalse);
  });

  test('custom roles work from permissions without a Flutter rewrite', () {
    final Authorization reportsOnly = Authorization.fromUser(
      sampleUserFrom(
        role: UserRole.unknown,
        roleValue: 'ACCOUNTANT',
        permissions: const <String>[Permissions.reportsView],
      ),
    );
    expect(reportsOnly.hasPermission(Permissions.reportsView), isTrue);
    expect(reportsOnly.hasPermission(Permissions.employeesView), isFalse);
    expect(reportsOnly.hasRole(UserRole.companyAdmin), isFalse);
  });
}

User sampleUserFrom({
  required UserRole role,
  required String roleValue,
  required List<String> permissions,
}) {
  return User(
    id: 99,
    email: 'custom@example.com',
    firstName: 'Custom',
    lastName: 'Role',
    fullName: 'Custom Role',
    role: role,
    roleValue: roleValue,
    companyId: kSampleCompanyId,
    permissions: permissions,
  );
}

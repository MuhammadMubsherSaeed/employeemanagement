import 'package:flutter_base/core/session/user_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserSession parses backend-shaped JSON defensively', () {
    final UserSession session = UserSession.fromJson(const <String, dynamic>{
      'user_id': 'u-1',
      'company_id': 'c-1',
      'role': 'manager',
      'permissions': <dynamic>['employees.view', ''],
    });

    expect(session.userId, 'u-1');
    expect(session.companyId, 'c-1');
    expect(session.role, 'manager');
    expect(session.hasTenantContext, isTrue);
    expect(session.hasPermission('employees.view'), isTrue);
    expect(session.permissions, <String>['employees.view']);
  });

  test('incomplete JSON is not treated as a valid tenant session', () {
    final UserSession session = UserSession.fromJson(const <String, dynamic>{
      'role': 'employee',
    });
    expect(session.hasTenantContext, isFalse);
  });
}

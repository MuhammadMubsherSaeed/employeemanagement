import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from `settings.manage`. Signed-in company members may view.
class SettingsAccess {
  const SettingsAccess(this.auth);

  factory SettingsAccess.of(User? user) =>
      SettingsAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView => auth.isAuthenticated && auth.hasTenant;

  bool get canEdit =>
      auth.hasPermission(Permissions.settingsManage) && auth.hasTenant;
}

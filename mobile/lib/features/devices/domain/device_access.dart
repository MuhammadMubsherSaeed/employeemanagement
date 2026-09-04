import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from backend permission codes. Django remains the security boundary.
class DeviceAccess {
  const DeviceAccess(this.auth);

  factory DeviceAccess.of(User? user) =>
      DeviceAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView => auth.hasPermission(Permissions.devicesView);

  bool get canCreate =>
      auth.hasPermission(Permissions.devicesCreate) && auth.hasTenant;

  bool get canUpdate =>
      auth.hasPermission(Permissions.devicesUpdate) && auth.hasTenant;

  bool get canDelete =>
      auth.hasPermission(Permissions.devicesDelete) && auth.hasTenant;

  bool get canAssign =>
      auth.hasPermission(Permissions.devicesAssign) && auth.hasTenant;

  bool get canReturn =>
      auth.hasPermission(Permissions.devicesReturn) && auth.hasTenant;

  bool get canSeeSensitive => canUpdate || canDelete;

  bool get canFilterByEmployee => canAssign;

  bool get isSelfService =>
      canView && !canCreate && !canUpdate && !canAssign && !canDelete;

  bool get canManageInventory => canCreate;
}

import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// Foundation only: Role → (future) Permissions → route access.
///
/// No HRMS module restrictions are enforced yet. Unknown roles are allowed so
/// a backend-introduced role does not lock the user out of the shell.
class RoleRoutePolicy {
  const RoleRoutePolicy();

  bool canAccess({
    required UserRole role,
    required String path,
  }) {
    return true;
  }
}

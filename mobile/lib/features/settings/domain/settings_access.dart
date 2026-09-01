import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from [User.role] and the default RBAC catalog (`settings.manage`).
/// Django remains the security boundary.
class SettingsAccess {
  const SettingsAccess(this.role);

  final UserRole role;

  bool get canView =>
      role == UserRole.companyAdmin ||
      role == UserRole.manager ||
      role == UserRole.employee;

  bool get canEdit => role == UserRole.companyAdmin;
}

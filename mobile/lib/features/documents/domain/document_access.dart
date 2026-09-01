import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates. The Django API remains the security boundary.
class DocumentAccess {
  const DocumentAccess(this.role);

  final UserRole role;

  bool get canView =>
      role == UserRole.companyAdmin ||
      role == UserRole.manager ||
      role == UserRole.employee ||
      role == UserRole.superAdmin;

  bool get canUpload =>
      role == UserRole.companyAdmin ||
      role == UserRole.manager ||
      role == UserRole.employee ||
      role == UserRole.superAdmin;

  bool get canDelete =>
      role == UserRole.companyAdmin || role == UserRole.superAdmin;

  bool get canManageProfileImage =>
      role == UserRole.companyAdmin ||
      role == UserRole.manager ||
      role == UserRole.employee ||
      role == UserRole.superAdmin;
}

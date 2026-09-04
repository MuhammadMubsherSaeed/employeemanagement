import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// UI gates from backend document codes. Django remains the security boundary.
class DocumentAccess {
  const DocumentAccess(this.auth);

  factory DocumentAccess.of(User? user) =>
      DocumentAccess(Authorization.fromUser(user));

  final Authorization auth;

  UserRole get role => auth.role;

  bool get canView => auth.hasPermission(Permissions.documentsView);

  bool get canUpload =>
      auth.hasPermission(Permissions.documentsCreate) && auth.hasTenant;

  bool get canUpdate =>
      auth.hasPermission(Permissions.documentsUpdate) && auth.hasTenant;

  bool get canDelete =>
      auth.hasPermission(Permissions.documentsDelete) && auth.hasTenant;

  bool get canDownload => auth.hasPermission(Permissions.documentsDownload);

  bool get canManageProfileImage =>
      auth.hasPermission(Permissions.employeesUpdate) && auth.hasTenant;
}

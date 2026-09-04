import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/permissions.dart';

class AuditLogAccess {
  const AuditLogAccess(this.auth);

  final Authorization auth;

  bool get canView =>
      auth.hasPermission(Permissions.auditLogsView) && auth.hasTenant;
}

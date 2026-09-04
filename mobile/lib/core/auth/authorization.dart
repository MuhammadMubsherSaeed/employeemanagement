import 'package:flutter/foundation.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

/// Session authorization derived from `/auth/login/` and `/auth/me/`.
///
/// Fail closed: missing, empty, or unknown codes never grant access.
/// Django remains the security boundary; this class is UX-only.
@immutable
class Authorization {
  const Authorization({
    required this.isAuthenticated,
    required this.role,
    required this.roleValue,
    required this.permissions,
    this.userId,
    this.companyId,
  });

  const Authorization.anonymous()
      : isAuthenticated = false,
        role = UserRole.unknown,
        roleValue = 'UNKNOWN',
        permissions = const <String>[],
        userId = null,
        companyId = null;

  factory Authorization.fromUser(User? user) {
    if (user == null) {
      return const Authorization.anonymous();
    }
    return Authorization(
      isAuthenticated: true,
      role: user.role,
      roleValue: user.roleValue,
      permissions: user.permissions,
      userId: user.id,
      companyId: user.companyId,
    );
  }

  final bool isAuthenticated;
  final UserRole role;
  final String roleValue;
  final List<String> permissions;
  final int? userId;
  final String? companyId;

  bool get hasTenant {
    final String? id = companyId;
    return id != null && id.trim().isNotEmpty;
  }

  /// Platform admins are seeded with an empty M2M. Django still grants every
  /// code via `TenantContext.has_permission`. Mirror that only when the API
  /// did not already send an explicit list.
  bool get _platformBypass {
    return isAuthenticated &&
        role == UserRole.superAdmin &&
        permissions.isEmpty;
  }

  bool hasPermission(String permission) {
    if (!isAuthenticated) {
      return false;
    }
    final String code = permission.trim();
    if (code.isEmpty) {
      return false;
    }
    if (permissions.contains(code)) {
      return true;
    }
    return _platformBypass;
  }

  bool hasAnyPermission(Iterable<String> codes) {
    for (final String code in codes) {
      if (hasPermission(code)) {
        return true;
      }
    }
    return false;
  }

  bool hasAllPermissions(Iterable<String> codes) {
    final List<String> required = codes.toList(growable: false);
    if (required.isEmpty) {
      return false;
    }
    for (final String code in required) {
      if (!hasPermission(code)) {
        return false;
      }
    }
    return true;
  }

  bool hasRole(UserRole expected) => isAuthenticated && role == expected;

  bool hasAnyRole(Iterable<UserRole> roles) {
    if (!isAuthenticated) {
      return false;
    }
    return roles.contains(role);
  }

  /// Future/custom roles compare against the raw API value, not the enum.
  bool hasRoleValue(String code) {
    if (!isAuthenticated) {
      return false;
    }
    return roleValue.trim().toUpperCase() == code.trim().toUpperCase();
  }
}

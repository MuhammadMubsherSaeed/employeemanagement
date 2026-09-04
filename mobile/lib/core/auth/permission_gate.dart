import 'package:flutter/material.dart';
import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hides or disables [child] when the session lacks the required permission.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.child,
    this.permission,
    this.anyOf,
    this.allOf,
    this.fallback = const SizedBox.shrink(),
    this.disable = false,
  });

  final Widget child;
  final String? permission;
  final List<String>? anyOf;
  final List<String>? allOf;
  final Widget fallback;
  final bool disable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Authorization auth = ref.watch(authorizationProvider);
    final bool allowed = _allowed(auth);
    if (allowed) {
      return child;
    }
    if (disable) {
      return IgnorePointer(
        child: Opacity(opacity: 0.45, child: child),
      );
    }
    return fallback;
  }

  bool _allowed(Authorization auth) {
    if (permission != null && permission!.trim().isNotEmpty) {
      return auth.hasPermission(permission!);
    }
    final List<String>? any = anyOf;
    if (any != null) {
      return auth.hasAnyPermission(any);
    }
    final List<String>? all = allOf;
    if (all != null) {
      return auth.hasAllPermissions(all);
    }
    return false;
  }
}

/// Role-specific UX only. Prefer [PermissionGate] for actions.
class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.child,
    this.role,
    this.anyOf,
    this.fallback = const SizedBox.shrink(),
  });

  final Widget child;
  final UserRole? role;
  final List<UserRole>? anyOf;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Authorization auth = ref.watch(authorizationProvider);
    final bool allowed;
    if (role != null) {
      allowed = auth.hasRole(role!);
    } else if (anyOf != null) {
      allowed = auth.hasAnyRole(anyOf!);
    } else {
      allowed = false;
    }
    if (allowed) {
      return child;
    }
    return fallback;
  }
}

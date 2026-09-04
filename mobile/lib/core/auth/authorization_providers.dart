import 'package:flutter_base/core/auth/authorization.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of authorization state. Derived from [authControllerProvider].
final authorizationProvider = Provider<Authorization>((Ref ref) {
  final AuthState auth = ref.watch(authControllerProvider);
  if (auth is AuthAuthenticated) {
    return Authorization.fromUser(auth.user);
  }
  return const Authorization.anonymous();
});

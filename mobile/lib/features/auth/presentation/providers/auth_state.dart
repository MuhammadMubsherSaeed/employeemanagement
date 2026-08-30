import 'package:equatable/equatable.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;

  const factory AuthState.loading() = AuthLoading;

  const factory AuthState.authenticated(User user) = AuthAuthenticated;

  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  const factory AuthState.error(String message) = AuthError;

  bool get isAuthenticated => this is AuthAuthenticated;

  bool get isResolving => this is AuthInitial || this is AuthLoading;
}

class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => const <Object?>[];
}

class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => const <Object?>[];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();

  @override
  List<Object?> get props => const <Object?>[];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

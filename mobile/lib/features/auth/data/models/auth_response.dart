import 'package:flutter_base/features/auth/data/models/token_model.dart';
import 'package:flutter_base/features/auth/data/models/user_model.dart';

class AuthResponse {
  const AuthResponse({
    required this.tokens,
    required this.user,
  });

  final TokenModel tokens;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final Object? userRaw = json['user'];
    return AuthResponse(
      tokens: TokenModel.fromJson(json),
      user: UserModel.fromJson(
        userRaw is Map
            ? Map<String, dynamic>.from(userRaw)
            : const <String, dynamic>{},
      ),
    );
  }
}

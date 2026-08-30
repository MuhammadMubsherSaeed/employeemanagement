import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/auth_endpoints.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/auth/data/models/auth_response.dart';
import 'package:flutter_base/features/auth/data/models/login_request.dart';
import 'package:flutter_base/features/auth/data/models/token_model.dart';
import 'package:flutter_base/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(LoginRequest request);

  Future<TokenModel> refresh(String refreshToken);

  Future<void> logout(String refreshToken);

  Future<UserModel> getCurrentUser();

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
    required String confirmPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    final envelope = await _post(AuthEndpoints.login, request.toJson());
    return AuthResponse.fromJson(_data(envelope));
  }

  @override
  Future<TokenModel> refresh(String refreshToken) async {
    final envelope = await _post(
      AuthEndpoints.refresh,
      <String, dynamic>{'refresh': refreshToken},
    );
    return TokenModel.fromJson(_data(envelope));
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _post(
      AuthEndpoints.logout,
      <String, dynamic>{'refresh': refreshToken},
    );
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get<dynamic>(AuthEndpoints.me);
    return UserModel.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _post(
      AuthEndpoints.forgotPassword,
      <String, dynamic>{'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _post(
      AuthEndpoints.resetPassword,
      <String, dynamic>{
        'uid': uid,
        'token': token,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<ApiEnvelope> _post(String path, Object data) async {
    final response = await _client.post<dynamic>(path, data: data);
    return _envelope(response.data);
  }

  Map<String, dynamic> _data(ApiEnvelope envelope) {
    try {
      return envelope.requireDataMap();
    } on FormatException {
      throw const UnknownException();
    }
  }

  ApiEnvelope _envelope(dynamic data) {
    try {
      final ApiEnvelope envelope = ApiEnvelope.parse(data);
      if (!envelope.success && envelope.data == null) {
        throw UnknownException(envelope.message ?? 'Request failed.');
      }
      return envelope;
    } on FormatException {
      throw const UnknownException();
    }
  }
}

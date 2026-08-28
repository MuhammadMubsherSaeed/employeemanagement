import 'dart:convert';

import 'Data.dart';

LoginResponse loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));
String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  LoginResponse({
    this.success,
    this.message,
    this.data,
    this.statusCode,
    this.code,
  });

  LoginResponse.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    statusCode = json['status_code'];
    code = json['code'];
  }
  bool? success;
  String? message;
  Data? data;
  int? statusCode;
  int? code;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    map['status_code'] = statusCode;
    map['code'] = code;
    return map;
  }
}

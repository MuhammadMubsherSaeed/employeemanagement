import 'dart:convert';

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());

class Data {
  Data({
    this.accessToken,
    this.tokenType,
    this.otpCode,
    this.userId,
    this.username,
    this.name,
    this.appVersion,
    this.otpVerificationRequired,
  });

  Data.fromJson(dynamic json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'];
    otpCode = json['otp_code'];
    userId = json['user_id'];
    username = json['username'];
    name = json['name'];
    appVersion = json['app_version'];
    otpVerificationRequired = json['otp_verification_required'];
  }
  String? accessToken;
  String? tokenType;
  int? otpCode;
  int? userId;
  String? username;
  String? name;
  String? appVersion;
  int? otpVerificationRequired;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['access_token'] = accessToken;
    map['token_type'] = tokenType;
    map['otp_code'] = otpCode;
    map['user_id'] = userId;
    map['username'] = username;
    map['name'] = name;
    map['app_version'] = appVersion;
    map['otp_verification_required'] = otpVerificationRequired;
    return map;
  }
}

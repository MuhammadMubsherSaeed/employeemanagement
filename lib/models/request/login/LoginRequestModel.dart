import 'package:package_info_plus/package_info_plus.dart';

class LoginRequestModel {
  String userName;
  String? deviceToken;
  String? deviceId;

  LoginRequestModel({required this.userName, this.deviceToken, this.deviceId});

  Future<Map<String, dynamic>> toJson() async {
    Map<String, dynamic> map = {
      'username': userName.replaceAll("-", "").trim(),
      'device_token': deviceToken,
      'device_id': deviceId,
    };
    return map;
  }
}

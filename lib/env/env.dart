import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: ".env")
abstract class Env {
  @EnviedField(varName: "BASE_API_URL_DEV", obfuscate: true)
  static String base_api_url_dev = _Env.base_api_url_dev;

  @EnviedField(varName: "BASE_API_URL_LIVE", obfuscate: true)
  static String base_api_url_live = _Env.base_api_url_live;

  @EnviedField(varName: "BASE_URL_DEV", obfuscate: true)
  static String base_api_dev = _Env.base_api_dev;

  @EnviedField(varName: "BASE_URL_LIVE", obfuscate: true)
  static String base_url_live = _Env.base_url_live;

  @EnviedField(varName: "API_KEY", obfuscate: true)
  static String api_key = _Env.api_key;

  @EnviedField(varName: "API_KEY_LIVE", obfuscate: true)
  static String api_key_live = _Env.api_key_live;

  @EnviedField(varName: "APP_KEY", obfuscate: true)
  static String app_key = _Env.app_key;

  @EnviedField(varName: "APP_KEY_LIVE", obfuscate: true)
  static String app_key_live = _Env.app_key_live;
}

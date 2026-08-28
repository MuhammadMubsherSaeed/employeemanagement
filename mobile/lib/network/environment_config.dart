import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  static const IS_LIVE = true;
  static const BASE_API_URL_DEV = String.fromEnvironment('BASE_API_URL',
      defaultValue: "https://eventtracking.punjab.gov.pk/api/");
  // defaultValue: "https://pmlntracking.com/api/");
  static const BASE_API_URL_LIVE = String.fromEnvironment('BASE_API_URL',
      // defaultValue: "https://eventtracking.punjab.gov.pk/api/");
      defaultValue: "https://pmlntracking.com/api/");
  static const BASE_URL_DEV = String.fromEnvironment('BASE_URL',
      defaultValue: "https://devpafskyview.pitb.gov.pk");
  static const BASE_URL_LIVE = String.fromEnvironment('BASE_URL',
      defaultValue: "https://pmlntracking.com");
  static const API_KEY = String.fromEnvironment('HEADER_API_KEY',
      defaultValue: "AewHnVKkfV2PKscUzaSVhqZIErXCag5a");
  static const API_KEY_LIVE = String.fromEnvironment('X-API-KEY',
      defaultValue: "AewHnVKkfV2PKscUzaSVhqZIErXCag5a");
  static const APP_KEY = String.fromEnvironment('HEADER_APP_KEY',
      defaultValue: "5xbRlEpIiajswk6sQ9LO2sIGeAwXl1M2");
  static const APP_KEY_LIVE = String.fromEnvironment('HEADER_APP_KEY',
      defaultValue: "5xbRlEpIiajswk6sQ9LO2sIGeAwXl1M2");

  // Common Api's Endpoints
  static const LOGIN_URL = "login";
  static const SYNC = "sync";
  static const EVENTS = "events";
  static const ATTENDANCE = "attendance";
  static const VERIFY_OTP = "verifyotp";
  static const REGISTER = "signup";
  // ignore: constant_identifier_names
  static const String DEV_SERVER_URL =
      'https://dev.poltrain.punjabpolice.gov.pk/'; // dev server
  // ignore: constant_identifier_names
  static const String STAGE_SERVER_URL = ''; // stage server
  // ignore: constant_identifier_names
  static const String PROD_SERVER_URL = ''; // prod server
  static String userToken = '';
  static getBaseUrl() {
    if (kDebugMode) {
      return DEV_SERVER_URL;
    } else {
      return PROD_SERVER_URL;
    }
  }

  static setUserToken(String value) {
    userToken = value;
  }
}

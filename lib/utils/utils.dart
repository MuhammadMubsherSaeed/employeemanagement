import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_base/models/response/login_response/Data.dart';
import 'package:flutter_base/utils/strings.dart';
import 'package:flutter_base/widgets/dialog_widget/dialog_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'colors.dart';

class Utils {
  static Future<void> setIsDownload(bool isDownload) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("download_count", isDownload);
  }

  static Future<bool> getIsDownload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDownload = prefs.getBool("download_count");
    return isDownload ?? false;
  }

  static Future<void> removeIsDownload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("download_count");
  }

  static void setAccessToken(String accesToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("token", accesToken);
  }

  static Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    return token;
  }

  static Future<void> removeAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("token");
  }

  static void setIsLoggedIn(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("is_logged_in", isLoggedIn);
  }

  static Future<bool> getIsLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool("is_logged_in");
    return isLoggedIn ?? false;
  }

  static Future<void> removeIsLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("is_logged_in");
  }

  static void setUserData(Data userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("user_data", jsonEncode(userData.toJson()));
  }

  static Future<Data?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("user_data");
    if (data != null) {
      Data userData = Data.fromJson(jsonDecode(data));
      return userData;
    } else {
      return null;
    }
  }

  static Future<void> removeUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("user_data");
  }

  static Future<bool> isAllPermissionsGranted() async {
    // TrackingStatus trackingStatus =
    //     await AppTrackingTransparency.requestTrackingAuthorization();
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
    ].request();
    // print(trackingStatus);
    if (statuses[Permission.notification]!.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> requestForPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();
  }

  static String? validateFields(String? value, {required String errorText}) {
    if (value != null) {
      if (value.isEmpty) {
        return errorText;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  static DateTime getFormattedDate(String date) {
    DateFormat inputFormat2 = DateFormat('yyyy-MM-dd hh:mm a');
    return inputFormat2.parse(date);
  }

  static String checkNullString(bool prefix) {
    var value = '';
    if (prefix) {
      value = ',N/A';
    } else {
      value = 'N/A';
    }

    return value;
  }

  static InputDecoration dropdownInputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: textFieldBorderColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: textFieldBorderColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: textFieldBorderColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: redColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      // suffixIcon: Icon(Icons.keyboard_arrow_down_outlined),
      isCollapsed: true,
      contentPadding: EdgeInsets.symmetric(
        vertical: 20.h,
        horizontal: 18.w,
      ),
      hintText: dropdownHintText,
    );
  }

  static Future<void> launchWebUrl(String url) async {
    if (Platform.isAndroid) {
      if (await canLaunchUrl(Uri.parse(url))) {
        launchUrl(Uri.parse(url));
      } else {
        Fluttertoast.showToast(msg: 'Unable to update');
      }
    }
  }

  static showUpdateDialog(
      {required String message, required BuildContext context}) {
    DialogBuilder.showLogoutDialog(
        title: "Alert",
        content: message,
        context: context,
        isCancelable: false,
        callback: () async {
          Navigator.pop(context);
          // await Utils.launchWebUrl(EnvironmentConfig.BASE_URL_LIVE);
        },
        buttonText: 'Ok');
  }
}

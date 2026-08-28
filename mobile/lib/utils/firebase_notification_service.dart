import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseNotificationService {
  static late FirebaseMessaging firebaseMessaging;

  static void firebaseNotificationInit() {
    firebaseMessaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen((event) {});

    FirebaseMessaging.onMessageOpenedApp.listen((event) {});
  }

  static Future<String> getDeviceToken() async {
    String? token = await firebaseMessaging.getToken();
    return token!;
  }

  void isTokenRefresh() async {
    firebaseMessaging.onTokenRefresh.listen((event) {
      event.toString();
      if (kDebugMode) {
        print('refresh');
      }
    });
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_base/features/notifications/domain/services/fcm_gateway.dart';
import 'package:flutter_base/features/notifications/domain/services/push_payload.dart';

PushMessage? pushMessageFromRemote(RemoteMessage message) {
  return PushMessage(
    payload: PushPayload.fromData(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
      messageId: message.messageId,
    ),
    title: message.notification?.title,
    body: message.notification?.body,
    messageId: message.messageId,
  );
}

class FirebaseFcmGateway implements FcmGateway {
  FirebaseFcmGateway({FirebaseMessaging? messaging}) : _messaging = messaging;

  FirebaseMessaging? _messaging;

  FirebaseMessaging? get _instance {
    if (_messaging != null) {
      return _messaging;
    }
    if (!isAvailable) {
      return null;
    }
    _messaging = FirebaseMessaging.instance;
    return _messaging;
  }

  @override
  bool get isAvailable => Firebase.apps.isNotEmpty;

  @override
  Future<void> requestPermission() async {
    final FirebaseMessaging? messaging = _instance;
    if (messaging == null) {
      return;
    }
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<String?> getToken() async {
    final FirebaseMessaging? messaging = _instance;
    if (messaging == null) {
      return null;
    }
    return messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh {
    final FirebaseMessaging? messaging = _instance;
    if (messaging == null) {
      return const Stream<String>.empty();
    }
    return messaging.onTokenRefresh;
  }

  @override
  Stream<PushMessage> get onForegroundMessage {
    if (!isAvailable) {
      return const Stream<PushMessage>.empty();
    }
    return FirebaseMessaging.onMessage
        .map(pushMessageFromRemote)
        .where((PushMessage? item) => item != null)
        .cast<PushMessage>();
  }

  @override
  Stream<PushMessage> get onMessageOpenedApp {
    if (!isAvailable) {
      return const Stream<PushMessage>.empty();
    }
    return FirebaseMessaging.onMessageOpenedApp
        .map(pushMessageFromRemote)
        .where((PushMessage? item) => item != null)
        .cast<PushMessage>();
  }

  @override
  Future<PushMessage?> getInitialMessage() async {
    final FirebaseMessaging? messaging = _instance;
    if (messaging == null) {
      return null;
    }
    final RemoteMessage? message = await messaging.getInitialMessage();
    if (message == null) {
      return null;
    }
    return pushMessageFromRemote(message);
  }
}

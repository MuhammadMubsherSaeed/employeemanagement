import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_base/core/utils/app_logger.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/services/fcm_gateway.dart';

/// Application-level FCM lifecycle. Listeners are registered once.
class FirebaseNotificationService {
  FirebaseNotificationService(this._gateway);

  final FcmGateway _gateway;
  bool _initialized = false;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  final StreamController<PushMessage> _foreground =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> _opened =
      StreamController<PushMessage>.broadcast();
  final StreamController<String> _tokenRefresh =
      StreamController<String>.broadcast();

  bool get isInitialized => _initialized;

  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  Stream<PushMessage> get onOpenedMessage => _opened.stream;

  Stream<String> get onTokenRefresh => _tokenRefresh.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (!_gateway.isAvailable) {
      AppLogger.info('FCM skipped; Firebase is not initialized.');
      return;
    }
    _initialized = true;
    try {
      await _gateway.requestPermission();
    } catch (error, stack) {
      AppLogger.error('FCM permission request failed', error, stack);
    }
    _subscriptions.add(
      _gateway.onForegroundMessage.listen(_foreground.add),
    );
    _subscriptions.add(
      _gateway.onMessageOpenedApp.listen(_opened.add),
    );
    _subscriptions.add(
      _gateway.onTokenRefresh.listen(_tokenRefresh.add),
    );
  }

  Future<String?> getToken() async {
    if (!_gateway.isAvailable) {
      return null;
    }
    try {
      return await _gateway.getToken();
    } catch (error, stack) {
      AppLogger.error('FCM token lookup failed', error, stack);
      return null;
    }
  }

  Future<PushMessage?> getInitialMessage() async {
    if (!_gateway.isAvailable) {
      return null;
    }
    try {
      return await _gateway.getInitialMessage();
    } catch (error, stack) {
      AppLogger.error('FCM initial message lookup failed', error, stack);
      return null;
    }
  }

  DeviceTokenPlatform currentPlatform() {
    if (kIsWeb) {
      return DeviceTokenPlatform.web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return DeviceTokenPlatform.android;
      case TargetPlatform.iOS:
        return DeviceTokenPlatform.ios;
      default:
        return DeviceTokenPlatform.unknown;
    }
  }

  String deviceName() => currentPlatform().label;

  Future<void> dispose() async {
    for (final StreamSubscription<dynamic> sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _foreground.close();
    await _opened.close();
    await _tokenRefresh.close();
    _initialized = false;
  }
}

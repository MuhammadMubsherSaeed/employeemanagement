import 'package:flutter_base/features/notifications/domain/services/push_payload.dart';

class PushMessage {
  const PushMessage({
    required this.payload,
    this.title,
    this.body,
    this.messageId,
  });

  final PushPayload payload;
  final String? title;
  final String? body;
  final String? messageId;
}

/// Isolates Firebase Messaging so unit tests can substitute a fake.
abstract class FcmGateway {
  bool get isAvailable;

  Future<void> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushMessage> get onForegroundMessage;

  Stream<PushMessage> get onMessageOpenedApp;

  Future<PushMessage?> getInitialMessage();
}

class DisabledFcmGateway implements FcmGateway {
  const DisabledFcmGateway();

  @override
  bool get isAvailable => false;

  @override
  Future<void> requestPermission() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<PushMessage> get onForegroundMessage => const Stream<PushMessage>.empty();

  @override
  Stream<PushMessage> get onMessageOpenedApp => const Stream<PushMessage>.empty();

  @override
  Future<PushMessage?> getInitialMessage() async => null;
}

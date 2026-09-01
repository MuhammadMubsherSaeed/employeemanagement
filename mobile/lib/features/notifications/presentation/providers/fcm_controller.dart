import 'dart:async';

import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/session/logout_side_effects.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/utils/app_logger.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/services/fcm_gateway.dart';
import 'package:flutter_base/features/notifications/domain/services/firebase_notification_service.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_list_controller.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/providers/unread_count_controller.dart';
import 'package:flutter_base/features/notifications/presentation/states/notification_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcmController extends Notifier<FcmSessionState> {
  StreamSubscription<PushMessage>? _foreground;
  StreamSubscription<PushMessage>? _opened;
  StreamSubscription<String>? _tokenRefresh;
  String? _lastHandledMessageId;
  PushMessage? _pendingOpened;
  bool _handlingOpened = false;
  Future<void>? _syncJob;

  @override
  FcmSessionState build() {
    final LogoutSideEffects effects = ref.read(logoutSideEffectsProvider);
    effects.register(_deactivateCurrentToken);
    ref.onDispose(() {
      effects.unregister(_deactivateCurrentToken);
      _foreground?.cancel();
      _opened?.cancel();
      _tokenRefresh?.cancel();
    });
    ref.listen<AuthState>(authControllerProvider, (
      AuthState? previous,
      AuthState next,
    ) {
      if (next is AuthAuthenticated) {
        Future<void>.microtask(syncAfterAuth);
      } else if (next is AuthUnauthenticated) {
        _clearLocal();
      }
    });
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      Future<void>.microtask(syncAfterAuth);
    }
    return const FcmSessionState();
  }

  PushMessage? takePendingOpened() {
    final PushMessage? pending = _pendingOpened;
    _pendingOpened = null;
    return pending;
  }

  Stream<PushMessage> get foregroundMessages {
    return ref.read(firebaseNotificationServiceProvider).onForegroundMessage;
  }

  Stream<PushMessage> get openedMessages {
    return ref.read(firebaseNotificationServiceProvider).onOpenedMessage;
  }

  Future<void> syncAfterAuth() {
    return _syncJob ??= _sync().whenComplete(() {
      _syncJob = null;
    });
  }

  Future<void> _sync() async {
    state = state.copyWith(isSyncing: true);
    final FirebaseNotificationService service =
        ref.read(firebaseNotificationServiceProvider);
    try {
      await service.initialize();
      await _attachListeners(service);
      await _registerCurrentToken(service);
      await ref
          .read(unreadNotificationCountControllerProvider.notifier)
          .refresh();
      final PushMessage? initial = await service.getInitialMessage();
      if (initial != null) {
        _pendingOpened = initial;
      }
    } catch (error, stack) {
      AppLogger.error('FCM session sync failed', error, stack);
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> onAppResumed() async {
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return;
    }
    await ref.read(unreadNotificationCountControllerProvider.notifier).refresh();
  }

  Future<void> _attachListeners(FirebaseNotificationService service) async {
    _foreground ??= service.onForegroundMessage.listen(_onForeground);
    _opened ??= service.onOpenedMessage.listen(_queueOpened);
    _tokenRefresh ??= service.onTokenRefresh.listen((String token) {
      unawaited(_registerToken(service, token));
    });
  }

  void _onForeground(PushMessage message) {
    unawaited(
      ref.read(unreadNotificationCountControllerProvider.notifier).refresh(),
    );
    unawaited(ref.read(notificationListControllerProvider.notifier).refresh());
  }

  void _queueOpened(PushMessage message) {
    if (_lastHandledMessageId != null &&
        message.messageId != null &&
        message.messageId == _lastHandledMessageId) {
      return;
    }
    _pendingOpened = message;
  }

  Future<void> _registerCurrentToken(FirebaseNotificationService service) {
    return service.getToken().then((String? token) async {
      if (token == null || token.isEmpty) {
        return;
      }
      await _registerToken(service, token);
    });
  }

  Future<void> _registerToken(
    FirebaseNotificationService service,
    String token,
  ) async {
    if (token.trim().length < 8) {
      return;
    }
    if (state.lastToken == token && state.registrationId != null) {
      return;
    }
    try {
      final String? existingId = state.registrationId ??
          await ref.read(secureStorageServiceProvider).read(
                StorageKeys.fcmDeviceTokenId,
              );
      DeviceTokenRegistration registration;
      if (existingId != null &&
          existingId.isNotEmpty &&
          state.lastToken != null &&
          state.lastToken != token) {
        registration = await ref.read(updateDeviceTokenUseCaseProvider)(
          existingId,
          UpdateDeviceTokenBody(
            token: token,
            platform: service.currentPlatform(),
            deviceName: service.deviceName(),
          ),
        );
      } else {
        registration = await ref.read(registerDeviceTokenUseCaseProvider)(
          RegisterDeviceTokenBody(
            token: token,
            platform: service.currentPlatform(),
            deviceName: service.deviceName(),
          ),
        );
      }
      await ref.read(secureStorageServiceProvider).write(
            StorageKeys.fcmDeviceTokenId,
            registration.id,
          );
      state = state.copyWith(
        registrationId: registration.id,
        lastToken: token,
      );
    } catch (error, stack) {
      AppLogger.error('FCM token registration failed', error, stack);
    }
  }

  Future<void> _deactivateCurrentToken() async {
    final String? id = state.registrationId ??
        await ref.read(secureStorageServiceProvider).read(
              StorageKeys.fcmDeviceTokenId,
            );
    if (id == null || id.isEmpty) {
      _clearLocal();
      return;
    }
    try {
      await ref.read(removeDeviceTokenUseCaseProvider)(id);
    } catch (error, stack) {
      AppLogger.error('FCM token deactivation failed', error, stack);
    } finally {
      _clearLocal();
    }
  }

  void _clearLocal() {
    unawaited(
      ref.read(secureStorageServiceProvider).delete(StorageKeys.fcmDeviceTokenId),
    );
    state = const FcmSessionState();
    _pendingOpened = null;
    _lastHandledMessageId = null;
  }

  bool markHandled(String? messageId) {
    if (messageId != null && messageId == _lastHandledMessageId) {
      return false;
    }
    if (_handlingOpened) {
      return false;
    }
    _handlingOpened = true;
    _lastHandledMessageId = messageId;
    _handlingOpened = false;
    return true;
  }
}

final fcmControllerProvider =
    NotifierProvider<FcmController, FcmSessionState>(FcmController.new);

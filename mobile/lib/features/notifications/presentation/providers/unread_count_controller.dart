import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_error_mapper.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_base/features/notifications/presentation/states/notification_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnreadNotificationCountController
    extends Notifier<UnreadNotificationCountState> {
  bool _inFlight = false;

  @override
  UnreadNotificationCountState build() {
    ref.listen<AuthState>(authControllerProvider, (_, AuthState next) {
      if (next is AuthAuthenticated) {
        Future<void>.microtask(refresh);
      } else {
        state = const UnreadNotificationCountState();
      }
    });
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      Future<void>.microtask(refresh);
    }
    return const UnreadNotificationCountState();
  }

  Future<void> refresh() async {
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      state = const UnreadNotificationCountState();
      return;
    }
    if (_inFlight) {
      return;
    }
    _inFlight = true;
    state = state.copyWith(isLoading: state.count == 0, clearError: true);
    try {
      final int count =
          await ref.read(getUnreadNotificationCountUseCaseProvider)();
      state = UnreadNotificationCountState(
        count: count < 0 ? 0 : count,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: NotificationErrorMapper.message(error),
      );
    } finally {
      _inFlight = false;
    }
  }
}

final unreadNotificationCountControllerProvider = NotifierProvider<
    UnreadNotificationCountController, UnreadNotificationCountState>(
  UnreadNotificationCountController.new,
);

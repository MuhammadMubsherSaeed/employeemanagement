import 'package:flutter/material.dart';
import 'package:flutter_base/features/notifications/presentation/providers/unread_count_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnreadNotificationBadge extends ConsumerWidget {
  const UnreadNotificationBadge({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String label =
        ref.watch(unreadNotificationCountControllerProvider).badgeLabel;
    return Badge(
      isLabelVisible: label.isNotEmpty,
      label: Text(label),
      child: child,
    );
  }
}

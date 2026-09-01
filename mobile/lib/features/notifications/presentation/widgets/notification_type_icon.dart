import 'package:flutter/material.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_presentation.dart';

class NotificationTypeIcon extends StatelessWidget {
  const NotificationTypeIcon({
    super.key,
    required this.type,
    this.unread = false,
  });

  final AppNotificationType type;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: unread
          ? colors.primary.withValues(alpha: 0.16)
          : colors.surfaceContainerHighest,
      child: Icon(
        NotificationPresentation.icon(type),
        color: unread ? colors.primary : colors.onSurfaceVariant,
      ),
    );
  }
}

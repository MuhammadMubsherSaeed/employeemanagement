import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_icon_well.dart';

class LeaveSummaryCard extends StatelessWidget {
  const LeaveSummaryCard({
    super.key,
    required this.pendingCount,
    this.onTap,
    this.title = 'Pending leave requests',
  });

  final int pendingCount;
  final VoidCallback? onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label: '$title $pendingCount',
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            const AppIconWell(icon: Icons.event_available_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    pendingCount == 0
                        ? 'No pending requests'
                        : '$pendingCount pending',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            Text('$pendingCount', style: text.headlineSmall),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}

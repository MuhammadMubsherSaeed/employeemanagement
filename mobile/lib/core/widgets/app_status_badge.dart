import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_colors.dart';

enum AppBadgeTone { success, warning, error, info, neutral }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (tone) {
      AppBadgeTone.success => AppColors.success,
      AppBadgeTone.warning => AppColors.warning,
      AppBadgeTone.error => AppColors.danger,
      AppBadgeTone.info => AppColors.info,
      AppBadgeTone.neutral => Theme.of(context).colorScheme.outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

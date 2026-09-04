import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

enum AppBadgeTone { success, warning, error, info, neutral }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final AppBadgeTone tone;

  static Color colorOf(BuildContext context, AppBadgeTone tone) {
    final Brightness brightness = Theme.of(context).brightness;
    return switch (tone) {
      AppBadgeTone.success => AppColors.successOf(brightness),
      AppBadgeTone.warning => AppColors.warningOf(brightness),
      AppBadgeTone.error => AppColors.dangerOf(brightness),
      AppBadgeTone.info => AppColors.infoOf(brightness),
      AppBadgeTone.neutral => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color color = colorOf(context, tone);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.badge,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
              ),
        ),
      ),
    );
  }
}

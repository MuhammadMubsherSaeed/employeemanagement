import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

enum AppCardVariant { outlined, elevated, flat }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.margin,
    this.onTap,
    this.variant = AppCardVariant.outlined,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget content = Padding(padding: padding, child: child);
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: AppRadius.card,
      side: variant == AppCardVariant.flat
          ? BorderSide.none
          : BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
    );

    final Widget card = Material(
      color: variant == AppCardVariant.flat
          ? scheme.surfaceContainerHighest
          : scheme.surface,
      elevation: variant == AppCardVariant.elevated
          ? AppElevation.sm
          : AppElevation.none,
      shadowColor: variant == AppCardVariant.elevated
          ? const Color(0x14101828)
          : Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              child: content,
            ),
    );

    if (margin == null) {
      return card;
    }
    return Padding(padding: margin!, child: card);
  }
}

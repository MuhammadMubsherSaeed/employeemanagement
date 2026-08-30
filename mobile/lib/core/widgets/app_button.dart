import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary ||
                      variant == AppButtonVariant.secondary
                  ? colors.onPrimary
                  : colors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
            ],
          );

    final VoidCallback? callback = isLoading ? null : onPressed;

    final Widget button = switch (variant) {
      AppButtonVariant.primary =>
        ElevatedButton(onPressed: callback, child: child),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.secondary,
            foregroundColor: colors.onSecondary,
          ),
          child: child,
        ),
      AppButtonVariant.outlined =>
        OutlinedButton(onPressed: callback, child: child),
      AppButtonVariant.text => TextButton(onPressed: callback, child: child),
    };

    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger }

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
    final bool enabled = onPressed != null && !isLoading;
    final Widget child = isLoading
        ? SizedBox(
            width: AppDimensions.iconMd,
            height: AppDimensions.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: AppDimensions.loaderStroke,
              color: variant == AppButtonVariant.outlined ||
                      variant == AppButtonVariant.text
                  ? colors.primary
                  : colors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppDimensions.iconMd),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, overflow: TextOverflow.ellipsis),
            ],
          );

    final VoidCallback? callback = enabled ? onPressed : null;
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
      AppButtonVariant.danger => ElevatedButton(
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dangerOf(Theme.of(context).brightness),
            foregroundColor: Colors.white,
          ),
          child: child,
        ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

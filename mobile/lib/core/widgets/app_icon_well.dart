import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_radius.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

class AppIconWell extends StatelessWidget {
  const AppIconWell({
    super.key,
    required this.icon,
    this.color,
    this.size = AppDimensions.avatarLg,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        icon,
        color: tint,
        size: size * 0.46,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_icon_well.dart';
import 'package:flutter_base/core/widgets/app_skeleton.dart';

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.color,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      button: onTap != null,
      label: '$title $value',
      child: AppCard(
        onTap: onTap,
        child: isLoading
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeleton(height: 20, width: 20),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton(height: 28, width: 72),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (icon != null) ...<Widget>[
                        AppIconWell(
                          icon: icon!,
                          color: tint,
                          size: 36,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: text.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: text.headlineSmall),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

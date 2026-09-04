import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_icon_well.dart';

class AppModuleTile extends StatelessWidget {
  const AppModuleTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: title,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppIconWell(icon: icon, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppModuleGrid extends StatelessWidget {
  const AppModuleGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : AppBreakpoints.medium;
        final int columns = AppBreakpoints.columnsFor(
          maxWidth,
          compact: 2,
          mediumColumns: 3,
          expandedColumns: 4,
        );
        const double gap = AppSpacing.sm;
        final double width = (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

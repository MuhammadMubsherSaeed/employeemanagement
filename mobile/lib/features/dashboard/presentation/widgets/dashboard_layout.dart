import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/features/dashboard/presentation/widgets/dashboard_stat_card.dart';

const double kDashboardTabletBreakpoint = 700;

class DashboardStatGrid extends StatelessWidget {
  const DashboardStatGrid({super.key, required this.children});

  final List<DashboardStatCard> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : kDashboardTabletBreakpoint;
        final int columns =
            maxWidth >= kDashboardTabletBreakpoint ? 4 : 2;
        const double gap = AppSpacing.sm;
        final double width = (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final DashboardStatCard child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

String dashboardGreeting(DateTime now) {
  final int hour = now.hour;
  if (hour < 12) {
    return 'Good morning';
  }
  if (hour < 17) {
    return 'Good afternoon';
  }
  return 'Good evening';
}

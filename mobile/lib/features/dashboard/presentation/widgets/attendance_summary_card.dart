import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({
    super.key,
    required this.present,
    required this.absent,
    required this.late,
    required this.onLeave,
    this.title = "Today's attendance",
  });

  final int present;
  final int absent;
  final int late;
  final int onLeave;
  final String title;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Brightness brightness = Theme.of(context).brightness;
    return Semantics(
      label: 'Present $present, absent $absent, late $late, on leave $onLeave',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _row(
              context,
              'Present',
              present,
              Icons.check_circle_outline,
              AppColors.successOf(brightness),
            ),
            _row(
              context,
              'Absent',
              absent,
              Icons.highlight_off_outlined,
              AppColors.dangerOf(brightness),
            ),
            _row(
              context,
              'Late',
              late,
              Icons.schedule_outlined,
              AppColors.warningOf(brightness),
            ),
            _row(
              context,
              'On leave',
              onLeave,
              Icons.event_busy_outlined,
              AppColors.infoOf(brightness),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(icon, size: AppDimensions.iconMd, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text('$value', style: text.titleSmall),
        ],
      ),
    );
  }
}

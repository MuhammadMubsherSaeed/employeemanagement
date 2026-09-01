import 'package:flutter/material.dart';
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
    return Semantics(
      label: 'Present $present, absent $absent, late $late, on leave $onLeave',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _row(context, 'Present', present, Icons.check_circle_outline),
            _row(context, 'Absent', absent, Icons.highlight_off_outlined),
            _row(context, 'Late', late, Icons.schedule_outlined),
            _row(context, 'On leave', onLeave, Icons.event_busy_outlined),
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
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text('$value', style: text.titleSmall),
        ],
      ),
    );
  }
}

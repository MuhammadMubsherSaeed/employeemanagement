import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.count,
    this.label = 'Matching records',
  });

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      label: '$count $label',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: text.bodyMedium)),
            Text('$count', style: text.titleMedium),
          ],
        ),
      ),
    );
  }
}

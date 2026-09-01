import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

class ReportFilterChip extends StatelessWidget {
  const ReportFilterChip({
    super.key,
    required this.label,
    this.onDeleted,
  });

  final String label;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

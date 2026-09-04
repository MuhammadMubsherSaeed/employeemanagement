import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 120,
  });

  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(label, style: text.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

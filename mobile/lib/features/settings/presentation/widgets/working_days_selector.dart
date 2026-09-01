import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';

class WorkingDaysSelector extends StatelessWidget {
  const WorkingDaysSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Working days', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: kWeekdayNames.map((String day) {
            final bool isSelected = selected.contains(day);
            return FilterChip(
              label: Text(_label(day)),
              selected: isSelected,
              onSelected: enabled
                  ? (bool value) {
                      final List<String> next = List<String>.from(selected);
                      if (value) {
                        if (!next.contains(day)) {
                          next.add(day);
                        }
                      } else {
                        next.remove(day);
                      }
                      onChanged(next);
                    }
                  : null,
            );
          }).toList(),
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  static String _label(String day) {
    if (day.isEmpty) {
      return day;
    }
    return '${day[0].toUpperCase()}${day.substring(1)}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.icon = Icons.calendar_today_outlined,
  });

  final String label;
  final DateTime? value;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String display = value == null
        ? (hint ?? 'Select a date')
        : AppDateFormatter.date(value!);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: Icon(icon, size: AppDimensions.iconMd),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            display,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: value == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
          ),
        ),
      ),
    );
  }
}

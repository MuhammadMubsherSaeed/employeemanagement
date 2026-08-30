import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

class UpcomingModulePlaceholder extends StatelessWidget {
  const UpcomingModulePlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screen,
      child: Center(
        child: Text(
          '$title module coming soon.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

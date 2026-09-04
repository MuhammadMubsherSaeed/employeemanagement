import 'package:flutter/material.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';

class UpcomingModulePlaceholder extends StatelessWidget {
  const UpcomingModulePlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: '$title module coming soon.',
      subtitle: 'Related records will appear here when this section is available.',
      icon: Icons.upcoming_outlined,
    );
  }
}

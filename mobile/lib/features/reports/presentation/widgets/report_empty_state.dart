import 'package:flutter/material.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';

class ReportEmptyState extends StatelessWidget {
  const ReportEmptyState({
    super.key,
    required this.message,
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: message,
      subtitle: subtitle ?? 'Try a different search or clear filters.',
      icon: Icons.assessment_outlined,
    );
  }
}

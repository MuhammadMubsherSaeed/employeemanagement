import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height = AppSpacing.md});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Divider(height: height);
  }
}

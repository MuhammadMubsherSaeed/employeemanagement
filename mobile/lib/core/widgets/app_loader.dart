import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.message,
    this.compact = false,
  });

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = SizedBox(
      width: compact ? AppDimensions.iconLg : AppDimensions.avatarMd,
      height: compact ? AppDimensions.iconLg : AppDimensions.avatarMd,
      child: const CircularProgressIndicator(),
    );
    return Center(
      child: Padding(
        padding: compact ? EdgeInsets.zero : AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            indicator,
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

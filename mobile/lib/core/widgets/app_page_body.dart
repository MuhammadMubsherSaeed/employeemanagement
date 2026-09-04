import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_breakpoints.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';

class AppPageBody extends StatelessWidget {
  const AppPageBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxContentWidth,
        ),
        child: Padding(
          padding: padding ?? AppBreakpoints.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

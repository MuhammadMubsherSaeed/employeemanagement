import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 360;
  static const double medium = 600;
  static const double expanded = 840;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < medium;

  static bool isTablet(BuildContext context) => widthOf(context) >= medium;

  static bool isExpanded(BuildContext context) => widthOf(context) >= expanded;

  static int columnsFor(
    double width, {
    int compact = 2,
    int mediumColumns = 3,
    int expandedColumns = 4,
  }) {
    if (width >= expanded) {
      return expandedColumns;
    }
    if (width >= medium) {
      return mediumColumns;
    }
    return compact;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final double width = widthOf(context);
    if (width >= expanded) {
      return const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      );
    }
    if (width >= medium) {
      return const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      );
    }
    return AppSpacing.screen;
  }

  static double contentMaxWidth(BuildContext context) {
    return isExpanded(context)
        ? AppDimensions.maxContentWidth
        : double.infinity;
  }
}

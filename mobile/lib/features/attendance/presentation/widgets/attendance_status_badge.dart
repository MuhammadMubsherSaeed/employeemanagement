import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';

class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({super.key, required this.status});

  final AttendanceStatus status;

  static AppBadgeTone toneOf(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => AppBadgeTone.success,
      AttendanceStatus.late => AppBadgeTone.warning,
      AttendanceStatus.halfDay => AppBadgeTone.info,
      AttendanceStatus.absent => AppBadgeTone.error,
      AttendanceStatus.leave => AppBadgeTone.info,
      AttendanceStatus.holiday => AppBadgeTone.neutral,
      AttendanceStatus.weekend => AppBadgeTone.neutral,
      AttendanceStatus.unknown => AppBadgeTone.neutral,
    };
  }

  static Color colorOf(AttendanceStatus status, [BuildContext? context]) {
    if (context != null) {
      return AppStatusBadge.colorOf(context, toneOf(status));
    }
    return switch (toneOf(status)) {
      AppBadgeTone.success => AppColors.success,
      AppBadgeTone.warning => AppColors.warning,
      AppBadgeTone.error => AppColors.danger,
      AppBadgeTone.info => AppColors.info,
      AppBadgeTone.neutral => AppColors.body,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: status.label, tone: toneOf(status));
  }
}

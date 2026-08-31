import 'package:flutter/material.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';

class LeaveStatusBadge extends StatelessWidget {
  const LeaveStatusBadge({super.key, required this.status});

  final LeaveRequestStatus status;

  static AppBadgeTone toneOf(LeaveRequestStatus status) {
    return switch (status) {
      LeaveRequestStatus.pending => AppBadgeTone.warning,
      LeaveRequestStatus.approved => AppBadgeTone.success,
      LeaveRequestStatus.rejected => AppBadgeTone.error,
      LeaveRequestStatus.cancelled => AppBadgeTone.neutral,
      LeaveRequestStatus.unknown => AppBadgeTone.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: status.label, tone: toneOf(status));
  }
}

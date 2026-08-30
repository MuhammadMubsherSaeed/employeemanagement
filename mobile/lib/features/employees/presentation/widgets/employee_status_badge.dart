import 'package:flutter/material.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';

class EmployeeStatusBadge extends StatelessWidget {
  const EmployeeStatusBadge({super.key, required this.status});

  final EmployeeStatus status;

  @override
  Widget build(BuildContext context) {
    final AppBadgeTone tone = switch (status) {
      EmployeeStatus.active => AppBadgeTone.success,
      EmployeeStatus.onLeave => AppBadgeTone.warning,
      EmployeeStatus.terminated => AppBadgeTone.error,
      EmployeeStatus.inactive => AppBadgeTone.neutral,
      EmployeeStatus.unknown => AppBadgeTone.neutral,
    };
    return AppStatusBadge(label: status.label, tone: tone);
  }
}

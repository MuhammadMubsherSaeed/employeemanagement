import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/attendance/domain/working_duration.dart';
import 'package:flutter_base/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_status_badge.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_status_badge.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_opener.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_status_badge.dart';
import 'package:flutter_base/features/reports/domain/entities/report_items.dart';

class AttendanceReportCard extends StatelessWidget {
  const AttendanceReportCard({super.key, required this.item});

  final AttendanceReportItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.employee.fullName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(item.employee.employeeCode),
          if (item.employee.department != null)
            Text(item.employee.department!.name),
          const SizedBox(height: AppSpacing.xs),
          Text(item.date == null ? '—' : AppDateFormatter.date(item.date!)),
          Text(
            '${_time(item.checkIn)} – ${_time(item.checkOut)}  ·  ${WorkingDuration.format(item.workingMinutes)}',
          ),
          const SizedBox(height: AppSpacing.xs),
          AttendanceStatusBadge(status: item.status),
        ],
      ),
    );
  }
}

class LeaveReportCard extends StatelessWidget {
  const LeaveReportCard({super.key, required this.item});

  final LeaveReportItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.employee.fullName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(item.leaveType.name),
          if (item.employee.department != null)
            Text(item.employee.department!.name),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.startDate == null || item.endDate == null
                ? '—'
                : AppDateFormatter.dateRange(item.startDate!, item.endDate!),
          ),
          Text(leaveDaysLabel(item.totalDays)),
          Text(item.approvedBy?.email ?? 'Not approved'),
          if (item.approvedAt != null)
            Text(AppDateFormatter.date(item.approvedAt!)),
          const SizedBox(height: AppSpacing.xs),
          LeaveStatusBadge(status: item.status),
        ],
      ),
    );
  }
}

class EmployeeReportCard extends StatelessWidget {
  const EmployeeReportCard({super.key, required this.item});

  final EmployeeReportItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.fullName, style: Theme.of(context).textTheme.titleMedium),
          Text(item.employeeCode),
          Text(item.department?.name ?? 'No department'),
          Text(item.position?.title ?? 'No position'),
          Text(item.employmentType.label),
          Text(
            item.joiningDate == null
                ? '—'
                : AppDateFormatter.date(item.joiningDate!),
          ),
          Text(item.manager?.fullName ?? 'No manager'),
          const SizedBox(height: AppSpacing.xs),
          EmployeeStatusBadge(status: item.status),
        ],
      ),
    );
  }
}

class DeviceReportCard extends StatelessWidget {
  const DeviceReportCard({super.key, required this.item});

  final DeviceReportItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.assetCode, style: Theme.of(context).textTheme.titleMedium),
          Text(item.type),
          Text('${item.manufacturer} ${item.model}'.trim()),
          if (item.serialNumber != null) Text(item.serialNumber!),
          Text(item.assignedEmployee?.fullName ?? 'Unassigned'),
          Text(
            item.assignedAt == null
                ? '—'
                : AppDateFormatter.date(item.assignedAt!),
          ),
          if (item.hasCost) Text(item.cost ?? '—'),
          const SizedBox(height: AppSpacing.xs),
          DeviceStatusBadge(status: item.status),
        ],
      ),
    );
  }
}

String _time(DateTime? value) {
  if (value == null) {
    return '—';
  }
  return AppDateFormatter.time(value.toLocal());
}

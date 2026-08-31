import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_opener.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_status_badge.dart';

class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.showEmployee = false,
  });

  final LeaveRequest request;
  final VoidCallback? onTap;
  final bool showEmployee;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String typeName = request.leaveType?.name ?? 'Leave';
    return Semantics(
      button: onTap != null,
      label: '$typeName ${request.status.label}',
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(typeName, style: text.titleMedium),
                ),
                LeaveStatusBadge(status: request.status),
              ],
            ),
            if (showEmployee && request.employee != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(request.employee!.fullName, style: text.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppDateFormatter.dateRange(request.startDate, request.endDate),
              style: text.bodyMedium,
            ),
            Text(
              leaveDaysLabel(request.totalDays),
              style: text.bodyMedium,
            ),
            if (request.createdAt != null)
              Text(
                AppDateFormatter.date(request.createdAt!.toLocal()),
                style: text.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

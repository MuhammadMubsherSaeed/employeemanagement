import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_opener.dart';

class LeaveBalanceCard extends StatelessWidget {
  const LeaveBalanceCard({
    super.key,
    required this.balance,
    this.onAllocate,
    this.showEmployee = false,
  });

  final LeaveBalance balance;
  final VoidCallback? onAllocate;
  final bool showEmployee;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String typeName = balance.leaveType?.name ?? 'Leave';
    return AppCard(
      onTap: onAllocate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(typeName, style: text.titleMedium),
              ),
              Text('${balance.year}', style: text.bodySmall),
            ],
          ),
          if (showEmployee && balance.employee != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(balance.employee!.fullName, style: text.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Remaining: ${leaveDaysLabel(balance.remainingDays)}',
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Allocated: ${leaveDaysLabel(balance.allocatedDays)}',
            style: text.bodyMedium,
          ),
          Text(
            'Used: ${leaveDaysLabel(balance.usedDays)}',
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

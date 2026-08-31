import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_status_badge.dart';

class DeviceHistoryTimeline extends StatelessWidget {
  const DeviceHistoryTimeline({
    super.key,
    required this.items,
  });

  final List<DeviceHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: items
          .map(
            (DeviceHistoryItem item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DeviceHistoryTile(item: item),
            ),
          )
          .toList(),
    );
  }
}

class DeviceHistoryTile extends StatelessWidget {
  const DeviceHistoryTile({super.key, required this.item});

  final DeviceHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String name = item.employee?.fullName ?? 'Employee';
    final String assigned = AppDateFormatter.dateTime(item.assignedAt);
    final String returned = item.returnedAt == null
        ? 'Currently assigned'
        : 'Returned ${AppDateFormatter.dateTime(item.returnedAt!)}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(name, style: text.titleMedium)),
              if (item.isActive)
                const DeviceStatusBadge(status: DeviceStatus.assigned),
            ],
          ),
          if (item.employee?.employeeCode.isNotEmpty == true) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(item.employee!.employeeCode, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text('Assigned $assigned', style: text.bodyMedium),
          Text(returned, style: text.bodyMedium),
          if (item.conditionOnAssignment.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Condition out: ${item.conditionOnAssignment}',
              style: text.bodySmall,
            ),
          ],
          if (item.conditionOnReturn.isNotEmpty)
            Text(
              'Condition in: ${item.conditionOnReturn}',
              style: text.bodySmall,
            ),
          if (item.notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(item.notes, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

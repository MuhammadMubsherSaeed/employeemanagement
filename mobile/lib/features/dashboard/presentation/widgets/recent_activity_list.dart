import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({
    super.key,
    required this.items,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onSelect,
  });

  final List<DashboardActivity> items;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<DashboardActivity>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoader(message: 'Loading activity…');
    }
    if (error != null) {
      return AppErrorWidget(message: error!, onRetry: onRetry);
    }
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'No recent activity',
        subtitle: 'Audit events for your company will appear here.',
        icon: Icons.history,
      );
    }
    return Column(
      children: <Widget>[
        for (final DashboardActivity item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ActivityTile(
              item: item,
              onTap: dashboardActivityRoute(item) == null
                  ? null
                  : () => onSelect?.call(item),
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, this.onTap});

  final DashboardActivity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String when = item.createdAt == null
        ? ''
        : AppDateFormatter.relative(item.createdAt!.toLocal());
    return Semantics(
      button: onTap != null,
      label: item.action,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.action,
                    style: text.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      item.resource,
                      if (item.actor?.email != null) item.actor!.email,
                      if (when.isNotEmpty) when,
                    ].join(' · '),
                    style: text.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

String? dashboardActivityRoute(DashboardActivity activity) {
  final String id = activity.resourceId.trim();
  if (id.isEmpty) {
    return null;
  }
  switch (activity.resource) {
    case 'employees.Employee':
      return AppRoutes.employee(id);
    case 'leave.LeaveRequest':
      return AppRoutes.leaveRequest(id);
    case 'devices.Device':
      return AppRoutes.device(id);
    default:
      return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/presentation/access_denied_screen.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_info_row.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/audit_logs/domain/audit_log_access.dart';
import 'package:flutter_base/features/audit_logs/domain/entities/audit_log.dart';
import 'package:flutter_base/features/audit_logs/presentation/providers/audit_log_list_controller.dart';
import 'package:flutter_base/features/audit_logs/presentation/states/audit_log_list_state.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(auditLogListControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double max = _scroll.position.maxScrollExtent;
    if (max <= 0) {
      return;
    }
    if (_scroll.position.pixels > max - 240) {
      ref.read(auditLogListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuditLogAccess access = AuditLogAccess(
      ref.watch(authorizationProvider),
    );
    if (!access.canView) {
      return const AccessDeniedScreen();
    }
    final AuditLogListState list = ref.watch(auditLogListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit logs')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(auditLogListControllerProvider.notifier).refresh(),
        child: _body(list),
      ),
    );
  }

  Widget _body(AuditLogListState list) {
    if (list.isInitialLoading && list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120, child: AppLoader(message: 'Loading audit logs…')),
        ],
      );
    }
    if (list.error != null && list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          AppErrorWidget(
            message: list.error!,
            onRetry: () =>
                ref.read(auditLogListControllerProvider.notifier).loadInitial(),
          ),
        ],
      );
    }
    if (list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 80),
          AppEmptyState(
            title: 'No audit logs',
            subtitle: 'Company activity will appear here.',
            icon: Icons.policy_outlined,
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: AppSpacing.screen,
      itemCount: list.items.length + (list.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        if (index >= list.items.length) {
          return const AppLoader();
        }
        final AuditLogEntry entry = list.items[index];
        return AppCard(
          onTap: () => context.push(AppRoutes.auditLog(entry.id), extra: entry),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppStatusBadge(
                label: entry.action,
                tone: AppBadgeTone.info,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${entry.entityType}${entry.entityId == null ? '' : ' · ${entry.entityId}'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (entry.user != null)
                      Text(
                        entry.user!.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (entry.createdAt != null)
                      Text(
                        AppDateFormatter.dateTime(entry.createdAt!.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AuditLogDetailsScreen extends StatelessWidget {
  const AuditLogDetailsScreen({super.key, this.entry});

  final AuditLogEntry? entry;

  @override
  Widget build(BuildContext context) {
    final AuditLogEntry? log = entry;
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: log == null
          ? const Padding(
              padding: AppSpacing.screen,
              child: AppEmptyState(
                title: 'Audit log unavailable',
                subtitle: AccessDeniedScreen.message,
                icon: Icons.lock_outline,
              ),
            )
          : ListView(
              padding: AppSpacing.screen,
              children: <Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(log.action, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AppInfoRow(label: 'Entity', value: log.entityType),
                      if (log.entityId != null)
                        AppInfoRow(label: 'ID', value: log.entityId!),
                      if (log.user != null)
                        AppInfoRow(label: 'Actor', value: log.user!.name),
                      if (log.ipAddress != null)
                        AppInfoRow(label: 'IP', value: log.ipAddress!),
                      if (log.createdAt != null)
                        AppInfoRow(
                          label: 'When',
                          value: AppDateFormatter.dateTime(
                            log.createdAt!.toLocal(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

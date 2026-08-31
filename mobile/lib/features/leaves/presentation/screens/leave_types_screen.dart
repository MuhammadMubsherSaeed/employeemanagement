import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_status_badge.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_type_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeaveTypesScreen extends ConsumerWidget {
  const LeaveTypesScreen({super.key});

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    LeaveType type,
  ) async {
    final LeaveTypeStatus next = type.isActive
        ? LeaveTypeStatus.inactive
        : LeaveTypeStatus.active;
    final LeaveType? updated =
        await ref.read(leaveTypeFormControllerProvider.notifier).update(
              type.id,
              LeaveTypeWrite.fromType(type).copyWith(status: next),
            );
    if (!context.mounted) {
      return;
    }
    if (updated != null) {
      context.showSnack(
        next == LeaveTypeStatus.active
            ? 'Leave type activated.'
            : 'Leave type deactivated.',
      );
    } else {
      final String? error = ref.read(leaveTypeFormControllerProvider).error;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LeaveType>> async = ref.watch(leaveTypesProvider);
    final bool busy = ref.watch(leaveTypeFormControllerProvider).isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Leave types')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.leavesTypesAdd),
        tooltip: 'Create leave type',
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const AppLoader(message: 'Loading leave types…'),
        error: (Object error, _) => AppErrorWidget(
          message: LeaveErrorMapper.message(error),
          onRetry: () => ref.invalidate(leaveTypesProvider),
        ),
        data: (List<LeaveType> items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(leaveTypesProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 80),
                  AppEmptyState(title: 'No leave types available.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(leaveTypesProvider),
            child: ListView.separated(
              padding: AppSpacing.screen,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final LeaveType type = items[index];
                return AppCard(
                  onTap: () => context.push(AppRoutes.leaveTypeEdit(type.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              type.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          AppStatusBadge(
                            label: type.status.label,
                            tone: type.isActive
                                ? AppBadgeTone.success
                                : AppBadgeTone.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(type.code, style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        'Allowed: ${type.daysAllowed} days',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: type.isActive ? 'Deactivate' : 'Activate',
                        variant: AppButtonVariant.outlined,
                        expand: false,
                        onPressed: busy ? null : () => _toggle(context, ref, type),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

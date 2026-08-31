import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_action_controller.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/states/apply_leave_state.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_balance_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveBalanceScreen extends ConsumerWidget {
  const LeaveBalanceScreen({super.key});

  Future<void> _allocate(
    BuildContext context,
    WidgetRef ref,
    LeaveBalance balance,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: '${balance.allocatedDays}',
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Set allocated days'),
          content: AppTextField(
            controller: controller,
            label: 'Allocated days',
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }
    final int? days = int.tryParse(controller.text.trim());
    controller.dispose();
    if (days == null || !context.mounted) {
      return;
    }
    final LeaveBalance? updated =
        await ref.read(leaveActionControllerProvider.notifier).allocate(
              id: balance.id,
              allocatedDays: days,
            );
    if (!context.mounted) {
      return;
    }
    if (updated != null) {
      context.showSnack('Leave allocation updated.');
    } else {
      final String? error = ref.read(leaveActionControllerProvider).error;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authControllerProvider);
    final LeaveAccess access = LeaveAccess(
      auth is AuthAuthenticated ? auth.user.role : UserRole.unknown,
    );
    final AsyncValue<List<LeaveBalance>> async =
        ref.watch(leaveBalancesProvider);
    final LeaveActionState action = ref.watch(leaveActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leave balances')),
      body: async.when(
        loading: () => const AppLoader(message: 'Loading balances…'),
        error: (Object error, _) => AppErrorWidget(
          message: LeaveErrorMapper.message(error),
          onRetry: () => ref.invalidate(leaveBalancesProvider),
        ),
        data: (List<LeaveBalance> items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(leaveBalancesProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 80),
                  AppEmptyState(title: 'No leave balance available.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(leaveBalancesProvider),
            child: ListView.separated(
              padding: AppSpacing.screen,
              itemCount: items.length + (action.isAllocating ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                if (index >= items.length) {
                  return const AppLoader();
                }
                final LeaveBalance balance = items[index];
                return LeaveBalanceCard(
                  balance: balance,
                  showEmployee: access.canViewTeam,
                  onAllocate: access.canManage && !action.isBusy
                      ? () => _allocate(context, ref, balance)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/leave_access.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_error_mapper.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_requests_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/leave_requests_state.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_balance_card.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeaveDashboardScreen extends ConsumerStatefulWidget {
  const LeaveDashboardScreen({super.key});

  @override
  ConsumerState<LeaveDashboardScreen> createState() =>
      _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends ConsumerState<LeaveDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref
          .read(leaveRequestsControllerProvider(LeaveListKind.all).notifier)
          .loadInitial();
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(leaveBalancesProvider);
    await ref
        .read(leaveRequestsControllerProvider(LeaveListKind.all).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    final LeaveAccess access = LeaveAccess(
      ref.watch(authorizationProvider),
    );
    final AsyncValue<List<LeaveBalance>> balances =
        ref.watch(leaveBalancesProvider);
    final LeaveRequestsState requests =
        ref.watch(leaveRequestsControllerProvider(LeaveListKind.all));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Requests',
            onPressed: () => context.push(AppRoutes.leavesRequests),
            icon: const Icon(Icons.list_alt_outlined),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () => context.push(AppRoutes.leavesHistory),
            icon: const Icon(Icons.history),
          ),
          if (access.canManage)
            IconButton(
              tooltip: 'Leave types',
              onPressed: () => context.push(AppRoutes.leavesTypes),
              icon: const Icon(Icons.tune_outlined),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screen,
          children: <Widget>[
            Text('Leave balances', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            balances.when(
              loading: () => const AppLoader(message: 'Loading balances…'),
              error: (Object error, _) => AppErrorWidget(
                message: LeaveErrorMapper.message(error),
                onRetry: () => ref.invalidate(leaveBalancesProvider),
              ),
              data: (List<LeaveBalance> items) {
                if (items.isEmpty) {
                  return const AppEmptyState(
                    title: 'No leave balance available.',
                    subtitle: 'Balances are created by your company.',
                  );
                }
                return Column(
                  children: items
                      .take(4)
                      .map(
                        (LeaveBalance balance) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: LeaveBalanceCard(
                            balance: balance,
                            showEmployee: access.canViewTeam,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.leavesBalances),
                child: const Text('View all balances'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (access.canCreate)
              AppButton(
                label: 'Apply for Leave',
                onPressed: () => context.push(AppRoutes.leavesApply),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Recent requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (requests.isInitialLoading)
              const AppLoader(message: 'Loading requests…')
            else if (requests.error != null && requests.items.isEmpty)
              AppErrorWidget(
                message: requests.error!,
                onRetry: () => ref
                    .read(
                      leaveRequestsControllerProvider(LeaveListKind.all)
                          .notifier,
                    )
                    .loadInitial(),
              )
            else if (requests.isEmpty)
              const AppEmptyState(title: 'No leave requests found.')
            else
              ...requests.items.take(5).map(
                    (LeaveRequest request) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: LeaveRequestCard(
                        request: request,
                        showEmployee: access.canViewTeam,
                        onTap: () => context.push(
                          access.canApprove && request.isPending
                              ? AppRoutes.leaveApproval(request.id)
                              : AppRoutes.leaveRequest(request.id),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

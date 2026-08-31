import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_requests_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/leave_requests_state.dart';
import 'package:flutter_base/features/leaves/presentation/widgets/leave_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveRequestListView extends ConsumerStatefulWidget {
  const LeaveRequestListView({
    super.key,
    required this.kind,
    required this.showEmployee,
    required this.onOpen,
  });

  final LeaveListKind kind;
  final bool showEmployee;
  final void Function(LeaveRequest request) onOpen;

  @override
  ConsumerState<LeaveRequestListView> createState() =>
      _LeaveRequestListViewState();
}

class _LeaveRequestListViewState extends ConsumerState<LeaveRequestListView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(leaveRequestsControllerProvider(widget.kind).notifier).loadInitial();
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
      ref.read(leaveRequestsControllerProvider(widget.kind).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LeaveRequestsState list =
        ref.watch(leaveRequestsControllerProvider(widget.kind));
    if (list.isInitialLoading) {
      return const AppLoader(message: 'Loading leave requests…');
    }
    if (list.error != null && list.items.isEmpty) {
      return AppErrorWidget(
        message: list.error!,
        onRetry: () => ref
            .read(leaveRequestsControllerProvider(widget.kind).notifier)
            .loadInitial(),
      );
    }
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref
            .read(leaveRequestsControllerProvider(widget.kind).notifier)
            .refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 80),
            AppEmptyState(
              title: 'No leave requests found.',
              subtitle: 'Try a different status, leave type, or date range.',
            ),
          ],
        ),
      );
    }
    final int extra = list.isLoadingMore || list.error != null ? 1 : 0;
    return RefreshIndicator(
      onRefresh: () => ref
          .read(leaveRequestsControllerProvider(widget.kind).notifier)
          .refresh(),
      child: ListView.separated(
        controller: _scroll,
        padding: AppSpacing.screen,
        itemCount: list.items.length + extra,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index >= list.items.length) {
            if (list.error != null) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppButton(
                  label: 'Retry',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => ref
                      .read(
                        leaveRequestsControllerProvider(widget.kind).notifier,
                      )
                      .loadMore(),
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final LeaveRequest request = list.items[index];
          return LeaveRequestCard(
            request: request,
            showEmployee: widget.showEmployee,
            onTap: () => widget.onOpen(request),
          );
        },
      ),
    );
  }
}

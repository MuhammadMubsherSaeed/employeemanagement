import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/presentation/providers/notification_list_controller.dart';
import 'package:flutter_base/features/notifications/presentation/states/notification_states.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationListView extends ConsumerStatefulWidget {
  const NotificationListView({
    super.key,
    required this.onOpen,
  });

  final void Function(AppNotification notification) onOpen;

  @override
  ConsumerState<NotificationListView> createState() =>
      _NotificationListViewState();
}

class _NotificationListViewState extends ConsumerState<NotificationListView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(notificationListControllerProvider.notifier).loadInitial();
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
      ref.read(notificationListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationListState list =
        ref.watch(notificationListControllerProvider);
    if (list.isInitialLoading) {
      return const AppLoader(message: 'Loading notifications…');
    }
    if (list.error != null && list.items.isEmpty) {
      return AppErrorWidget(
        message: list.error!,
        onRetry: () =>
            ref.read(notificationListControllerProvider.notifier).loadInitial(),
      );
    }
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationListControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: const AppEmptyState(
                title: "You're all caught up",
                subtitle: 'No notifications yet.',
                icon: Icons.notifications_none_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationListControllerProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scroll,
        padding: AppSpacing.screen,
        itemCount:
            list.items.length + (list.hasMore || list.error != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index >= list.items.length) {
            if (list.error != null) {
              return AppButton(
                label: 'Retry',
                variant: AppButtonVariant.outlined,
                onPressed: () => ref
                    .read(notificationListControllerProvider.notifier)
                    .loadMore(),
              );
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final AppNotification item = list.items[index];
          return NotificationCard(
            notification: item,
            onTap: () => widget.onOpen(item),
          );
        },
      ),
    );
  }
}

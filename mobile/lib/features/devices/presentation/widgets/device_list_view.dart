import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_list_controller.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceListView extends ConsumerStatefulWidget {
  const DeviceListView({
    super.key,
    required this.kind,
    required this.onOpen,
    this.emptyTitle = 'No devices found',
    this.emptySubtitle,
  });

  final DeviceListKind kind;
  final void Function(Device device) onOpen;
  final String emptyTitle;
  final String? emptySubtitle;

  @override
  ConsumerState<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends ConsumerState<DeviceListView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(deviceListControllerProvider(widget.kind).notifier).loadInitial();
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
      ref.read(deviceListControllerProvider(widget.kind).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeviceListState list =
        ref.watch(deviceListControllerProvider(widget.kind));
    if (list.isInitialLoading) {
      return const AppLoader(message: 'Loading devices…');
    }
    if (list.error != null && list.items.isEmpty) {
      return AppErrorWidget(
        message: list.error!,
        onRetry: () => ref
            .read(deviceListControllerProvider(widget.kind).notifier)
            .loadInitial(),
      );
    }
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref
            .read(deviceListControllerProvider(widget.kind).notifier)
            .refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: AppEmptyState(
                title: widget.emptyTitle,
                subtitle: widget.emptySubtitle,
                icon: Icons.devices_other_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(deviceListControllerProvider(widget.kind).notifier).refresh(),
      child: ListView.separated(
        controller: _scroll,
        padding: AppSpacing.screen,
        itemCount: list.items.length + (list.hasMore || list.error != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index >= list.items.length) {
            if (list.error != null) {
              return AppButton(
                label: 'Retry',
                variant: AppButtonVariant.outlined,
                onPressed: () => ref
                    .read(deviceListControllerProvider(widget.kind).notifier)
                    .loadMore(),
              );
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final Device device = list.items[index];
          return DeviceCard(
            device: device,
            onTap: () => widget.onOpen(device),
          );
        },
      ),
    );
  }
}

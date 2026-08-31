import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_history_controller.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_history_timeline.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceHistoryScreen extends ConsumerStatefulWidget {
  const DeviceHistoryScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<DeviceHistoryScreen> createState() =>
      _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends ConsumerState<DeviceHistoryScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref
          .read(deviceHistoryControllerProvider(widget.deviceId).notifier)
          .loadInitial();
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
      ref
          .read(deviceHistoryControllerProvider(widget.deviceId).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeviceHistoryState history =
        ref.watch(deviceHistoryControllerProvider(widget.deviceId));
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment history')),
      body: _body(history),
    );
  }

  Widget _body(DeviceHistoryState history) {
    if (history.isInitialLoading) {
      return const AppLoader(message: 'Loading history…');
    }
    if (history.error != null && history.items.isEmpty) {
      return AppErrorWidget(
        message: history.error!,
        onRetry: () => ref
            .read(deviceHistoryControllerProvider(widget.deviceId).notifier)
            .loadInitial(),
      );
    }
    if (history.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref
            .read(deviceHistoryControllerProvider(widget.deviceId).notifier)
            .refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 120),
            AppEmptyState(
              title: 'No assignment history',
              icon: Icons.history,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref
          .read(deviceHistoryControllerProvider(widget.deviceId).notifier)
          .refresh(),
      child: ListView(
        controller: _scroll,
        padding: AppSpacing.screen,
        children: <Widget>[
          DeviceHistoryTimeline(items: history.items),
          if (history.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: history.error != null
                  ? AppButton(
                      label: 'Retry',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => ref
                          .read(
                            deviceHistoryControllerProvider(widget.deviceId)
                                .notifier,
                          )
                          .loadMore(),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

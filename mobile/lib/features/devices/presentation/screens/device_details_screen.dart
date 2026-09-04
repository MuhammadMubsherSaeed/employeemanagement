import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_card.dart';
import 'package:flutter_base/core/widgets/app_dialog.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/core/auth/authorization_providers.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_action_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_history_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_assignment_dialog.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_history_timeline.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_info_row.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_status_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeviceDetailsScreen extends ConsumerStatefulWidget {
  const DeviceDetailsScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<DeviceDetailsScreen> createState() =>
      _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends ConsumerState<DeviceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref
          .read(deviceHistoryControllerProvider(widget.deviceId).notifier)
          .loadInitial();
    });
  }

  Future<void> _return(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Return device',
      message: 'Are you sure you want to mark this device as returned?',
      confirmLabel: 'Continue',
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final ReturnDeviceBody? body = await showDeviceReturnSheet(context: context);
    if (body == null || !context.mounted) {
      return;
    }
    final Device? result = await ref
        .read(deviceActionControllerProvider.notifier)
        .returnDevice(id: widget.deviceId, body: body);
    if (!context.mounted) {
      return;
    }
    if (result != null) {
      context.showSnack('Device returned.');
    } else {
      final String? error = ref.read(deviceActionControllerProvider).error;
      if (error != null) {
        context.showSnack(error);
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete device',
      message:
          'Are you sure you want to delete this device? Devices with assignment history may need to be retired instead.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final bool ok =
        await ref.read(deviceActionControllerProvider.notifier).delete(widget.deviceId);
    if (!context.mounted) {
      return;
    }
    if (ok) {
      context.showSnack('Device deleted.');
      context.pop();
      return;
    }
    final String? error = ref.read(deviceActionControllerProvider).error;
    if (error != null) {
      context.showSnack(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeviceAccess access = DeviceAccess(
      ref.watch(authorizationProvider),
    );
    final AsyncValue<Device> async =
        ref.watch(deviceDetailProvider(widget.deviceId));
    final DeviceActionState action = ref.watch(deviceActionControllerProvider);
    final DeviceHistoryState history =
        ref.watch(deviceHistoryControllerProvider(widget.deviceId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Device')),
        body: const AppLoader(),
      ),
      error: (Object error, _) => Scaffold(
        appBar: AppBar(title: const Text('Device')),
        body: AppErrorWidget(
          message: DeviceErrorMapper.message(error),
          onRetry: () => ref.invalidate(deviceDetailProvider(widget.deviceId)),
        ),
      ),
      data: (Device device) {
        return Scaffold(
          appBar: AppBar(
            title: Text(device.assetCode),
            actions: <Widget>[
              if (access.canUpdate)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => context.push(AppRoutes.deviceEdit(device.id)),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (access.canDelete)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: action.isBusy
                      ? null
                      : () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          body: ListView(
            padding: AppSpacing.screen,
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            device.assetCode,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        DeviceStatusBadge(status: device.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DeviceInfoRow(label: 'Type', value: device.type),
                    DeviceInfoRow(
                      label: 'Manufacturer',
                      value: device.manufacturer,
                    ),
                    DeviceInfoRow(label: 'Model', value: device.model),
                    DeviceInfoRow(
                      label: 'Serial',
                      value: device.serialNumber ?? '',
                    ),
                    if (device.hasCost)
                      DeviceInfoRow(label: 'Cost', value: device.cost ?? ''),
                    if (device.hasNotes)
                      DeviceInfoRow(label: 'Notes', value: device.notes ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: DeviceDetailsSection(
                  title: 'Purchase & warranty',
                  child: Column(
                    children: <Widget>[
                      DeviceInfoRow(
                        label: 'Purchased',
                        value: device.purchaseDate == null
                            ? ''
                            : AppDateFormatter.date(device.purchaseDate!),
                      ),
                      DeviceInfoRow(
                        label: 'Warranty',
                        value: device.warrantyExpiry == null
                            ? ''
                            : AppDateFormatter.date(device.warrantyExpiry!),
                      ),
                    ],
                  ),
                ),
              ),
              if (history.activeAssignment != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                DeviceDetailsSection(
                  title: 'Current assignment',
                  child: DeviceHistoryTile(item: history.activeAssignment!),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (access.canAssign && device.status.canAssign)
                AppButton(
                  label: 'Assign',
                  isLoading: action.isAssigning,
                  onPressed: action.isBusy
                      ? null
                      : () => context.push(AppRoutes.deviceAssign(device.id)),
                ),
              if (access.canReturn && device.status.canReturn) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Return',
                  variant: AppButtonVariant.outlined,
                  isLoading: action.isReturning,
                  onPressed: action.isBusy ? null : () => _return(context, ref),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'View history',
                variant: AppButtonVariant.text,
                onPressed: () =>
                    context.push(AppRoutes.deviceHistory(device.id)),
              ),
            ],
          ),
        );
      },
    );
  }
}

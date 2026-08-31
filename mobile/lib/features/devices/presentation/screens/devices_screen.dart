import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/devices/domain/device_access.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_list_controller.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_filter_sheet.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_list_view.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authControllerProvider);
    final DeviceAccess access = DeviceAccess(
      auth is AuthAuthenticated ? auth.user.role : UserRole.unknown,
    );
    final DeviceListState list =
        ref.watch(deviceListControllerProvider(DeviceListKind.inventory));
    final int filters = list.query.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: <Widget>[
          IconButton(
            tooltip: filters == 0 ? 'Filters' : 'Filters ($filters)',
            onPressed: () => _openFilters(context, ref),
            icon: Badge(
              isLabelVisible: filters > 0,
              label: Text('$filters'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      floatingActionButton: access.canCreate
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.devicesAdd),
              tooltip: 'Add device',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: EmployeeSearchBar(
              hintText: 'Search asset code, serial, model…',
              initialValue: list.query.search,
              onChanged: (String value) {
                ref
                    .read(
                      deviceListControllerProvider(DeviceListKind.inventory)
                          .notifier,
                    )
                    .setSearch(value);
              },
            ),
          ),
          Expanded(
            child: DeviceListView(
              kind: DeviceListKind.inventory,
              emptyTitle: 'No devices match these filters',
              emptySubtitle: 'Try a different search or clear filters.',
              onOpen: (Device device) {
                context.push(AppRoutes.device(device.id));
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final DeviceListState list =
        ref.read(deviceListControllerProvider(DeviceListKind.inventory));
    final DeviceQuery? next = await showDeviceFilterSheet(
      context: context,
      current: list.query,
    );
    if (next == null) {
      return;
    }
    await ref
        .read(deviceListControllerProvider(DeviceListKind.inventory).notifier)
        .applyFilters(next);
  }
}

class MyDeviceScreen extends ConsumerWidget {
  const MyDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceListState list =
        ref.watch(deviceListControllerProvider(DeviceListKind.mine));
    return Scaffold(
      appBar: AppBar(title: const Text('My devices')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: EmployeeSearchBar(
              hintText: 'Search my devices…',
              initialValue: list.query.search,
              onChanged: (String value) {
                ref
                    .read(
                      deviceListControllerProvider(DeviceListKind.mine).notifier,
                    )
                    .setSearch(value);
              },
            ),
          ),
          Expanded(
            child: DeviceListView(
              kind: DeviceListKind.mine,
              emptyTitle: 'No devices assigned to you',
              emptySubtitle: 'Assigned assets will appear here.',
              onOpen: (Device device) {
                context.push(AppRoutes.device(device.id));
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_action_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_employee_picker_controller.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_error_mapper.dart';
import 'package:flutter_base/features/devices/presentation/providers/device_providers.dart';
import 'package:flutter_base/features/devices/presentation/states/device_states.dart';
import 'package:flutter_base/features/devices/presentation/widgets/device_assignment_dialog.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/presentation/states/employee_list_state.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_card.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssignDeviceScreen extends ConsumerStatefulWidget {
  const AssignDeviceScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<AssignDeviceScreen> createState() => _AssignDeviceScreenState();
}

class _AssignDeviceScreenState extends ConsumerState<AssignDeviceScreen> {
  final ScrollController _scroll = ScrollController();
  Employee? _selected;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(deviceEmployeePickerControllerProvider.notifier).loadInitial();
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
      ref.read(deviceEmployeePickerControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _assign() async {
    final Employee? employee = _selected;
    if (employee == null) {
      context.showSnack('Select an employee.');
      return;
    }
    final AssignDeviceBody? body = await showDeviceAssignmentDialog(
      context: context,
      employee: employee,
    );
    if (body == null || !mounted) {
      return;
    }
    final Device? result =
        await ref.read(deviceActionControllerProvider.notifier).assign(
              id: widget.deviceId,
              body: body,
            );
    if (!mounted) {
      return;
    }
    if (result != null) {
      context.showSnack('Device assigned.');
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
    final AsyncValue<Device> deviceAsync =
        ref.watch(deviceDetailProvider(widget.deviceId));
    final EmployeeListState picker =
        ref.watch(deviceEmployeePickerControllerProvider);
    final DeviceActionState action = ref.watch(deviceActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign device')),
      body: deviceAsync.when(
        loading: () => const AppLoader(),
        error: (Object error, _) => AppErrorWidget(
          message: DeviceErrorMapper.message(error),
          onRetry: () =>
              ref.invalidate(deviceDetailProvider(widget.deviceId)),
        ),
        data: (Device device) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Text(
                  'Assign ${device.assetCode}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: EmployeeSearchBar(
                  hintText: 'Search employees',
                  onChanged: (String value) {
                    ref
                        .read(deviceEmployeePickerControllerProvider.notifier)
                        .setSearch(value);
                  },
                ),
              ),
              Expanded(child: _pickerList(picker)),
              SafeArea(
                child: Padding(
                  padding: AppSpacing.screen,
                  child: AppButton(
                    label: _selected == null
                        ? 'Select an employee'
                        : 'Assign to ${_selected!.fullName}',
                    isLoading: action.isAssigning,
                    onPressed: action.isBusy ? null : _assign,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pickerList(EmployeeListState picker) {
    if (picker.isInitialLoading) {
      return const AppLoader(message: 'Loading employees…');
    }
    if (picker.error != null && picker.items.isEmpty) {
      return AppErrorWidget(
        message: picker.error!,
        onRetry: () => ref
            .read(deviceEmployeePickerControllerProvider.notifier)
            .loadInitial(),
      );
    }
    if (picker.isEmpty) {
      return const AppEmptyState(
        title: 'No employees found',
        icon: Icons.person_search_outlined,
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: picker.items.length + (picker.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        if (index >= picker.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final Employee employee = picker.items[index];
        final bool selected = _selected?.id == employee.id;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          child: EmployeeCard(
            employee: employee,
            onTap: () => setState(() => _selected = employee),
          ),
        );
      },
    );
  }
}

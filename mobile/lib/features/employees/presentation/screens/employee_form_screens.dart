import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_error_mapper.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_list_controller.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  bool _saving = false;
  Map<String, String> _fieldErrors = <String, String>{};

  Future<void> _submit(EmployeeWrite write) async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
      _fieldErrors = <String, String>{};
    });
    try {
      final Employee created = await ref.read(createEmployeeProvider)(write);
      ref.read(employeeListControllerProvider.notifier).prependEmployee(created);
      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fieldErrors = EmployeeErrorMapper.fieldErrors(error);
      });
      context.showSnack(EmployeeErrorMapper.message(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Department>> departments =
        ref.watch(departmentsProvider);
    final AsyncValue<List<Position>> positions = ref.watch(positionsProvider);
    final AsyncValue<List<Employee>> directory =
        ref.watch(employeeDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add employee')),
      body: departments.when(
        loading: () => const AppLoader(),
        error: (Object error, _) => AppErrorWidget(
          message: EmployeeErrorMapper.message(error),
          onRetry: () => ref.invalidate(departmentsProvider),
        ),
        data: (List<Department> depts) {
          return SingleChildScrollView(
            padding: AppSpacing.screen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: EmployeeForm(
              departments: depts,
              positions: positions.valueOrNull ?? const <Position>[],
              managers: directory.valueOrNull ?? const <Employee>[],
              submitting: _saving,
              fieldErrors: _fieldErrors,
              submitLabel: 'Create employee',
              onSubmit: _submit,
            ),
          );
        },
      ),
    );
  }
}

class EditEmployeeScreen extends ConsumerStatefulWidget {
  const EditEmployeeScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  ConsumerState<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends ConsumerState<EditEmployeeScreen> {
  bool _saving = false;
  Map<String, String> _fieldErrors = <String, String>{};

  Future<void> _submit(EmployeeWrite write) async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
      _fieldErrors = <String, String>{};
    });
    try {
      final Employee updated = await ref.read(updateEmployeeProvider)(
        widget.employeeId,
        write,
      );
      ref.read(employeeListControllerProvider.notifier).replaceEmployee(updated);
      ref.invalidate(employeeDetailProvider(widget.employeeId));
      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fieldErrors = EmployeeErrorMapper.fieldErrors(error);
      });
      context.showSnack(EmployeeErrorMapper.message(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Employee> detail =
        ref.watch(employeeDetailProvider(widget.employeeId));
    final AsyncValue<List<Department>> departments =
        ref.watch(departmentsProvider);
    final AsyncValue<List<Position>> positions = ref.watch(positionsProvider);
    final AsyncValue<List<Employee>> directory =
        ref.watch(employeeDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit employee')),
      body: detail.when(
        loading: () => const AppLoader(),
        error: (Object error, _) => AppErrorWidget(
          message: EmployeeErrorMapper.message(error),
          onRetry: () =>
              ref.invalidate(employeeDetailProvider(widget.employeeId)),
        ),
        data: (Employee employee) {
          return SingleChildScrollView(
            padding: AppSpacing.screen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: EmployeeForm(
              initial: employee,
              departments: departments.valueOrNull ?? const <Department>[],
              positions: positions.valueOrNull ?? const <Position>[],
              managers: directory.valueOrNull ?? const <Employee>[],
              submitting: _saving,
              fieldErrors: _fieldErrors,
              submitLabel: 'Save changes',
              onSubmit: _submit,
            ),
          );
        },
      ),
    );
  }
}

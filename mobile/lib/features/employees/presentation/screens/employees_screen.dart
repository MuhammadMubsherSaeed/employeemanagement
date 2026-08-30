import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_empty_state.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_base/features/employees/domain/employee_access.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_list_controller.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_base/features/employees/presentation/states/employee_list_state.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_card.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_filter_sheet.dart';
import 'package:flutter_base/features/employees/presentation/widgets/employee_search_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final ScrollController _scroll = ScrollController();
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.microtask(() {
      ref.read(employeeListControllerProvider.notifier).loadInitial();
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
      ref.read(employeeListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final EmployeeListState list = ref.read(employeeListControllerProvider);
    final List<Department> departments =
        await ref.read(departmentsProvider.future);
    final List<Position> positions = await ref.read(positionsProvider.future);
    if (!mounted) {
      return;
    }
    final EmployeeQuery? next = await showEmployeeFilterSheet(
      context: context,
      current: list.query,
      departments: departments,
      positions: positions,
    );
    if (next == null) {
      return;
    }
    ref.read(employeeListControllerProvider.notifier).applyFilters(
          transform: (_) => next,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authControllerProvider);
    final EmployeeAccess access = EmployeeAccess(
      auth is AuthAuthenticated ? auth.user.role : UserRole.unknown,
    );
    final EmployeeListState list = ref.watch(employeeListControllerProvider);
    final int filters = list.query.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: <Widget>[
          IconButton(
            tooltip: _compact ? 'Card view' : 'List view',
            onPressed: () => setState(() => _compact = !_compact),
            icon: Icon(_compact ? Icons.grid_view : Icons.view_list),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            onSelected: (String value) {
              ref
                  .read(employeeListControllerProvider.notifier)
                  .setOrdering(value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'first_name',
                child: Text('Name'),
              ),
              const PopupMenuItem<String>(
                value: 'employee_code',
                child: Text('Employee code'),
              ),
              const PopupMenuItem<String>(
                value: '-joining_date',
                child: Text('Joining date'),
              ),
              const PopupMenuItem<String>(
                value: '-created_at',
                child: Text('Recently added'),
              ),
            ],
          ),
          IconButton(
            tooltip: filters == 0 ? 'Filters' : 'Filters ($filters)',
            onPressed: _openFilters,
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
              tooltip: 'Add employee',
              onPressed: () => context.push(AppRoutes.employeesAdd),
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
              AppSpacing.xs,
            ),
            child: EmployeeSearchBar(
              initialValue: list.query.search,
              onChanged: (String value) {
                ref
                    .read(employeeListControllerProvider.notifier)
                    .setSearch(value);
              },
            ),
          ),
          Expanded(child: _body(list)),
        ],
      ),
    );
  }

  Widget _body(EmployeeListState list) {
    if (list.isInitialLoading) {
      return const AppLoader(message: 'Loading employees…');
    }
    if (list.error != null && list.items.isEmpty) {
      return AppErrorWidget(
        message: list.error!,
        onRetry: () =>
            ref.read(employeeListControllerProvider.notifier).loadInitial(),
      );
    }
    if (list.isEmpty) {
      return AppEmptyState(
        title: list.query.search.isEmpty
            ? 'No employees found.'
            : 'No employees match your search.',
        subtitle: list.query.search.isEmpty
            ? 'Add an employee or adjust filters.'
            : 'Try a different name, code, email, or phone.',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(employeeListControllerProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scroll,
        padding: AppSpacing.screen,
        itemCount: list.items.length + (list.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index >= list.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final Employee employee = list.items[index];
          void open() => context.push(AppRoutes.employee(employee.id));
          if (_compact) {
            return EmployeeListItem(employee: employee, onTap: open);
          }
          return EmployeeCard(employee: employee, onTap: open);
        },
      ),
    );
  }
}


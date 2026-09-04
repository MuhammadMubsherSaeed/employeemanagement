import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_base/features/employees/domain/usecases/employee_usecases.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_list_controller.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_base/features/employees/presentation/states/employee_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';

ProviderContainer _container(FakeEmployeeRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      getEmployeesProvider.overrideWithValue(GetEmployees(repository)),
    ],
  );
}

EmployeePage<Employee> _page({
  required int page,
  required bool hasMore,
  required List<Employee> results,
  int count = 40,
}) {
  return EmployeePage<Employee>(
    results: results,
    count: count,
    next: hasMore ? 'http://example.com/api/v1/employees/?page=${page + 1}' : null,
  );
}

void main() {
  test('first page loads into success state', () async {
    final FakeEmployeeRepository repository = FakeEmployeeRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.loadInitial();

    final EmployeeListState state = container.read(employeeListControllerProvider);
    expect(state.isInitialLoading, isFalse);
    expect(state.items, isNotEmpty);
    expect(state.query.page, 1);
    expect(repository.listCalls, 1);
  });

  test('search updates state, debounces, and resets pagination', () async {
    final FakeEmployeeRepository repository = FakeEmployeeRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.loadInitial();

    controller.setSearch('A');
    controller.setSearch('Ad');
    controller.setSearch('Ada');
    expect(repository.listCalls, 1);

    await Future<void>.delayed(
      EmployeeListController.searchDebounce + const Duration(milliseconds: 50),
    );
    expect(repository.listCalls, 2);
    expect(repository.listQueries.last.search, 'Ada');
    expect(repository.listQueries.last.page, 1);
  });

  test('immediate search and clear reload the list from page 1', () async {
    final FakeEmployeeRepository repository = FakeEmployeeRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.loadInitial();

    await controller.setSearch('Ada', immediate: true);
    expect(container.read(employeeListControllerProvider).query.search, 'Ada');
    await controller.setSearch('', immediate: true);

    expect(repository.listCalls, 3);
    expect(repository.listQueries.last.search, isEmpty);
    expect(repository.listQueries.last.page, 1);
  });

  test('pagination loads the next page once and stops on the last page', () async {
    final FakeEmployeeRepository repository = FakeEmployeeRepository()
      ..delay = const Duration(milliseconds: 20)
      ..pageBuilder = (EmployeeQuery query) {
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <Employee>[sampleEmployee(id: 'a')],
          );
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <Employee>[sampleEmployee(id: 'b', code: 'EMP-002')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.loadInitial();
    expect(container.read(employeeListControllerProvider).hasMore, isTrue);

    final Future<void> first = controller.loadMore();
    final Future<void> second = controller.loadMore();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.listCalls, 2);
    expect(repository.listQueries.last.page, 2);
    expect(container.read(employeeListControllerProvider).items.length, 2);
    expect(container.read(employeeListControllerProvider).hasMore, isFalse);

    await controller.loadMore();
    expect(repository.listCalls, 2);
  });

  test('load-more errors keep the current page so retry does not skip', () async {
    bool failPage2 = true;
    final FakeEmployeeRepository repository = FakeEmployeeRepository()
      ..pageBuilder = (EmployeeQuery query) {
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <Employee>[sampleEmployee(id: 'a')],
          );
        }
        if (failPage2) {
          throw const NetworkException();
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <Employee>[sampleEmployee(id: 'b', code: 'EMP-002')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.loadInitial();

    await controller.loadMore();
    final EmployeeListState failed =
        container.read(employeeListControllerProvider);
    expect(failed.error, isNotNull);
    expect(failed.query.page, 1);
    expect(failed.items.length, 1);

    failPage2 = false;
    await controller.loadMore();
    final EmployeeListState recovered =
        container.read(employeeListControllerProvider);
    expect(recovered.error, isNull);
    expect(recovered.items.length, 2);
    expect(repository.listQueries.last.page, 2);
  });

  test('refresh, search, and filters reset pagination', () async {
    final FakeEmployeeRepository repository = FakeEmployeeRepository()
      ..pageBuilder = (EmployeeQuery query) => _page(
            page: query.page,
            hasMore: query.page == 1,
            results: <Employee>[sampleEmployee(id: 'p${query.page}')],
          );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.loadInitial();
    await controller.loadMore();
    expect(repository.listQueries.last.page, 2);

    await controller.refresh();
    expect(repository.listQueries.last.page, 1);

    await controller.setSearch('code', immediate: true);
    expect(repository.listQueries.last.page, 1);

    await controller.applyFilters(
      transform: (EmployeeQuery current) => current.copyWith(
        departmentId: 'dept-1',
        positionId: 'pos-1',
        status: EmployeeStatus.active,
        employmentType: EmploymentType.contract,
      ),
    );
    expect(repository.listQueries.last.page, 1);
    expect(repository.listQueries.last.departmentId, 'dept-1');
    expect(repository.listQueries.last.positionId, 'pos-1');
    expect(repository.listQueries.last.status, EmployeeStatus.active);
    expect(
      repository.listQueries.last.employmentType,
      EmploymentType.contract,
    );
    expect(repository.listQueries.last.search, 'code');
  });

  test('clearing filters keeps search and reloads', () async {
    final FakeEmployeeRepository repository = FakeEmployeeRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.setSearch('Ada', immediate: true);
    await controller.applyFilters(departmentId: 'dept-1');
    await controller.clearFilters();

    expect(container.read(employeeListControllerProvider).query.search, 'Ada');
    expect(
      container.read(employeeListControllerProvider).query.departmentId,
      isNull,
    );
  });

  test('errors keep existing items and expose a user-facing message', () async {
    final FakeEmployeeRepository repository = FakeEmployeeRepository()
      ..pageBuilder = (EmployeeQuery query) => _page(
            page: 1,
            hasMore: true,
            results: <Employee>[sampleEmployee()],
          );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);
    await controller.loadInitial();

    repository
      ..pageBuilder = null
      ..listError = const NetworkException();
    await controller.loadMore();

    final EmployeeListState state = container.read(employeeListControllerProvider);
    expect(state.items, isNotEmpty);
    expect(state.error, contains('internet'));
  });

  test('create update delete helpers keep list state consistent', () {
    final FakeEmployeeRepository repository = FakeEmployeeRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final EmployeeListController controller =
        container.read(employeeListControllerProvider.notifier);

    final Employee created = sampleEmployee(id: 'new');
    controller.prependEmployee(created);
    expect(container.read(employeeListControllerProvider).items.first.id, 'new');

    controller.replaceEmployee(created.copyWith(firstName: 'Updated'));
    expect(
      container.read(employeeListControllerProvider).items.first.firstName,
      'Updated',
    );

    controller.removeEmployee('new');
    expect(container.read(employeeListControllerProvider).items, isEmpty);
  });
}

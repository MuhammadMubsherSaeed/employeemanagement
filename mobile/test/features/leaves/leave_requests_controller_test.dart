import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_providers.dart';
import 'package:flutter_base/features/leaves/presentation/providers/leave_requests_controller.dart';
import 'package:flutter_base/features/leaves/presentation/states/leave_requests_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';
import '../../helpers/leave_fakes.dart';

ProviderContainer _container(
  FakeLeaveRepository repository, {
  User user = sampleUser,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      leaveRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

LeavePage<LeaveRequest> _page({
  required int page,
  required bool hasMore,
  required List<LeaveRequest> results,
  int count = 40,
}) {
  return LeavePage<LeaveRequest>(
    results: results,
    count: count,
    next: hasMore
        ? 'http://example.com/api/v1/leave/requests/?page=${page + 1}'
        : null,
  );
}

void main() {
  test('initial load, empty, and error states', () async {
    final FakeLeaveRepository empty = FakeLeaveRepository(
      requests: <LeaveRequest>[],
    );
    final ProviderContainer container = _container(empty);
    addTearDown(container.dispose);

    await container
        .read(leaveRequestsControllerProvider(LeaveListKind.all).notifier)
        .loadInitial();
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).isEmpty,
      isTrue,
    );

    empty.listError = const NetworkException();
    empty.requests = <LeaveRequest>[sampleLeaveRequest()];
    await container
        .read(leaveRequestsControllerProvider(LeaveListKind.all).notifier)
        .loadInitial();
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).error,
      contains('internet'),
    );
  });

  test('pagination loads the next page once and stops on the last page',
      () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..delay = const Duration(milliseconds: 20)
      ..pageBuilder = (LeaveRequestQuery query) {
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <LeaveRequest>[sampleLeaveRequest(id: 'a')],
          );
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <LeaveRequest>[sampleLeaveRequest(id: 'b')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      leaveRequestsControllerProvider(LeaveListKind.all).notifier,
    );
    await controller.loadInitial();
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).hasMore,
      isTrue,
    );

    final Future<void> first = controller.loadMore();
    final Future<void> second = controller.loadMore();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.listCalls, 2);
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).items.length,
      2,
    );
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).hasMore,
      isFalse,
    );

    await controller.loadMore();
    expect(repository.listCalls, 2);
  });

  test('refresh and filters reset pagination', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..pageBuilder = (LeaveRequestQuery query) => _page(
            page: query.page,
            hasMore: query.page == 1,
            results: <LeaveRequest>[sampleLeaveRequest(id: 'p${query.page}')],
          );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      leaveRequestsControllerProvider(LeaveListKind.all).notifier,
    );
    await controller.loadInitial();
    await controller.loadMore();
    expect(repository.listQueries.last.page, 2);

    await controller.refresh();
    expect(repository.listQueries.last.page, 1);

    await controller.applyFilters(
      const LeaveRequestQuery(status: LeaveRequestStatus.approved),
    );
    expect(repository.listQueries.last.page, 1);
    expect(
      repository.listQueries.last.status,
      LeaveRequestStatus.approved,
    );
  });

  test('employees cannot query another employee from request filters',
      () async {
    final FakeLeaveRepository repository = FakeLeaveRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    await container
        .read(leaveRequestsControllerProvider(LeaveListKind.all).notifier)
        .applyFilters(const LeaveRequestQuery(employeeId: 'someone-else'));

    expect(repository.listQueries.single.employeeId, isNull);
  });

  test('managers may send an employee filter supported by the API', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository();
    final ProviderContainer container = _container(
      repository,
      user: managerUser,
    );
    addTearDown(container.dispose);

    await container
        .read(leaveRequestsControllerProvider(LeaveListKind.all).notifier)
        .applyFilters(const LeaveRequestQuery(employeeId: 'emp-9'));
    expect(repository.listQueries.single.employeeId, 'emp-9');
  });

  test('load-more errors can be retried without skipping a page', () async {
    int calls = 0;
    final FakeLeaveRepository repository = FakeLeaveRepository()
      ..pageBuilder = (LeaveRequestQuery query) {
        calls += 1;
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <LeaveRequest>[sampleLeaveRequest(id: 'a')],
          );
        }
        if (calls == 2) {
          throw const NetworkException();
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <LeaveRequest>[sampleLeaveRequest(id: 'b')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      leaveRequestsControllerProvider(LeaveListKind.all).notifier,
    );
    await controller.loadInitial();
    await controller.loadMore();
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).error,
      contains('internet'),
    );
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).items.length,
      1,
    );
    await controller.loadMore();
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).items.length,
      2,
    );
    expect(
      container.read(leaveRequestsControllerProvider(LeaveListKind.all)).error,
      isNull,
    );
  });
}

import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_history_controller.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/auth/domain/entities/user.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';
import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';

ProviderContainer _container(
  FakeAttendanceRepository repository, {
  User user = sampleUser,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(() => SeededAuthController(user)),
      getAttendanceHistoryUseCaseProvider.overrideWithValue(
        GetAttendanceHistory(repository),
      ),
    ],
  );
}

AttendancePage<AttendanceRecord> _page({
  required int page,
  required bool hasMore,
  required List<AttendanceRecord> results,
  int count = 40,
}) {
  return AttendancePage<AttendanceRecord>(
    results: results,
    count: count,
    next: hasMore
        ? 'http://example.com/api/v1/attendance/me/?page=${page + 1}'
        : null,
  );
}

void main() {
  test('initial load, empty, and error states', () async {
    final FakeAttendanceRepository empty = FakeAttendanceRepository(
      records: <AttendanceRecord>[],
    );
    final ProviderContainer container = _container(empty);
    addTearDown(container.dispose);

    await container.read(attendanceHistoryControllerProvider.notifier).loadInitial();
    expect(container.read(attendanceHistoryControllerProvider).isEmpty, isTrue);

    empty.myError = const NetworkException();
    empty.records = <AttendanceRecord>[sampleAttendance()];
    await container.read(attendanceHistoryControllerProvider.notifier).loadInitial();
    expect(container.read(attendanceHistoryControllerProvider).error, contains('internet'));
  });

  test('pagination loads the next page once and stops on the last page',
      () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository()
      ..delay = const Duration(milliseconds: 20)
      ..pageBuilder = (AttendanceQuery query) {
        if (query.page == 1) {
          return _page(
            page: 1,
            hasMore: true,
            results: <AttendanceRecord>[sampleAttendance(id: 'a')],
          );
        }
        return _page(
          page: 2,
          hasMore: false,
          results: <AttendanceRecord>[sampleAttendance(id: 'b')],
        );
      };
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(attendanceHistoryControllerProvider.notifier);
    await controller.loadInitial();
    expect(container.read(attendanceHistoryControllerProvider).hasMore, isTrue);

    final Future<void> first = controller.loadMore();
    final Future<void> second = controller.loadMore();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.myCalls, 2);
    expect(container.read(attendanceHistoryControllerProvider).items.length, 2);
    expect(container.read(attendanceHistoryControllerProvider).hasMore, isFalse);

    await controller.loadMore();
    expect(repository.myCalls, 2);
  });

  test('refresh and filters reset pagination', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository()
      ..pageBuilder = (AttendanceQuery query) => _page(
            page: query.page,
            hasMore: query.page == 1,
            results: <AttendanceRecord>[sampleAttendance(id: 'p${query.page}')],
          );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(attendanceHistoryControllerProvider.notifier);
    await controller.loadInitial();
    await controller.loadMore();
    expect(repository.myQueries.last.page, 2);

    await controller.refresh();
    expect(repository.myQueries.last.page, 1);

    await controller.applyFilters(
      const AttendanceQuery(
        startDate: null,
        status: AttendanceStatus.late,
      ).copyWith(startDate: DateTime(2026, 8, 1), endDate: DateTime(2026, 8, 31)),
    );
    expect(repository.myQueries.last.page, 1);
    expect(repository.myQueries.last.status, AttendanceStatus.late);
    expect(repository.myQueries.last.startDate, DateTime(2026, 8, 1));
  });

  test('employees cannot query another employee from history filters',
      () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    await container.read(attendanceHistoryControllerProvider.notifier).applyFilters(
          const AttendanceQuery(employeeId: 'someone-else'),
        );

    expect(repository.historyCalls, 0);
    expect(repository.myQueries.single.employeeId, isNull);
  });

  test('managers use the authorized list endpoint', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository();
    final ProviderContainer container = _container(
      repository,
      user: managerUser,
    );
    addTearDown(container.dispose);

    await container.read(attendanceHistoryControllerProvider.notifier).loadInitial();
    expect(repository.historyCalls, 1);
    expect(repository.myCalls, 0);
  });
}

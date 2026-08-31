import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_calendar_controller.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';

ProviderContainer _container(FakeAttendanceRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      getAttendanceHistoryUseCaseProvider.overrideWithValue(
        GetAttendanceHistory(repository),
      ),
    ],
  );
}

void main() {
  test('loads the selected month as a single date-range request', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository(
      records: <AttendanceRecord>[
        sampleAttendance(date: DateTime(2026, 8, 3), status: AttendanceStatus.late),
      ],
    );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final controller =
        container.read(attendanceCalendarControllerProvider.notifier);

    await controller.goToCurrentMonth();
    // Force August 2026 by previous/next from a known month via load of copied state.
    await controller.previousMonth();

    expect(repository.myCalls, greaterThanOrEqualTo(1));
    final AttendanceQuery last = repository.myQueries.last;
    expect(last.startDate?.day, 1);
    expect(last.endDate?.month, last.startDate?.month);
    expect(last.employeeId, isNull);
    expect(container.read(attendanceCalendarControllerProvider).isLoading, isFalse);
  });

  test('empty month, loading error, and next-month cap', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository(
      records: <AttendanceRecord>[],
    );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final controller =
        container.read(attendanceCalendarControllerProvider.notifier);

    await controller.goToCurrentMonth();
    expect(container.read(attendanceCalendarControllerProvider).records, isEmpty);

    final int calls = repository.myCalls;
    await controller.nextMonth();
    expect(repository.myCalls, calls);

    repository.myError = const NetworkException();
    await controller.previousMonth();
    expect(
      container.read(attendanceCalendarControllerProvider).error,
      contains('internet'),
    );
  });

  test('calendar maps backend statuses by date without inventing absence', () async {
    final DateTime now = DateTime.now();
    final FakeAttendanceRepository repository = FakeAttendanceRepository(
      records: <AttendanceRecord>[
        sampleAttendance(
          id: 'p',
          date: DateTime(now.year, now.month, 2),
          status: AttendanceStatus.present,
        ),
        sampleAttendance(
          id: 'l',
          date: DateTime(now.year, now.month, 3),
          status: AttendanceStatus.late,
        ),
      ],
    );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    await container.read(attendanceCalendarControllerProvider.notifier).load();
    final byDate = container.read(attendanceCalendarControllerProvider).byDate;
    expect(byDate[formatDateParam(DateTime(now.year, now.month, 2))]?.status,
        AttendanceStatus.present);
    expect(byDate[formatDateParam(DateTime(now.year, now.month, 3))]?.status,
        AttendanceStatus.late);
    expect(byDate[formatDateParam(DateTime(now.year, now.month, 4))], isNull);
  });
}

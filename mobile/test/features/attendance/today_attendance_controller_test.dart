import 'dart:async';

import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_history_controller.dart';
import 'package:flutter_base/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:flutter_base/features/attendance/presentation/providers/today_attendance_controller.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';
import '../../helpers/auth_fakes.dart';
import '../../helpers/employee_fakes.dart';

ProviderContainer _container(FakeAttendanceRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      authControllerProvider.overrideWith(
        () => SeededAuthController(sampleUser),
      ),
      getTodayAttendanceProvider.overrideWithValue(
        GetTodayAttendance(repository),
      ),
      checkInUseCaseProvider.overrideWithValue(CheckIn(repository)),
      checkOutUseCaseProvider.overrideWithValue(CheckOut(repository)),
      getAttendanceHistoryUseCaseProvider.overrideWithValue(
        GetAttendanceHistory(repository),
      ),
      getAttendanceSummaryUseCaseProvider.overrideWithValue(
        GetAttendanceSummary(repository),
      ),
    ],
  );
}

void main() {
  test('loads empty, checked-in, and error states from the backend', () async {
    final FakeAttendanceRepository empty = FakeAttendanceRepository(today: null);
    final ProviderContainer container = _container(empty);
    addTearDown(container.dispose);

    await container.read(todayAttendanceProvider.notifier).load();
    expect(container.read(todayAttendanceProvider).record, isNull);
    expect(container.read(todayAttendanceProvider).punchState, PunchState.none);

    empty.todayRecord = sampleAttendance(checkOut: null, totalMinutes: null);
    await container.read(todayAttendanceProvider.notifier).load();
    expect(
      container.read(todayAttendanceProvider).punchState,
      PunchState.checkedIn,
    );

    empty.todayError = const NetworkException();
    await container.read(todayAttendanceProvider.notifier).load();
    expect(container.read(todayAttendanceProvider).error, contains('internet'));
  });

  test('check-in succeeds, blocks double-tap, and refreshes related data',
      () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository(
      today: null,
    )..delay = const Duration(milliseconds: 30);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final TodayAttendanceController controller =
        container.read(todayAttendanceProvider.notifier);
    await controller.load();

    final Future<bool> first = controller.checkIn();
    expect(container.read(todayAttendanceProvider).isCheckingIn, isTrue);
    final Future<bool> second = controller.checkIn();
    expect(await second, isFalse);
    expect(await first, isTrue);
    expect(repository.checkInCalls, 1);
    expect(
      container.read(todayAttendanceProvider).punchState,
      PunchState.checkedIn,
    );
    expect(container.read(todayAttendanceProvider).isCheckingIn, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repository.myCalls, greaterThan(0));
  });

  test('check-in surfaces API errors including unauthorized', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository()
      ..checkInError = const UnauthorizedException();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    final bool ok =
        await container.read(todayAttendanceProvider.notifier).checkIn();
    expect(ok, isFalse);
    expect(
      container.read(todayAttendanceProvider).actionError,
      'Please sign in again.',
    );
  });

  test('check-out succeeds and duplicate taps are ignored', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository(
      today: sampleAttendance(checkOut: null, totalMinutes: null),
    )..delay = const Duration(milliseconds: 20);
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final TodayAttendanceController controller =
        container.read(todayAttendanceProvider.notifier);
    await controller.load();

    final Future<bool> first = controller.checkOut();
    final Future<bool> second = controller.checkOut();
    expect(await second, isFalse);
    expect(await first, isTrue);
    expect(repository.checkOutCalls, 1);
    expect(
      container.read(todayAttendanceProvider).punchState,
      PunchState.checkedOut,
    );
  });

  test('check-out without check-in keeps the backend message', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository()
      ..checkOutError = const ValidationException(
        'You must check in before checking out.',
      );
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    final bool ok =
        await container.read(todayAttendanceProvider.notifier).checkOut();
    expect(ok, isFalse);
    expect(
      container.read(todayAttendanceProvider).actionError,
      'You must check in before checking out.',
    );
  });

  test('summary provider returns monthly backend values', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final AttendanceSummaryQuery query = AttendanceSummaryQuery(
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
    );

    final AttendanceSummary summary =
        await container.read(attendanceSummaryProvider(query).future);
    expect(summary.presentDays, 18);
    expect(summary.totalWorkingMinutes, 8640);
    expect(repository.summaryQueries.single.startDate, DateTime(2026, 8, 1));
    expect(repository.summaryQueries.single.endDate, DateTime(2026, 8, 31));
  });

  test('history controller after check-in uses employee self endpoint',
      () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);

    await container.read(todayAttendanceProvider.notifier).checkIn();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(attendanceHistoryControllerProvider).items, isNotEmpty);
    expect(repository.myCalls, greaterThan(0));
    expect(repository.historyCalls, 0);
  });

  test('a stale today-attendance response does not overwrite a newer refresh',
      () async {
    final Completer<AttendanceRecord?> hold = Completer<AttendanceRecord?>();
    final FakeAttendanceRepository repository = FakeAttendanceRepository(
      today: null,
    )..todayHold = hold;
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final TodayAttendanceController controller =
        container.read(todayAttendanceProvider.notifier);

    final Future<void> first = controller.load();
    repository.todayHold = null;
    repository.todayRecord = sampleAttendance(checkOut: null, totalMinutes: null);
    await controller.refresh();
    expect(
      container.read(todayAttendanceProvider).punchState,
      PunchState.checkedIn,
    );

    hold.complete(null);
    await first;
    expect(
      container.read(todayAttendanceProvider).punchState,
      PunchState.checkedIn,
    );
    expect(container.read(todayAttendanceProvider).record, isNotNull);
  });
}

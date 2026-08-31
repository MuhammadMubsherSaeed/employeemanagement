import 'package:flutter_base/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';

void main() {
  test('repository forwards list, me, detail, summary, and punches', () async {
    final FakeAttendanceRemote remote = FakeAttendanceRemote();
    final AttendanceRepositoryImpl repository = AttendanceRepositoryImpl(remote);
    const AttendanceQuery query = AttendanceQuery(page: 1);

    expect((await repository.getMyAttendance(query)).results, isNotEmpty);
    expect(remote.lastQuery, query);
    expect(remote.myCalls, 1);

    expect((await repository.getAttendanceHistory(query)).count, 1);
    expect(remote.historyCalls, 1);

    expect((await repository.getAttendanceDetails('att-9')).id, 'att-9');
    expect(remote.lastId, 'att-9');

    expect(
      (await repository.getAttendanceSummary(
        AttendanceSummaryQuery(
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
        ),
      )).presentDays,
      18,
    );

    await repository.checkIn();
    expect(remote.checkInCalls, 1);
    expect(remote.lastBody, const CheckInOutBody());

    await repository.checkOut();
    expect(remote.checkOutCalls, 1);
  });

  test('getTodayAttendance uses /me/ for the local calendar day', () async {
    final FakeAttendanceRemote remote = FakeAttendanceRemote(
      page: AttendancePage<AttendanceRecord>(
        results: <AttendanceRecord>[sampleAttendance(id: 'today')],
        count: 1,
      ),
    );
    final AttendanceRepositoryImpl repository = AttendanceRepositoryImpl(remote);

    final AttendanceRecord? today = await repository.getTodayAttendance(
      now: DateTime(2026, 8, 31, 15),
    );

    expect(today?.id, 'today');
    expect(remote.myCalls, 1);
    expect(remote.lastQuery?.startDate, DateTime(2026, 8, 31));
    expect(remote.lastQuery?.endDate, DateTime(2026, 8, 31));
  });

  test('getTodayAttendance returns null when the page is empty', () async {
    final FakeAttendanceRemote remote = FakeAttendanceRemote(
      page: const AttendancePage<AttendanceRecord>(
        results: <AttendanceRecord>[],
        count: 0,
      ),
    );
    final AttendanceRepositoryImpl repository = AttendanceRepositoryImpl(remote);
    expect(await repository.getTodayAttendance(now: DateTime(2026, 8, 31)), isNull);
  });
}

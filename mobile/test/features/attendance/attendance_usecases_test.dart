import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_base/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';

void main() {
  test('today, details, summary, and punch use cases delegate', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository(
      today: sampleAttendance(checkOut: null),
    );

    expect((await GetTodayAttendance(repository)())?.id, 'att-1');
    expect((await GetAttendanceDetails(repository)('att-1')).id, 'att-1');
    expect(
      (await GetAttendanceSummary(repository)(
        AttendanceSummaryQuery(
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
        ),
      )).presentDays,
      18,
    );
    expect((await CheckIn(repository)()).punchState, PunchState.checkedIn);
    expect((await CheckOut(repository)()).punchState, PunchState.checkedOut);
  });

  test('history for employees uses /me/ and drops employee filters', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository();
    await GetAttendanceHistory(repository)(
      const AttendanceQuery(employeeId: 'someone-else', departmentId: 'dept-1'),
      selfOnly: true,
    );

    expect(repository.myCalls, 1);
    expect(repository.historyCalls, 0);
    expect(repository.myQueries.single.employeeId, isNull);
    expect(repository.myQueries.single.departmentId, isNull);
  });

  test('history for managers uses the authorized list endpoint', () async {
    final FakeAttendanceRepository repository = FakeAttendanceRepository();
    await GetAttendanceHistory(repository)(
      const AttendanceQuery(status: AttendanceStatus.late),
      selfOnly: false,
    );

    expect(repository.historyCalls, 1);
    expect(repository.myCalls, 0);
    expect(repository.historyQueries.single.status, AttendanceStatus.late);
  });
}

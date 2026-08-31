import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/usecases/leave_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/leave_fakes.dart';

void main() {
  test('use cases delegate to the repository', () async {
    final FakeLeaveRepository repository = FakeLeaveRepository();

    expect((await GetLeaveTypes(repository)()).results, isNotEmpty);
    expect((await GetLeaveTypes(repository)(activeOnly: true)).results, isNotEmpty);
    expect((await GetLeaveBalances(repository)()).results.single.remainingDays, 12);
    expect(
      (await GetLeaveRequests(repository)(const LeaveRequestQuery())).count,
      1,
    );
    expect((await GetLeaveRequestDetails(repository)('req-1')).id, 'req-1');
    expect(
      (await CreateLeaveRequest(repository)(
        CreateLeaveRequestBody(
          leaveTypeId: 'type-1',
          startDate: DateTime(2026, 8, 15),
          endDate: DateTime(2026, 8, 18),
        ),
      )).id,
      'req-new',
    );
    expect((await ApproveLeaveRequest(repository)('req-1')).isApproved, isTrue);
    expect(
      (await RejectLeaveRequest(repository)(
        id: 'req-1',
        rejectionReason: 'Coverage',
      )).status,
      LeaveRequestStatus.rejected,
    );
    expect(
      (await CancelLeaveRequest(repository)('req-1')).status,
      LeaveRequestStatus.cancelled,
    );
  });
}

import 'package:flutter_base/features/leaves/data/repositories/leave_repository_impl.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/leave_fakes.dart';

void main() {
  test('repository forwards types, balances, requests, and actions', () async {
    final FakeLeaveRemote remote = FakeLeaveRemote();
    final LeaveRepositoryImpl repository = LeaveRepositoryImpl(remote);
    const LeaveRequestQuery query = LeaveRequestQuery(page: 1);

    expect((await repository.getLeaveTypes(const LeaveTypeQuery())).results, isNotEmpty);
    expect((await repository.getLeaveBalances(const LeaveBalanceQuery())).results.single.remainingDays, 12);
    expect((await repository.getLeaveRequests(query)).count, 1);
    expect(remote.lastRequestQuery, query);
    expect((await repository.getLeaveRequestDetails('req-9')).id, 'req-9');

    final LeaveRequest created = await repository.createLeaveRequest(
      CreateLeaveRequestBody(
        leaveTypeId: 'type-1',
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 18),
      ),
    );
    expect(created.id, 'req-new');
    expect(remote.lastCreate?.leaveTypeId, 'type-1');

    expect((await repository.approveLeaveRequest('req-1')).isApproved, isTrue);
    expect(
      (await repository.rejectLeaveRequest(
        id: 'req-1',
        rejectionReason: 'No coverage',
      )).rejectionReason,
      'No coverage',
    );
    expect(
      (await repository.cancelLeaveRequest('req-1')).status.name,
      'cancelled',
    );
  });
}

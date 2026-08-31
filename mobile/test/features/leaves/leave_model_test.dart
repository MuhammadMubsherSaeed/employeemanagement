import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_base/features/leaves/domain/services/leave_attachment_opener.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/leave_fakes.dart';

void main() {
  test('parses leave type snake_case JSON', () {
    final LeaveType type = LeaveType.fromJson(sampleLeaveTypeJson());
    expect(type.id, 'type-1');
    expect(type.daysAllowed, 15);
    expect(type.isPaid, isTrue);
    expect(type.carryForward, isFalse);
    expect(type.status, LeaveTypeStatus.active);
  });

  test('parses leave balance without client-side remaining calculation', () {
    final LeaveBalance balance = LeaveBalance.fromJson(
      sampleLeaveBalanceJson(remainingDays: 9, usedDays: 6, allocatedDays: 15),
    );
    expect(balance.remainingDays, 9);
    expect(balance.usedDays, 6);
    expect(balance.allocatedDays, 15);
    expect(balance.leaveType?.name, 'Annual Leave');
    expect(balance.employee?.fullName, 'Ada Lovelace');
  });

  test('parses request list and detail payloads', () {
    final LeaveRequest list = LeaveRequest.fromJson(sampleLeaveRequestJson());
    expect(list.reason, isEmpty);
    expect(list.attachment, isNull);
    expect(list.status, LeaveRequestStatus.pending);

    final LeaveRequest detail = LeaveRequest.fromJson(
      sampleLeaveRequestJson(
        status: 'APPROVED',
        detail: true,
        attachment: 'https://example.com/media/leave/a.pdf',
      ),
    );
    expect(detail.reason, 'Family event');
    expect(detail.attachment, contains('a.pdf'));
    expect(detail.approvedBy, 11);
    expect(detail.status, LeaveRequestStatus.approved);
  });

  test('maps known statuses and keeps unknown values safe', () {
    expect(LeaveRequestStatus.fromApi('PENDING'), LeaveRequestStatus.pending);
    expect(LeaveRequestStatus.fromApi('CANCELLED'), LeaveRequestStatus.cancelled);
    expect(LeaveRequestStatus.fromApi('FUTURE_STATUS'), LeaveRequestStatus.unknown);
    expect(LeaveRequestStatus.fromApi(null), LeaveRequestStatus.unknown);
    expect(LeaveTypeStatus.fromApi('INACTIVE'), LeaveTypeStatus.inactive);
    expect(LeaveTypeStatus.fromApi('NEW'), LeaveTypeStatus.unknown);
  });

  test('query parameters match the Django leave filter contract', () {
    final LeaveRequestQuery query = LeaveRequestQuery(
      status: LeaveRequestStatus.pending,
      leaveTypeId: 'type-1',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      employeeId: 'emp-9',
      page: 2,
    );
    expect(
      query.toQueryParameters(),
      <String, dynamic>{
        'status': 'PENDING',
        'leave_type': 'type-1',
        'start_date': '2026-08-01',
        'end_date': '2026-08-31',
        'employee': 'emp-9',
        'ordering': '-start_date',
        'page': 2,
        'page_size': 20,
      },
    );
  });

  test('create body never sends company, employee, status, or total_days', () {
    final CreateLeaveRequestBody body = CreateLeaveRequestBody(
      leaveTypeId: 'type-1',
      startDate: DateTime(2026, 8, 15),
      endDate: DateTime(2026, 8, 18),
      reason: 'Family event',
    );
    expect(body.toJson().containsKey('company'), isFalse);
    expect(body.toJson().containsKey('employee'), isFalse);
    expect(body.toJson().containsKey('status'), isFalse);
    expect(body.toJson().containsKey('total_days'), isFalse);
    expect(body.toJson()['leave_type'], 'type-1');
  });

  test('resolves relative attachment URLs against the API origin', () {
    expect(
      resolveLeaveAttachmentUrl(
        '/media/leave/a.pdf',
        'http://example.com/api/v1/',
      ),
      'http://example.com/media/leave/a.pdf',
    );
    expect(
      resolveLeaveAttachmentUrl(
        'https://cdn.example.com/a.pdf',
        'http://example.com/api/v1/',
      ),
      'https://cdn.example.com/a.pdf',
    );
    expect(resolveLeaveAttachmentUrl('', 'http://example.com/api/v1/'), isNull);
  });
}

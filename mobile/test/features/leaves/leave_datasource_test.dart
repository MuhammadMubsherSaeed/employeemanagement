import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/leaves/data/datasources/leave_remote_datasource.dart';
import 'package:flutter_base/features/leaves/data/leave_endpoints.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_enums.dart';
import 'package:flutter_base/features/leaves/domain/entities/leave_query.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/leave_fakes.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.onFetch);

  final ResponseBody Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

LeaveRemoteDataSourceImpl _source(_Adapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://example.com/api/v1/'));
  dio.httpClientAdapter = adapter;
  final ApiClient client = ApiClient(
    config: const AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://example.com/api/v1/',
      enableVerboseLogging: false,
    ),
    storage: const SecureStorageService(FlutterSecureStorage()),
    dio: dio,
  );
  return LeaveRemoteDataSourceImpl(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('parses paginated leave requests and query params', () async {
    RequestOptions? captured;
    final LeaveRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'message': 'ok',
          'data': <String, dynamic>{
            'count': 1,
            'next': 'http://example.com/api/v1/leave/requests/?page=2',
            'previous': null,
            'results': <Map<String, dynamic>>[sampleLeaveRequestJson()],
          },
        });
      }),
    );

    final LeavePage<LeaveRequest> page = await source.getLeaveRequests(
      LeaveRequestQuery(
        status: LeaveRequestStatus.pending,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      ),
    );

    expect(captured?.path, LeaveEndpoints.requests);
    expect(captured?.queryParameters['status'], 'PENDING');
    expect(captured?.queryParameters['start_date'], '2026-08-01');
    expect(page.results.single.status, LeaveRequestStatus.pending);
    expect(page.hasMore, isTrue);
  });

  test('create posts JSON without an attachment and multipart with one', () async {
    Object? lastBody;
    String? lastPath;
    final LeaveRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        lastBody = options.data;
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleLeaveRequestJson(detail: true),
        });
      }),
    );

    await source.createLeaveRequest(
      CreateLeaveRequestBody(
        leaveTypeId: 'type-1',
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 18),
        reason: 'Family event',
      ),
    );
    expect(lastPath, LeaveEndpoints.requests);
    expect(lastBody, isA<Map<String, dynamic>>());
    expect((lastBody as Map<String, dynamic>)['leave_type'], 'type-1');

    final File temp = File(
      '${Directory.systemTemp.path}/leave_attach_test_${DateTime.now().millisecondsSinceEpoch}.pdf',
    )..writeAsStringSync('pdf');
    await source.createLeaveRequest(
      CreateLeaveRequestBody(
        leaveTypeId: 'type-1',
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 18),
        reason: 'Family event',
        attachment: LeaveAttachmentFile(
          path: temp.path,
          name: 'leave_attach_test.pdf',
          size: 3,
        ),
      ),
    );
    expect(lastBody, isA<FormData>());
    try {
      temp.deleteSync();
    } on FileSystemException {
      // Windows may still hold the multipart handle; ignore.
    }
  });

  test('approve, reject, and cancel post to action endpoints', () async {
    String? lastPath;
    Object? lastBody;
    final LeaveRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        lastBody = options.data;
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleLeaveRequestJson(detail: true, status: 'APPROVED'),
        });
      }),
    );

    await source.approveLeaveRequest('req-1');
    expect(lastPath, LeaveEndpoints.approve('req-1'));

    await source.rejectLeaveRequest(
      id: 'req-1',
      rejectionReason: 'Coverage needed',
    );
    expect(lastPath, LeaveEndpoints.reject('req-1'));
    expect(
      (lastBody as Map<String, dynamic>)['rejection_reason'],
      'Coverage needed',
    );

    await source.cancelLeaveRequest('req-1');
    expect(lastPath, LeaveEndpoints.cancel('req-1'));
  });

  test('allocates only allocated_days on balance patch', () async {
    Object? lastBody;
    final LeaveRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastBody = options.data;
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleLeaveBalanceJson(allocatedDays: 20, remainingDays: 17),
        });
      }),
    );

    final LeaveBalance balance = await source.allocateLeaveBalance(
      id: 'bal-1',
      allocatedDays: 20,
    );
    expect(lastBody, <String, dynamic>{'allocated_days': 20});
    expect((lastBody as Map<String, dynamic>).containsKey('used_days'), isFalse);
    expect(balance.allocatedDays, 20);
    expect(balance.remainingDays, 17);
  });
}

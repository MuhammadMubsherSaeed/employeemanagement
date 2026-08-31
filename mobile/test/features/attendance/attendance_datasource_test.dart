import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/attendance/data/attendance_endpoints.dart';
import 'package:flutter_base/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_enums.dart';
import 'package:flutter_base/features/attendance/domain/entities/attendance_query.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/attendance_fakes.dart';

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

AttendanceRemoteDataSourceImpl _source(_Adapter adapter) {
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
  return AttendanceRemoteDataSourceImpl(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('parses paginated /me/ attendance and query params', () async {
    RequestOptions? captured;
    final AttendanceRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'message': 'ok',
          'data': <String, dynamic>{
            'count': 1,
            'next': 'http://example.com/api/v1/attendance/me/?page=2',
            'previous': null,
            'results': <Map<String, dynamic>>[sampleAttendanceJson()],
          },
        });
      }),
    );

    final AttendancePage<AttendanceRecord> page = await source.getMyAttendance(
      AttendanceQuery(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
        status: AttendanceStatus.present,
      ),
    );

    expect(captured?.path, AttendanceEndpoints.me);
    expect(captured?.queryParameters['start_date'], '2026-08-01');
    expect(captured?.queryParameters['end_date'], '2026-08-31');
    expect(captured?.queryParameters['status'], 'PRESENT');
    expect(page.results.single.status, AttendanceStatus.present);
    expect(page.hasMore, isTrue);
  });

  test('check-in and check-out post to the existing endpoints', () async {
    String? lastPath;
    Object? lastBody;
    final AttendanceRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        lastBody = options.data;
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleAttendanceJson(checkOut: null, totalMinutes: 0),
        });
      }),
    );

    await source.checkIn(const CheckInOutBody());
    expect(lastPath, AttendanceEndpoints.checkIn);
    expect(lastBody, isEmpty);

    await source.checkOut(const CheckInOutBody());
    expect(lastPath, AttendanceEndpoints.checkOut);
  });

  test('detail and summary parse backend envelopes', () async {
    String? lastPath;
    final AttendanceRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        if (options.path == AttendanceEndpoints.summary) {
          return _json(200, <String, dynamic>{
            'success': true,
            'data': sampleSummaryJson(),
          });
        }
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleAttendanceJson(sensitive: true),
        });
      }),
    );

    final AttendanceRecord detail = await source.getAttendanceById('att-9');
    expect(lastPath, AttendanceEndpoints.detail('att-9'));
    expect(detail.checkInIp, '203.0.113.10');

    final AttendanceSummary summary = await source.getAttendanceSummary(
      AttendanceSummaryQuery(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      ),
    );
    expect(lastPath, AttendanceEndpoints.summary);
    expect(summary.presentDays, 18);
  });
}

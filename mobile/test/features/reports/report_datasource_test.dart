import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:flutter_base/features/reports/data/report_endpoints.dart';
import 'package:flutter_base/features/reports/data/repositories/report_repository_impl.dart';
import 'package:flutter_base/features/reports/domain/entities/report_export.dart';
import 'package:flutter_base/features/reports/domain/entities/report_kind.dart';
import 'package:flutter_base/features/reports/domain/entities/report_query.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/report_fakes.dart';

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

ResponseBody _file({
  required List<int> bytes,
  required String contentType,
  String? filename,
}) {
  return ResponseBody.fromBytes(
    bytes,
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[contentType],
      if (filename != null)
        'content-disposition': <String>['attachment; filename="$filename"'],
    },
  );
}

ReportRemoteDataSourceImpl _source(_Adapter adapter) {
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
  return ReportRemoteDataSourceImpl(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('list requests use report paths, filters, and pagination', () async {
    RequestOptions? last;
    final ReportRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        last = options;
        return _json(
          200,
          reportListEnvelope(<Map<String, dynamic>>[sampleAttendanceReportJson()]),
        );
      }),
    );
    final ReportQuery query = ReportQuery(
      kind: ReportKind.attendance,
      dateFrom: DateTime(2026, 9, 1),
      dateTo: DateTime(2026, 9, 1),
      employeeId: 'emp-1',
      departmentId: 'dept-1',
      status: 'LATE',
      search: 'Ada',
      page: 2,
      pageSize: 20,
    );

    final page = await source.getAttendanceReport(query);
    expect(last?.path, ReportEndpoints.attendance);
    expect(last?.queryParameters['date_from'], '2026-09-01');
    expect(last?.queryParameters['employee'], 'emp-1');
    expect(last?.queryParameters['page'], 2);
    expect(last?.queryParameters.containsKey('company_id'), isFalse);
    expect(page.results.single.employee.employeeCode, 'EMP-001');

    await source.getLeaveReport(const ReportQuery(kind: ReportKind.leaves));
    expect(last?.path, ReportEndpoints.leaves);
    await source.getEmployeeReport(const ReportQuery(kind: ReportKind.employees));
    expect(last?.path, ReportEndpoints.employees);
    await source.getDeviceReport(const ReportQuery(kind: ReportKind.devices));
    expect(last?.path, ReportEndpoints.devices);
  });

  test('repository forwards list and export calls', () async {
    RequestOptions? last;
    final ReportRepositoryImpl repository = ReportRepositoryImpl(
      _source(
        _Adapter((RequestOptions options) {
          last = options;
          if (options.path.contains('export')) {
            return _file(
              bytes: <int>[1, 2, 3],
              contentType: 'text/csv',
              filename: 'attendance-report-2026-09-01.csv',
            );
          }
          return _json(
            200,
            reportListEnvelope(<Map<String, dynamic>>[sampleAttendanceReportJson()]),
          );
        }),
      ),
    );

    await repository.getAttendanceReport(
      const ReportQuery(kind: ReportKind.attendance),
    );
    final ReportExportFile file = await repository.exportAttendanceReport(
      const ReportQuery(kind: ReportKind.attendance, search: 'Ada'),
      ReportExportFormat.csv,
    );
    expect(last?.path, ReportEndpoints.attendanceExport);
    expect(last?.queryParameters['format'], 'csv');
    expect(last?.queryParameters['search'], 'Ada');
    expect(last?.queryParameters.containsKey('page'), isFalse);
    expect(file.filename, 'attendance-report-2026-09-01.csv');
  });

  test('exports csv, xlsx, and pdf with filename fallback', () async {
    final ReportRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        final String format = options.queryParameters['format'] as String;
        if (format == 'csv') {
          return _file(
            bytes: <int>[9, 9],
            contentType: 'text/csv',
            filename: 'leave-report-2026-09-01.csv',
          );
        }
        if (format == 'xlsx') {
          return _file(
            bytes: <int>[8, 8],
            contentType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
        }
        return _file(bytes: <int>[7, 7], contentType: 'application/pdf');
      }),
    );

    final ReportExportFile csv = await source.exportLeaveReport(
      const ReportQuery(kind: ReportKind.leaves),
      ReportExportFormat.csv,
    );
    expect(csv.filename, 'leave-report-2026-09-01.csv');

    final ReportExportFile xlsx = await source.exportEmployeeReport(
      const ReportQuery(kind: ReportKind.employees),
      ReportExportFormat.xlsx,
    );
    expect(xlsx.filename, contains('employee-report-'));
    expect(xlsx.filename, endsWith('.xlsx'));

    final ReportExportFile pdf = await source.exportDeviceReport(
      const ReportQuery(kind: ReportKind.devices),
      ReportExportFormat.pdf,
    );
    expect(pdf.mimeType, 'application/pdf');
  });

  test('maps unauthorized, forbidden, and invalid file responses', () async {
    Future<void> expectStatus(int status, Matcher matcher) async {
      final ReportRemoteDataSourceImpl source = _source(
        _Adapter(
          (_) => _json(status, <String, dynamic>{
            'success': false,
            'message': 'no',
          }),
        ),
      );
      expect(
        source.getAttendanceReport(
          const ReportQuery(kind: ReportKind.attendance),
        ),
        throwsA(matcher),
      );
    }

    await expectStatus(401, isA<UnauthorizedException>());
    await expectStatus(403, isA<ForbiddenException>());
    await expectStatus(404, isA<NotFoundException>());
    await expectStatus(500, isA<ServerException>());

    final ReportRemoteDataSourceImpl invalid = _source(
      _Adapter(
        (_) => _file(
          bytes: utf8.encode('{"success":false}'),
          contentType: 'application/json',
        ),
      ),
    );
    expect(
      invalid.exportAttendanceReport(
        const ReportQuery(kind: ReportKind.attendance),
        ReportExportFormat.csv,
      ),
      throwsA(isA<UnknownException>()),
    );
  });
}

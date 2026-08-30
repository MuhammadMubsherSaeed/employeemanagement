import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/employees/data/datasources/employee_remote_datasource.dart';
import 'package:flutter_base/features/employees/data/employee_endpoints.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/employee_fakes.dart';

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

EmployeeRemoteDataSourceImpl _source(_Adapter adapter) {
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
  return EmployeeRemoteDataSourceImpl(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('parses paginated employee envelope and query params', () async {
    RequestOptions? captured;
    final EmployeeRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'message': 'ok',
          'data': <String, dynamic>{
            'count': 1,
            'next': 'http://example.com/api/v1/employees/?page=2',
            'previous': null,
            'results': <Map<String, dynamic>>[sampleEmployeeJson()],
          },
        });
      }),
    );

    final EmployeePage<Employee> page = await source.getEmployees(
      const EmployeeQuery(search: 'Ada', page: 1),
    );

    expect(captured?.path, EmployeeEndpoints.employees);
    expect(captured?.queryParameters['search'], 'Ada');
    expect(page.results.single.firstName, 'Ada');
    expect(page.hasMore, isTrue);
    expect(page.count, 1);
  });

  test('parses detail, me, create, and department list envelopes', () async {
    String? lastPath;
    String? lastMethod;
    final EmployeeRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        lastMethod = options.method;
        if (options.path == EmployeeEndpoints.departments) {
          return _json(200, <String, dynamic>{
            'success': true,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'dept-1',
                'name': 'Engineering',
                'status': 'ACTIVE',
              },
            ],
          });
        }
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleEmployeeJson(detail: true),
        });
      }),
    );

    expect((await source.getEmployeeById('abc')).phone, '5550100');
    expect(lastPath, EmployeeEndpoints.employee('abc'));

    expect((await source.getMyEmployeeProfile()).employeeCode, 'EMP-001');
    expect(lastPath, EmployeeEndpoints.me);

    expect(
      (await source.createEmployee(
        const EmployeeWrite(
          employeeCode: 'EMP-002',
          firstName: 'Alan',
          lastName: 'Turing',
          employmentType: EmploymentType.fullTime,
          status: EmployeeStatus.active,
        ),
      )).firstName,
      'Ada',
    );
    expect(lastMethod, 'POST');

    expect((await source.getDepartments()).single.name, 'Engineering');
    expect(lastPath, EmployeeEndpoints.departments);
  });
}

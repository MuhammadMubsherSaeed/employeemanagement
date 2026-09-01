import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/dashboard/data/dashboard_endpoints.dart';
import 'package:flutter_base/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:flutter_base/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dashboard_fakes.dart';

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

DashboardRemoteDataSourceImpl _source(_Adapter adapter) {
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
  return DashboardRemoteDataSourceImpl(client);
}

Map<String, dynamic> _envelope(Map<String, dynamic> data) {
  return <String, dynamic>{
    'success': true,
    'message': 'ok',
    'data': data,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('loads admin, manager, and employee dashboards without company_id',
      () async {
    RequestOptions? last;
    final DashboardRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        last = options;
        if (options.path == DashboardEndpoints.admin) {
          return _json(200, _envelope(sampleAdminDashboardJson()));
        }
        if (options.path == DashboardEndpoints.manager) {
          return _json(200, _envelope(sampleManagerDashboardJson()));
        }
        return _json(200, _envelope(sampleEmployeeDashboardJson()));
      }),
    );

    final AdminDashboard admin = await source.getAdminDashboard();
    expect(last?.path, DashboardEndpoints.admin);
    expect(last?.queryParameters.containsKey('company_id'), isFalse);
    expect(admin.totalEmployees, 12);

    final ManagerDashboard manager = await source.getManagerDashboard();
    expect(last?.path, DashboardEndpoints.manager);
    expect(last?.queryParameters.containsKey('company_id'), isFalse);
    expect(manager.teamSize, 6);

    final EmployeeDashboard employee = await source.getEmployeeDashboard();
    expect(last?.path, DashboardEndpoints.employee);
    expect(last?.queryParameters.containsKey('employee_id'), isFalse);
    expect(employee.workingMinutes, 452);
    expect(employee.notificationsCount, 3);
  });

  test('maps unauthorized, forbidden, not found, and server errors', () async {
    Future<void> expectStatus(int status, Type type) async {
      final DashboardRemoteDataSourceImpl source = _source(
        _Adapter(
          (_) => _json(status, <String, dynamic>{
            'success': false,
            'message': 'no',
          }),
        ),
      );
      expect(
        source.getAdminDashboard(),
        throwsA(isA<AppException>().having((AppException e) => e.runtimeType, 'type', type)),
      );
    }

    await expectStatus(401, UnauthorizedException);
    await expectStatus(403, ForbiddenException);
    await expectStatus(404, NotFoundException);
    await expectStatus(500, ServerException);
  });

  test('maps timeout and network failures', () async {
    final DashboardRemoteDataSourceImpl timeout = _source(
      _Adapter((RequestOptions options) {
        throw DioError(
          requestOptions: options,
          type: DioErrorType.connectTimeout,
        );
      }),
    );
    expect(timeout.getManagerDashboard(), throwsA(isA<TimeoutException>()));

    final DashboardRemoteDataSourceImpl network = _source(
      _Adapter((RequestOptions options) {
        throw DioError(
          requestOptions: options,
          type: DioErrorType.other,
        );
      }),
    );
    expect(network.getEmployeeDashboard(), throwsA(isA<NetworkException>()));
  });
}

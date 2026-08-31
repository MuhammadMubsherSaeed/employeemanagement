import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:flutter_base/features/devices/data/device_endpoints.dart';
import 'package:flutter_base/features/devices/domain/entities/device.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/device_fakes.dart';

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

DeviceRemoteDataSourceImpl _source(_Adapter adapter) {
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
  return DeviceRemoteDataSourceImpl(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('parses paginated devices and query params', () async {
    RequestOptions? captured;
    final DeviceRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'message': 'ok',
          'data': <String, dynamic>{
            'count': 1,
            'next': 'http://example.com/api/v1/devices/?page=2',
            'previous': null,
            'results': <Map<String, dynamic>>[sampleDeviceJson()],
          },
        });
      }),
    );

    final DevicePage<Device> page = await source.getDevices(
      const DeviceQuery(
        search: 'LAP',
        status: DeviceStatus.available,
        type: 'Laptop',
        assigned: true,
      ),
    );

    expect(captured?.path, DeviceEndpoints.devices);
    expect(captured?.queryParameters['search'], 'LAP');
    expect(captured?.queryParameters['status'], 'AVAILABLE');
    expect(captured?.queryParameters['type'], 'Laptop');
    expect(captured?.queryParameters['assigned'], true);
    expect(page.results.single.assetCode, 'LAP-001');
    expect(page.hasMore, isTrue);
  });

  test('create posts snake_case without company_id or status', () async {
    Object? lastBody;
    String? lastPath;
    final DeviceRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        lastBody = options.data;
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleDeviceJson(detail: true, sensitive: true),
        });
      }),
    );

    await source.createDevice(
      const DeviceWrite(assetCode: 'LAP-009', type: 'Laptop'),
    );
    expect(lastPath, DeviceEndpoints.devices);
    final Map<String, dynamic> body = lastBody! as Map<String, dynamic>;
    expect(body['asset_code'], 'LAP-009');
    expect(body.containsKey('company_id'), isFalse);
    expect(body.containsKey('status'), isFalse);
  });

  test('update patches including status when allowed', () async {
    RequestOptions? captured;
    final DeviceRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleDeviceJson(status: 'MAINTENANCE', detail: true),
        });
      }),
    );

    await source.updateDevice(
      'dev-1',
      const DeviceWrite(
        assetCode: 'LAP-001',
        type: 'Laptop',
        status: DeviceStatus.maintenance,
      ),
    );
    expect(captured?.method, 'PATCH');
    expect(captured?.path, DeviceEndpoints.device('dev-1'));
    expect(
      (captured?.data as Map<String, dynamic>)['status'],
      'MAINTENANCE',
    );
  });

  test('assign, return, delete, and history use the Django action paths',
      () async {
    final List<RequestOptions> calls = <RequestOptions>[];
    final DeviceRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        calls.add(options);
        if (options.method == 'DELETE') {
          return _json(200, <String, dynamic>{'success': true, 'data': null});
        }
        if (options.path.contains('/history/')) {
          return _json(200, <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'count': 1,
              'next': null,
              'previous': null,
              'results': <Map<String, dynamic>>[sampleHistoryJson()],
            },
          });
        }
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleDeviceJson(detail: true),
        });
      }),
    );

    await source.assignDevice(
      'dev-1',
      const AssignDeviceBody(employeeId: 'emp-1', conditionOnAssignment: 'Good'),
    );
    await source.returnDevice(
      'dev-1',
      const ReturnDeviceBody(conditionOnReturn: 'Worn'),
    );
    await source.deleteDevice('dev-1');
    final DevicePage<DeviceHistoryItem> history = await source.getDeviceHistory(
      'dev-1',
      const DeviceHistoryQuery(page: 1),
    );

    expect(calls[0].path, DeviceEndpoints.assign('dev-1'));
    expect(calls[0].method, 'POST');
    expect(
      (calls[0].data as Map<String, dynamic>)['employee_id'],
      'emp-1',
    );
    expect((calls[0].data as Map<String, dynamic>).containsKey('device_id'), isFalse);
    expect(calls[1].path, DeviceEndpoints.returnDevice('dev-1'));
    expect(
      (calls[1].data as Map<String, dynamic>)['condition_on_return'],
      'Worn',
    );
    expect(calls[2].method, 'DELETE');
    expect(calls[2].path, DeviceEndpoints.device('dev-1'));
    expect(calls[3].path, DeviceEndpoints.history('dev-1'));
    expect(history.results.single.isActive, isTrue);
  });
}

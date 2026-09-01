import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:flutter_base/features/settings/data/settings_endpoints.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/settings_fakes.dart';

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

SettingsRemoteDataSourceImpl _source(_Adapter adapter) {
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
  return SettingsRemoteDataSourceImpl(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('GET settings parses the envelope', () async {
    RequestOptions? captured;
    final SettingsRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'message': 'ok',
          'data': sampleSettingsJson(),
        });
      }),
    );

    final CompanySettings settings = await source.getSettings();
    expect(captured?.path, SettingsEndpoints.settings);
    expect(captured?.method, 'GET');
    expect(settings.companyName, 'Acme');
    expect(settings.workStartTime.hour, 9);
  });

  test('PATCH settings sends a partial JSON body', () async {
    RequestOptions? captured;
    final SettingsRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'message': 'updated',
          'data': sampleSettingsJson(timezone: 'Europe/London', grace: 20),
        });
      }),
    );

    final CompanySettings updated = await source.updateSettings(
      const CompanySettingsPatch(
        timezone: 'Europe/London',
        gracePeriodMinutes: 20,
      ),
    );
    expect(captured?.path, SettingsEndpoints.settings);
    expect(captured?.method, 'PATCH');
    expect(captured?.data, <String, dynamic>{
      'timezone': 'Europe/London',
      'grace_period_minutes': 20,
    });
    expect(updated.timezone, 'Europe/London');
    expect(updated.gracePeriodMinutes, 20);
  });
}

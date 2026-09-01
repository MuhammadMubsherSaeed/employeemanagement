import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_environment.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:flutter_base/features/notifications/data/notification_endpoints.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_enums.dart';
import 'package:flutter_base/features/notifications/domain/entities/notification_query.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/notification_fakes.dart';

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

NotificationRemoteDataSourceImpl _source(_Adapter adapter) {
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
  return NotificationRemoteDataSourceImpl(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('parses paginated notifications and query params', () async {
    RequestOptions? captured;
    final NotificationRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        captured = options;
        return _json(200, <String, dynamic>{
          'success': true,
          'message': 'ok',
          'data': <String, dynamic>{
            'count': 1,
            'next': 'http://example.com/api/v1/notifications/?page=2',
            'previous': null,
            'results': <Map<String, dynamic>>[sampleNotificationJson()],
          },
        });
      }),
    );

    final NotificationPage<AppNotification> page = await source.getNotifications(
      const NotificationQuery(
        isRead: false,
        type: AppNotificationType.system,
      ),
    );

    expect(captured?.path, NotificationEndpoints.notifications);
    expect(captured?.queryParameters['is_read'], false);
    expect(captured?.queryParameters['type'], 'SYSTEM');
    expect(page.results.single.title, 'System notice');
    expect(page.hasMore, isTrue);
  });

  test('unread count and mark-read use envelope data', () async {
    String? lastPath;
    final NotificationRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        if (options.path.contains('unread-count')) {
          return _json(200, <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{'count': 5},
          });
        }
        if (options.path.contains('mark-all-read')) {
          return _json(200, <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{'updated': 4},
          });
        }
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleNotificationJson(detail: true, isRead: true),
        });
      }),
    );

    expect(await source.getUnreadCount(), 5);
    expect(lastPath, NotificationEndpoints.unreadCount);
    expect((await source.markAsRead('n-1')).isRead, isTrue);
    expect(lastPath, NotificationEndpoints.markRead('n-1'));
    expect(await source.markAllAsRead(), 4);
    expect(lastPath, NotificationEndpoints.markAllRead);
  });

  test('device token register omits user_id and company_id', () async {
    Object? lastBody;
    String? lastPath;
    final NotificationRemoteDataSourceImpl source = _source(
      _Adapter((RequestOptions options) {
        lastPath = options.path;
        lastBody = options.data;
        return _json(200, <String, dynamic>{
          'success': true,
          'data': sampleDeviceTokenJson(),
        });
      }),
    );

    final DeviceTokenRegistration row = await source.registerDeviceToken(
      const RegisterDeviceTokenBody(
        token: 'fcm-token-12345678',
        platform: DeviceTokenPlatform.android,
        deviceName: 'Pixel',
      ),
    );
    expect(lastPath, NotificationEndpoints.deviceTokens);
    expect(row.id, 'tok-1');
    expect(row.platform, DeviceTokenPlatform.android);
    final Map<String, dynamic> body = Map<String, dynamic>.from(lastBody! as Map);
    expect(body.containsKey('user_id'), isFalse);
    expect(body.containsKey('company_id'), isFalse);
    expect(body['token'], 'fcm-token-12345678');

    await source.updateDeviceToken(
      'tok-1',
      const UpdateDeviceTokenBody(token: 'fcm-token-99999999'),
    );
    expect(lastPath, NotificationEndpoints.deviceToken('tok-1'));
    await source.removeDeviceToken('tok-1');
    expect(lastPath, NotificationEndpoints.deviceToken('tok-1'));
  });
}

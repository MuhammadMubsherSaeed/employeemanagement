import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/network/auth_endpoints.dart';
import 'package:flutter_base/core/network/interceptors/dio_interceptors.dart';
import 'package:flutter_base/core/network/token_refresh_coordinator.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  int refreshCount = 0;
  bool failRefresh = false;
  bool failRetry = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = '${options.path} ${options.uri.path}'.toLowerCase();
    if (path.contains('refresh')) {
      refreshCount += 1;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (failRefresh) {
        return _json(401, <String, dynamic>{
          'success': false,
          'message': 'expired',
          'code': 'TOKEN_EXPIRED',
        });
      }
      return _json(200, <String, dynamic>{
        'success': true,
        'message': 'Token refreshed successfully.',
        'data': <String, dynamic>{
          'access': 'new-access',
          'refresh': 'new-refresh',
        },
      });
    }

    if (options.extra[AuthRequestExtra.authRetried] == true) {
      if (failRetry) {
        return _json(401, <String, dynamic>{
          'success': false,
          'code': 'UNAUTHORIZED',
        });
      }
      return _json(200, <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'ok': true},
      });
    }

    return _json(401, <String, dynamic>{
      'success': false,
      'message': 'Please sign in again.',
      'code': 'UNAUTHORIZED',
    });
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

  @override
  void close({bool force = false}) {}
}

Future<Dio> _dioWithAuth({
  required _Adapter adapter,
  required TokenStorage tokens,
  required SecureStorageService storage,
  void Function()? onInvalid,
}) async {
  final Dio dio = Dio(
    BaseOptions(baseUrl: 'http://example.com/api/v1/'),
  );
  dio.httpClientAdapter = adapter;
  dio.interceptors.addAll(
    DioInterceptorFactory.build(
      storage: storage,
      enableLogging: false,
      dio: dio,
      tokenStorage: tokens,
      coordinator: TokenRefreshCoordinator(),
      onSessionInvalidated: onInvalid,
    ),
  );
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage secure;
  late SecureStorageService storage;
  late TokenStorage tokens;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      StorageKeys.accessToken: 'old-access',
      StorageKeys.refreshToken: 'old-refresh',
    });
    secure = const FlutterSecureStorage();
    storage = SecureStorageService(secure);
    tokens = SecureTokenStorage(storage);
  });

  test('concurrent 401s share a single refresh', () async {
    final _Adapter adapter = _Adapter();
    final Dio dio = await _dioWithAuth(
      adapter: adapter,
      tokens: tokens,
      storage: storage,
    );

    final List<Response<dynamic>> responses = await Future.wait(
      <Future<Response<dynamic>>>[
        dio.get<dynamic>('auth/me/'),
        dio.get<dynamic>('auth/me/'),
        dio.get<dynamic>('auth/me/'),
      ],
    );

    expect(adapter.refreshCount, 1);
    expect(responses.every((Response<dynamic> item) => item.statusCode == 200), isTrue);
    expect(await tokens.getAccessToken(), 'new-access');
    expect(await tokens.getRefreshToken(), 'new-refresh');
  });

  test('refresh failure clears the session', () async {
    final _Adapter adapter = _Adapter()..failRefresh = true;
    bool invalidated = false;
    final Dio dio = await _dioWithAuth(
      adapter: adapter,
      tokens: tokens,
      storage: storage,
      onInvalid: () => invalidated = true,
    );

    await expectLater(dio.get<dynamic>('auth/me/'), throwsA(isA<DioError>()));
    expect(await tokens.getRefreshToken(), isNull);
    expect(invalidated, isTrue);
  });

  test('a 401 after a successful refresh does not loop', () async {
    final _Adapter adapter = _Adapter()..failRetry = true;
    bool invalidated = false;
    final Dio dio = await _dioWithAuth(
      adapter: adapter,
      tokens: tokens,
      storage: storage,
      onInvalid: () => invalidated = true,
    );

    await expectLater(dio.get<dynamic>('auth/me/'), throwsA(isA<DioError>()));
    expect(adapter.refreshCount, 1);
    expect(invalidated, isTrue);
  });

  test('login 401 does not attempt refresh', () async {
    final _Adapter adapter = _Adapter();
    final Dio dio = await _dioWithAuth(
      adapter: adapter,
      tokens: tokens,
      storage: storage,
    );

    await expectLater(
      dio.post<dynamic>('auth/login/', data: <String, dynamic>{}),
      throwsA(isA<DioError>()),
    );
    expect(adapter.refreshCount, 0);
  });
}

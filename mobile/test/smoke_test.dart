import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API path constants are initialized', () {
    expect(ApiPaths.v1, '/api/v1');
    expect(ApiPaths.health, '/api/v1/health/');
  });
}

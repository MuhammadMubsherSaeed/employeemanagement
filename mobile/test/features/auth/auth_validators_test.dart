import 'package:flutter_base/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email and password validators', () {
    expect(AuthValidators.email(null), isNotNull);
    expect(AuthValidators.email('not-an-email'), isNotNull);
    expect(AuthValidators.email('user@example.com'), isNull);
    expect(AuthValidators.requiredPassword(''), isNotNull);
    expect(AuthValidators.strongPassword('short'), isNotNull);
    expect(AuthValidators.strongPassword('long-enough'), isNull);
    expect(AuthValidators.confirmPassword('a', 'b'), isNotNull);
    expect(AuthValidators.confirmPassword('same', 'same'), isNull);
  });
}

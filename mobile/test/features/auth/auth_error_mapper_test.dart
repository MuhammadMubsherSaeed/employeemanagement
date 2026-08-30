import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps backend auth codes to user-safe copy', () {
    expect(
      AuthErrorMapper.message(
        const UnauthorizedException(
          'Invalid email or password.',
          'INVALID_CREDENTIALS',
        ),
      ),
      AuthErrorMapper.invalidCredentials,
    );
    expect(
      AuthErrorMapper.message(
        const ForbiddenException(
          'This account is inactive.',
          'ACCOUNT_INACTIVE',
        ),
      ),
      AuthErrorMapper.accountInactive,
    );
    expect(
      AuthErrorMapper.message(
        const UnauthorizedException('gone', 'TOKEN_BLACKLISTED'),
      ),
      AuthErrorMapper.sessionExpired,
    );
    expect(
      AuthErrorMapper.message(const NetworkException()),
      AuthErrorMapper.network,
    );
  });
}

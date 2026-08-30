import 'package:flutter_base/core/network/auth_endpoints.dart';
import 'package:flutter_base/core/network/token_refresh_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('concurrent run() performs a single refresh', () async {
    final TokenRefreshCoordinator coordinator = TokenRefreshCoordinator();
    int calls = 0;

    Future<TokenPair?> task() async {
      calls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return const TokenPair(access: 'a', refresh: 'r');
    }

    final List<TokenPair?> results = await Future.wait(
      <Future<TokenPair?>>[
        coordinator.run(task),
        coordinator.run(task),
        coordinator.run(task),
      ],
    );

    expect(calls, 1);
    expect(results.every((TokenPair? item) => item?.access == 'a'), isTrue);
  });

  test('a later refresh can run after the first completes', () async {
    final TokenRefreshCoordinator coordinator = TokenRefreshCoordinator();
    int calls = 0;
    Future<TokenPair?> task() async {
      calls += 1;
      return const TokenPair(access: 'a');
    }

    await coordinator.run(task);
    await coordinator.run(task);
    expect(calls, 2);
  });
}

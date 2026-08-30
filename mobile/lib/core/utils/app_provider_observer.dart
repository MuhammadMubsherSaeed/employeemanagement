import 'package:flutter_base/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Do not log provider values — they may later include tokens or PII.
    AppLogger.debug('[riverpod] ${provider.name ?? provider.runtimeType}');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_base/core/app_initialization.dart';
import 'package:flutter_base/core/constants/app_constants.dart';
import 'package:flutter_base/core/router/app_router.dart';
import 'package:flutter_base/core/theme/app_theme.dart';
import 'package:flutter_base/core/theme/theme_mode_controller.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_base/core/widgets/app_loader.dart';
import 'package:flutter_base/features/notifications/presentation/widgets/notification_host.dart';
import 'package:flutter_base/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HrmsApp extends ConsumerWidget {
  const HrmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> initialization = ref.watch(
      appInitializationProvider,
    );

    return initialization.when(
      loading: () => const _BootShell(
        child: AppLoader(message: 'Starting HRMS...'),
      ),
      error: (Object _, StackTrace __) => _BootShell(
        child: AppErrorWidget(
          message: 'The application could not start. Please try again.',
          onRetry: () => ref.invalidate(appInitializationProvider),
        ),
      ),
      data: (_) {
        final GoRouter router = ref.watch(goRouterProvider);
        final ThemeMode themeMode = ref.watch(themeModeControllerProvider);
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
          builder: (BuildContext context, Widget? child) {
            return NotificationHost(child: child ?? const SizedBox.shrink());
          },
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale('ur'),
          ],
        );
      },
    );
  }
}

class _BootShell extends StatelessWidget {
  const _BootShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(body: child),
    );
  }
}

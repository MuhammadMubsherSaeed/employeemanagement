import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base/app.dart';
import 'package:flutter_base/core/config/app_config.dart';
import 'package:flutter_base/core/config/app_config_provider.dart';
import 'package:flutter_base/core/storage/secure_storage_service.dart';
import 'package:flutter_base/core/storage/shared_prefs_service.dart';
import 'package:flutter_base/core/utils/app_logger.dart';
import 'package:flutter_base/core/utils/app_provider_observer.dart';
import 'package:flutter_base/core/widgets/app_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error('Flutter error', details.exception, details.stack);
  };

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    final AppConfig config = AppConfig.fromEnvironment();
    AppLogger.configure(
      ConsoleAppLogger(enableVerbose: config.enableVerboseLogging),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    const FlutterSecureStorage secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    runApp(
      ProviderScope(
        observers: <ProviderObserver>[AppProviderObserver()],
        overrides: <Override>[
          appConfigProvider.overrideWithValue(config),
          sharedPreferencesProvider.overrideWithValue(prefs),
          flutterSecureStorageProvider.overrideWithValue(secureStorage),
        ],
        child: const HrmsApp(),
      ),
    );
  } catch (error, stack) {
    AppLogger.error('Initialization failed', error, stack);
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: AppErrorWidget(
            message: 'The application could not start. Please try again.',
            onRetry: bootstrap,
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base/firebase_options.dart';
import 'package:flutter_base/route/route_generator.dart';
import 'package:flutter_base/theme.dart';
import 'package:flutter_base/utils/firebase_notification_service.dart';
import 'package:flutter_base/utils/logger.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_base/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'route/routes.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Catch and report Flutter errors.
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
        .then((value) =>
            runApp(ProviderScope(observers: [Logger()], child: const MyApp())));
    FirebaseNotificationService.firebaseNotificationInit();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    runApp(ProviderScope(observers: [Logger()], child: const MyApp()));
  }, (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: false,
      splitScreenMode: false,
      builder: (BuildContext context, Widget? child) {
        return child!;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "appName",
        localizationsDelegates: const [
          AppLocalizations.delegate, // Add this line
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ur'),
          Locale('en'),
        ],
        theme: lightThemeData,
        onGenerateRoute: RouteGenerator.generateRoute,
        initialRoute: Routes.SPLASH,
        builder: EasyLoading.init(),
        // routes: ThemeAppPages.routes,
      ),
    );
  }
}

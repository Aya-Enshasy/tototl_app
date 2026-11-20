import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/notifications/fcm_token_manager.dart';
import 'core/navigation/route_debug_observer.dart';
import 'core/notifications/push_notification_coordinator.dart';
import 'core/localization/app_language.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate: initialize Firebase only, never navigate or send
  // protected API requests without the foreground authenticated session.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A missing or unresponsive Google Play Services / Firebase provider on an
  // AOSP emulator must never prevent the FIRST Flutter frame from rendering.
  // All optional platform services initialize after the app is on screen.
  debugPrint('[TOTOTL][BOOT] run_app');
  runApp(const MyApp());
  unawaited(_initializeOptionalServices());
}

Future<void> _initializeOptionalServices() async {
  try {
    debugPrint('[TOTOTL][BOOT] language_start');
    await AppLanguage.load().timeout(const Duration(seconds: 6));
    debugPrint('[TOTOTL][BOOT] language_ready');
  } catch (error) {
    debugPrint('[TOTOTL][BOOT] language_unavailable: ${error.runtimeType}');
  }

  try {
    debugPrint('[TOTOTL][BOOT] firebase_start');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 12));
    debugPrint('[TOTOTL][BOOT] firebase_ready');
  } catch (error) {
    // Login, jobs, contracts, and Stripe use Laravel, not FCM. They must still
    // be reachable when Firebase initialization fails on Genymotion.
    debugPrint('[TOTOTL][BOOT] firebase_unavailable: ${error.runtimeType}');
    return;
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await PushNotificationCoordinator.instance.initialize()
        .timeout(const Duration(seconds: 10));
    debugPrint('[TOTOTL][BOOT] push_ready');
  } catch (error) {
    debugPrint('[TOTOTL][BOOT] push_unavailable: ${error.runtimeType}');
  }

  try {
    await FcmTokenManager.instance.initialize()
        .timeout(const Duration(seconds: 10));
    debugPrint('[TOTOTL][BOOT] fcm_ready');
  } catch (error) {
    debugPrint('[TOTOTL][BOOT] fcm_unavailable: ${error.runtimeType}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final TototlRouteDebugObserver _routeLogger =
      TototlRouteDebugObserver();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (_, locale, __) => MaterialApp(
        navigatorKey: PushNotificationCoordinator.instance.navigatorKey,
        navigatorObservers: [_routeLogger],
        scaffoldMessengerKey: PushNotificationCoordinator.instance.messengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('de')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (_, child) => Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
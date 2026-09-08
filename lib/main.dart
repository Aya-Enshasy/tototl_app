import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/notifications/fcm_token_manager.dart';
import 'core/localization/app_language.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppLanguage.load();

  runApp(const MyApp());

  try {
    await FcmTokenManager.instance.initialize();
  } catch (e) {
    debugPrint('FCM INITIALIZATION FAILED: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (_, locale, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: locale,
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
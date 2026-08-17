import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_language.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguage.load();

  runApp(const MyApp());
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

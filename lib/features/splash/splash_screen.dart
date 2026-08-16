import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 import '../../core/theme/app_colors.dart';
import '../auth/screens/login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ضبط شريط النظام العلوي
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    startSplash();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحميل الصور مسبقاً في الذاكرة لمنع أي تأخير أو ضبابية أثناء الفتح على الجوال
    precacheImage(const AssetImage("assets/images/splash.jpeg"), context);
  }

  void startSplash() {
    Future.delayed(
      const Duration(seconds: 3),
          () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final logoSize = (MediaQuery.of(context).size.width * 0.70)
        .clamp(180.0, 260.0);

    return Scaffold(
       backgroundColor: AppColors.logoNavy,
      body: Stack(
        children: [
           Positioned.fill(
            child: Image.asset(
              "assets/images/splash.jpeg",
              fit: BoxFit.cover,
            ),
          ),


          // 3. المحتوى الرئيسي
          SafeArea(
            child: Stack(
              children: [
                // =========================
                // اللوجو والمحتوى الرئيسي
                // =========================
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'TOTOTL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),

                        const Text(
                          'I N T G R X',
                          style: TextStyle(
                            color: Color(0xFF16C6C7),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 45,
                              height: 1,
                              color: Colors.white38,
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'DRONE PILOT & COMPANY PLATFORM',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            Container(
                              width: 45,
                              height: 1,
                              color: Colors.white38,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // =========================
                // المحتوى السفلي
                // =========================
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 50,
                  child: Column(
                    children: [
                      // النقاط الثلاث
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF21E6C1),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF21E6C1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // READY TO FLY
                      const Text(
                        "READY TO FLY",
                        style: TextStyle(
                          color: Color(0xFF21E6C1),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
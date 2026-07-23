import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    startSplash();
  }

  void startSplash() {
    Future.delayed(
      const Duration(seconds: 3), // نصيحة UX: تم تقليله من 10 إلى 3 ثوانٍ لأن 10 ثوانٍ طويلة جداً على المستخدم
          () {
        // هنا يمكنك فحص الـ Token وحالة التسجيل لاحقاً
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
    // جعل شريط الحالة العلوي شفافاً بالكامل لتندمج خلفية الدرون مع الشاشة
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Stack(
        children: [
          // 1. الصورة الأولى: الخلفية الكاملة للدرون
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "assets/images/drone_login.png",
              fit: BoxFit.cover,
            ),
          ),

          // 2. تدرج لوني داكن (Midnight Blue/Black Overlay)
          // يمنح أسفل الشاشة عمقاً داكناً يطابق التصميم تماماً لجعل اللوجو بارزاً ونقياً
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    const Color(0xFF0A122C).withOpacity(0.85), // درجة الأزرق الداكنة جداً من التصميم
                    const Color(0xFF040817),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // 3. العناصر السفلية (اللوجو، النقاط، والنص السفلي)
          Positioned(
            bottom: 45,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الصورة الثانية: كتلة اللوجو بالكامل (الرسمة + الاسم + الشعار السفلي)
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  // height: size.height * 0.42,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // اللوجو بحجم 70px
                        Image.asset(
                          'assets/images/logo.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),

                        // اسم TOTOTL ببنط 42 ووزن ExtraBold و LetterSpacing -1
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

                        // كلمة INTGRX باللون #3E63F4 وتباعد 4.5
                        const Text(
                          'I N T G R X',
                          style: TextStyle(
                            color: Color(0xFF3E63F4),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // النص السفلي مع خطين بعرض 45px
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 45, height: 1, color: Colors.white38),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
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
                            Container(width: 45, height: 1, color: Colors.white38),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // النقاط الثلاثة التفاعلية (Page Indicator Dots) بألوان التصميم
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4A77FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF3F6DFB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF7B99FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // نص READY TO FLY السفلي الأنيق بمحاذاة الحروف الواسعة
                const Text(
                  "READY TO FLY",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4.0, // إعطاء مسافة واسعة بين الحروف لتطابق التصميم بدقة
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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/login_screen.dart';
import '../../core/theme/app_colors.dart';

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
    precacheImage(const AssetImage("assets/images/splash.png"), context);
    // precacheImage(const AssetImage('assets/images/logo.png'), context);
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
    return Scaffold(
      // لون خلفية داكن احتياطي يمنع ظهور أي لون أبيض أثناء التحميل
      backgroundColor: AppColors.logoNavy,
      body: Stack(
        children: [
          // 1. صورة الخلفية كاملة
          Positioned.fill(
            child: Image.asset(
              "assets/images/splash.png",
              fit: BoxFit.cover,
            ),
          ),

          // // 2. التدرج اللوني الداكن
          // Positioned.fill(
          //   child: Container(
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: [
          //           Colors.transparent,
          //           Colors.black.withOpacity(0.1),
          //           const Color(0xFF08384C).withOpacity(0.85),
          //           const Color(0xFF08384C),
          //         ],
          //         stops: const [0.0, 0.4, 0.8, 1.0],
          //       ),
          //     ),
          //   ),
          // ),

          // // 3. المحتوى الرئيسي
          // SafeArea(
          //   child: Column(
          //     children: [
          //       const Spacer(), // يدفع العناصر بأسلوب متناسق إلى الأسفل

          //       // كتلة اللوجو والأسماء
          //       Column(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Image.asset(
          //             'assets/images/logo.png',
          //             width: 90,
          //             height: 90,
          //             fit: BoxFit.contain,
          //           ),
          //           const SizedBox(height: 4),
          //           const Text(
          //             'TOTOTL',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 42,
          //               fontWeight: FontWeight.w900,
          //               letterSpacing: -1.0,
          //               height: 1.1,
          //             ),
          //           ),
          //           const Text(
          //             'I N T G R X',
          //             style: TextStyle(
          //               color: Color(0xFF16C6C7),
          //               fontSize: 15,
          //               fontWeight: FontWeight.w800,
          //               letterSpacing: 5.5,
          //             ),
          //           ),
          //           const SizedBox(height: 12),
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               Container(width: 45, height: 1, color: Colors.white38),
          //               const Padding(
          //                 padding: EdgeInsets.symmetric(horizontal: 8.0),
          //                 child: Text(
          //                   'DRONE PILOT & COMPANY PLATFORM',
          //                   style: TextStyle(
          //                     color: Colors.white70,
          //                     fontSize: 12,
          //                     letterSpacing: 0.8,
          //                     fontWeight: FontWeight.w500,
          //                   ),
          //                 ),
          //               ),
          //               Container(width: 45, height: 1, color: Colors.white38),
          //             ],
          //           ),
          //         ],
          //       ),

          //       const SizedBox(height: 35),

          //       // النقاط الثلاث
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Container(
          //             width: 6,
          //             height: 6,
          //             decoration: const BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: Color(0xFF21E6C1),
          //             ),
          //           ),
          //           const SizedBox(width: 8),
          //           Container(
          //             width: 6,
          //             height: 6,
          //             decoration: const BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: Color(0xFF16C6C7),
          //             ),
          //           ),
          //           const SizedBox(width: 8),
          //           Container(
          //             width: 6,
          //             height: 6,
          //             decoration: const BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: Color(0xFF7B99FF),
          //             ),
          //           ),
          //         ],
          //       ),

          //       const SizedBox(height: 35),

          //       // النص السفلي
          //       const Text(
          //         "READY TO FLY",
          //         style: TextStyle(
          //           color: Colors.white60,
          //           fontSize: 11,
          //           fontWeight: FontWeight.w600,
          //           letterSpacing: 4.0,
          //         ),
          //       ),

          //       const SizedBox(height: 20),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
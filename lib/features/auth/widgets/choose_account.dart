import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/features/auth/register/pilot/pilot_register_step_one_screen.dart';

import '../register/company/company_register_step_one_screen.dart';

class ChooseAccountTypeScreen extends StatefulWidget {
  const ChooseAccountTypeScreen({super.key});

  @override
  State<ChooseAccountTypeScreen> createState() => _ChooseAccountTypeScreenState();
}

class _ChooseAccountTypeScreenState extends State<ChooseAccountTypeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _bgFadeAnimation;
  late Animation<double> _sheetEntranceAnimation;
  late Animation<double> _card1FadeAnimation;
  late Animation<Offset> _card1SlideAnimation;
  late Animation<double> _card2FadeAnimation;
  late Animation<Offset> _card2SlideAnimation;

  // متغير للتحكم في مسافة سحب الشاشة باليد لأسفل
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 1. ظهور التظليل والـ Blur تدريجياً
    _bgFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    // 2. حركة صعود الـ Sheet من الأسفل
    _sheetEntranceAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.fastLinearToSlowEaseIn),
      ),
    );

    // 3. حركة الكرت الأول
    _card1FadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );
    _card1SlideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.85, curve: Curves.fastLinearToSlowEaseIn),
      ),
    );

    // 4. حركة الكرت الثاني
    _card2FadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.97, curve: Curves.easeOut),
      ),
    );
    _card2SlideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.97, curve: Curves.fastLinearToSlowEaseIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // إغلاق الشاشة بحركة عكسية ناعمة
  void _dismissScreen() {
    _controller.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sheetHeight = size.height * 0.70;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double currentTranslation = (_sheetEntranceAnimation.value * sheetHeight) + _dragOffset;

          return Stack(
            children: [
              // ==========================================
              // الطبقة 1: تأثير التمويه (Blur)
              // ==========================================
              Positioned.fill(
                child: FadeTransition(
                  opacity: _bgFadeAnimation,
                  child: GestureDetector(
                    onTap: _dismissScreen,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        color: const Color(0xFF0B1731).withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================
              // الطبقة 2: الـ Bottom Sheet التفاعلي
              // ==========================================
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: sheetHeight,
                child: Transform.translate(
                  offset: Offset(0, currentTranslation),
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _dragOffset += details.primaryDelta!;
                        if (_dragOffset < 0) _dragOffset = 0;
                      });
                    },
                    onVerticalDragEnd: (details) {
                      if (_dragOffset > sheetHeight * 0.25 || details.primaryVelocity! > 500) {
                        _dismissScreen();
                      } else {
                        setState(() {
                          _dragOffset = 0.0;
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(44),
                          topRight: Radius.circular(44),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 25,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // مقبض السحب (Indicator)
                          Container(
                            width: 45,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // النصوص
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your account type',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF8F93A3),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // الكروت الحركية
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  // كرت Drone Pilot
                                  SlideTransition(
                                    position: _card1SlideAnimation,
                                    child: FadeTransition(
                                      opacity: _card1FadeAnimation,
                                      child: _buildAccountCard(
                                        title: 'Drone Pilot',
                                        subtitle: 'Upload your profile\nand apply for jobs',
                                        imageAsset: 'assets/images/drone.png',
                                        baseColor: const Color(0xFF183B70),
                                        arrowColor: const Color(0xFF28569E),
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const PilotRegisterStepOneScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // كرت Company
                                  SlideTransition(
                                    position: _card2SlideAnimation,
                                    child: FadeTransition(
                                      opacity: _card2FadeAnimation,
                                      child: _buildAccountCard(
                                        title: 'Company',
                                        subtitle: 'Hire certified pilots\nand publish jobs',
                                        imageAsset: 'assets/images/company.png',
                                        baseColor: const Color(0xFF381B60),
                                        arrowColor: const Color(0xFF552A90),
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const CompanyRegisterStepOneScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // دالة بناء الكرت المعدلة والمتناسقة بصریاً
  Widget _buildAccountCard({
    required String title,
    required String subtitle,
    required String imageAsset,
    required Color baseColor,
    required Color arrowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. الصورة بجهة اليسار بعرض متناسق (120px)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 120,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.white10),
                ),
              ),

              // 2. تدرج لوني ناعم لإخفاء حافة الصورة ودمجها مع الخلفية
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        baseColor.withOpacity(0.3),
                        baseColor.withOpacity(0.85),
                        baseColor,
                      ],
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. النص والسهم بمسافة تبدأ من 125px لمنع أي تداخل
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(left: 125, right: 18, top: 16, bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: arrowColor,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_bar/liquid_glass_bottom_bar.dart';
import 'package:tototl_app/features/pilot/message/messages_screen.dart';

import '../../features/pilot/home/presentation/home_page.dart';
import '../../features/pilot/jobs/find_job.dart';
import '../../features/pilot/notification/NotificationsScreen.dart';
import '../../features/pilot/profile/profile_screen.dart';
import '../theme/app_colors.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const HomeScreen(),
    const FindDroneJobsScreen(),
    const MessagesScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. إضافة خلفية بتدرج ألوان خفيف خلف الشاشة لإبراز انعكاس الزجاج
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF4F7FC),
            Color(0xFFE2ECFC), // لون سماوي خفيف جداً في الأسفل لإعطاء لمعة زجاجية
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // 2. جعل خلفية الـ Scaffold شفافة لتظهر الخلفية الملهمة
        extendBody: true, // ضروري ليمر المحتوى أسفل البوتوم بار
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: LiquidGlassBottomBar(
          items: const [
            LiquidGlassBottomBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.wallet_giftcard,
              label: 'Jobs',
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.messenger_outline,
              activeIcon: Icons.messenger_outlined,
              label: 'Messages',
              badge: 5,
            ),   LiquidGlassBottomBarItem(
              icon: Icons.notifications_none_sharp,
              activeIcon: Icons.notifications_sharp,
              label: 'Notifications',
              badge: 5,
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              badge: 5,
            ),
          ],
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() {
              _currentIndex = i;
            });
          },
          // 3. تعديل خصائص الزجاج لإعطائه لمعة كريستالية الشفافية:
          activeColor: AppColors.primary,
           barBlurSigma: 8, // درجة تغبيش متوازنة تظهر المحتوى الخلفي
          activeBlurSigma: 16,
        ),
      ),
    );
  }
}


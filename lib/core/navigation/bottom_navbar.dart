import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_bar/liquid_glass_bottom_bar.dart';

import '../../features/pilot/applications/applications_screen.dart';
import '../../features/pilot/home/presentation/home_page.dart';
import '../../features/pilot/jobs/find_job.dart';
import '../../features/pilot/message/messages_screen.dart';
import '../../features/pilot/profile/profile_screen.dart';
import '../theme/app_colors.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    FindDroneJobsScreen(),
    MessagesScreen(),
    ApplicationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.logoCameraEye, AppColors.blueBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: LiquidGlassBottomBar(
          items: const [
            LiquidGlassBottomBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.work_outline_rounded,
              activeIcon: Icons.work_rounded,
              label: 'Jobs',
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.messenger_outline,
              activeIcon: Icons.messenger_rounded,
              label: 'Messages',
              badge: 5,
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.description_outlined,
              activeIcon: Icons.description_rounded,
              label: 'Applications',
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
            ),
          ],
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          activeColor: AppColors.primary,
          barBlurSigma: 8,
          activeBlurSigma: 16,
        ),
      ),
    );
  }
}

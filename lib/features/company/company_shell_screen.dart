import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_bar/liquid_glass_bottom_bar.dart';

import '../../core/theme/app_colors.dart';
import 'home/company_home_screen.dart';
import 'jobs/company_jobs_screen.dart';
import 'messages/company_messages_screen.dart';
import 'pilots/pilot_search_screen.dart';
import 'profile/company_profile_screen.dart';

class CompanyShellScreen extends StatefulWidget {
  const CompanyShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<CompanyShellScreen> createState() => _CompanyShellScreenState();
}

class _CompanyShellScreenState extends State<CompanyShellScreen> {
  late int _currentIndex;

  final _pages = const [
    CompanyHomeScreen(),
    CompanyJobsScreen(),
    PilotSearchScreen(),
    CompanyMessagesScreen(),
    CompanyProfileScreen(),
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
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Pilots',
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.messenger_outline_rounded,
              activeIcon: Icons.messenger_rounded,
              label: 'Messages',
            ),
            LiquidGlassBottomBarItem(
              icon: Icons.business_outlined,
              activeIcon: Icons.business_rounded,
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

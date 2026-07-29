import 'package:flutter/material.dart';

import '../../core/navigation/app_bottom_nav_bar.dart';
import '../../core/theme/app_colors.dart';
import 'home/company_home_screen.dart';
import 'jobs/company_jobs_screen.dart';
import 'messages/company_messages_screen.dart';
import 'operations/company_operations_screen.dart';
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
    CompanyOperationsScreen(),
    CompanyMessagesScreen(),
    CompanyProfileScreen(),
  ];

  static const _navItems = [
    AppBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppBottomNavItem(
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
      label: 'Jobs',
    ),
    AppBottomNavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Pilots',
    ),
    AppBottomNavItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Operations',
    ),
    AppBottomNavItem(
      icon: Icons.messenger_outline_rounded,
      activeIcon: Icons.messenger_rounded,
      label: 'Messages',
    ),
    AppBottomNavItem(
      icon: Icons.business_outlined,
      activeIcon: Icons.business_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

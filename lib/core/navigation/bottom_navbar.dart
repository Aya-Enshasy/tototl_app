import 'package:flutter/material.dart';

import '../../features/pilot/screens/applications/applications_screen.dart';
import '../../features/pilot/screens/home/presentation/home_page.dart';
 import '../../features/pilot/screens/jobs/find_drone_jobs.dart';
import '../../features/pilot/screens/message/messages_screen.dart';
import '../../features/pilot/screens/profile/profile_screen.dart';
import '../navigation/app_bottom_nav_bar.dart';
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
      icon: Icons.messenger_outline_rounded,
      activeIcon: Icons.messenger_rounded,
      label: 'Messages',
      badge: 5,
    ),
    AppBottomNavItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Applications',
    ),
    AppBottomNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
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

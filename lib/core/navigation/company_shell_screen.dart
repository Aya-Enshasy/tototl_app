import 'package:flutter/material.dart';
import 'package:tototl_app/core/notifications/push_notification_coordinator.dart';
import 'package:tototl_app/core/notifications/notification_inbox_state.dart';
import 'package:tototl_app/features/company/screens/home/company_home_screen.dart';
import 'package:tototl_app/features/company/screens/jobs/company_jobs_screen.dart';
import 'package:tototl_app/features/company/screens/messages/company_messages_screen.dart';
import 'package:tototl_app/features/company/screens/applications/company_application_screen.dart';
import 'package:tototl_app/features/company/screens/profile/company_profile_screen.dart';

import 'app_bottom_nav_bar.dart';
import '../theme/app_colors.dart';

class CompanyShellScreen extends StatefulWidget {
  const CompanyShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<CompanyShellScreen> createState() => _CompanyShellScreenState();
}

class _CompanyShellScreenState extends State<CompanyShellScreen> {
  late int _currentIndex;
  final Set<int> _visitedTabs = <int>{};

  final _pages = const [
    CompanyHomeScreen(),
    CompanyJobsScreen(),
    // PilotSearchScreen(),
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
    // AppBottomNavItem(
    //   icon: Icons.people_outline_rounded,
    //   activeIcon: Icons.people_rounded,
    //   label: 'Pilots',
    // ),
    AppBottomNavItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Applications',
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
    _visitedTabs.add(_currentIndex);
    PushNotificationCoordinator.instance.onAuthenticatedScreenReady();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Mount each tab only after it is visited. A non-lazy IndexedStack
      // starts every screen's API calls simultaneously and can trigger 429s.
      // Keep visited tabs mounted to preserve scroll/forms, while disabling
      // offscreen animations and their TickerMode-aware polling.
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_pages.length, (index) {
          return TickerMode(
            enabled: index == _currentIndex,
            child: _visitedTabs.contains(index)
                ? _pages[index]
                : const SizedBox.shrink(),
          );
        }),
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
          _visitedTabs.add(index);
        }),
      ),
    );
  }
}

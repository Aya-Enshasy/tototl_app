import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/account_settings_screen.dart';
import '../../shared/settings_detail_screens.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Company Profile',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AccountSettingsScreen(isCompany: true),
                    ),
                  ),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.solar_power_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'SunTech Energy Ltd.',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Renewable Energy · Mojave Desert, CA',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.green,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Verified Company',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Metric(value: '47', label: 'Jobs posted'),
                      _Metric(value: '23', label: 'Pilots hired'),
                      _Metric(value: '4.8', label: 'Company rating'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'About',
              child: const Text(
                'SunTech Energy delivers large-scale solar operations, inspections, and field intelligence across California.',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Account',
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.business_outlined,
                    title: 'Company details',
                    subtitle: 'Industry, address, and operating regions',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UpdateProfileScreen(isCompany: true),
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.cardBorder),
                  _Tile(
                    icon: Icons.credit_card_outlined,
                    title: 'Subscription plan',
                    subtitle: 'Monthly plan · Active',
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.cardBorder),
                  _Tile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Job and application activity',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(isCompany: true),
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.cardBorder),
                  _Tile(
                    icon: Icons.security_outlined,
                    title: 'Security & privacy',
                    subtitle: 'Account access and data controls',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
      ],
    ),
  ));
}

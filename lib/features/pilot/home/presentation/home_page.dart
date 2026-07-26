import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../applications/applications_screen.dart';
import '../../jobs/find_job.dart';
import '../../shared/pilot_data.dart';
import '../widgets/home_header.dart';
import '../widgets/job_card.dart';
import '../widgets/my_drone_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bac.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.84)),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: PilotApplicationsStore.instance,
              builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeHeader(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: _DashboardStatCard(
                            label: 'Total earned',
                            value: r'$12,480',
                            icon: Icons.account_balance_wallet_outlined,
                            accent: AppColors.blue,
                            background: AppColors.blueBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardStatCard(
                            label: 'Active applications',
                            value:
                                '${PilotApplicationsStore.instance.activeCount}',
                            icon: Icons.description_outlined,
                            accent: AppColors.green,
                            background: AppColors.greenBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const MyDroneCard(),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: 'Recommended Jobs',
                      onSeeAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FindDroneJobsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const JobCard(),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: 'My Applications',
                      onSeeAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApplicationsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ApplicationsScreen(compact: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See all',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

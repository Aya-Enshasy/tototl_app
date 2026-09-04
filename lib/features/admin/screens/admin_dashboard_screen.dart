import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../widgets/admin_design.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onPilots,
    required this.onCompanies,
  });

  final AdminController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onPilots;
  final VoidCallback onCompanies;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AdminColors.tealDark,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _Hero(
                total: controller.totalPending,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.flight_takeoff_rounded,
                      value: '${controller.pendingPilotCount}',
                      label: 'Pending Pilots',
                      color: AdminColors.pilot,
                      background: AdminColors.pilotSoft,
                      onTap: onPilots,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.apartment_rounded,
                      value: '${controller.pendingCompanyCount}',
                      label: 'Companies',
                      color: AdminColors.company,
                      background: AdminColors.companySoft,
                      onTap: onCompanies,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fact_check_outlined,
                      value: '${controller.totalPending}',
                      label: 'Total Reviews',
                      color: AdminColors.tealDark,
                      background: AdminColors.tealSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _QueueShortcut(
                icon: Icons.flight_takeoff_rounded,
                title: 'Pilot Verification Queue',
                subtitle:
                    '${controller.pendingPilotCount} application${controller.pendingPilotCount == 1 ? '' : 's'} waiting',
                color: AdminColors.pilot,
                background: AdminColors.pilotSoft,
                onTap: onPilots,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              36,
            ),
            sliver: SliverToBoxAdapter(
              child: _QueueShortcut(
                icon: Icons.apartment_rounded,
                title: 'Company Verification Queue',
                subtitle:
                    '${controller.pendingCompanyCount} application${controller.pendingCompanyCount == 1 ? '' : 's'} waiting',
                color: AdminColors.company,
                background: AdminColors.companySoft,
                onTap: onCompanies,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.total,
  });

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF082B40),
            Color(0xFF0A5061),
            Color(0xFF0D7985),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.navy.withOpacity(0.20),
            blurRadius: 32,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -40,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.055),
              ),
            ),
          ),
          Positioned(
            right: 55,
            bottom: -70,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AdminColors.teal.withOpacity(0.09),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF95EFED),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ADMIN CONTROL CENTER',
                      style: TextStyle(
                        color: Color(0xFFD2FBFA),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Command the platform.\nReview with confidence.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                total == 0
                    ? 'Your verification queue is clear.'
                    : '$total account${total == 1 ? '' : 's'} require admin attention.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 10.8,
                ),
              ),
            ],
          ),
          Positioned(
            right: 2,
            bottom: 4,
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.09),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 122,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AdminColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 9.2,
                    fontWeight: FontWeight.w600,
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

class _QueueShortcut extends StatelessWidget {
  const _QueueShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AdminColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 9.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AdminColors.muted2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

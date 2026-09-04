import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../widgets/admin_design.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onReviews,
    required this.onAccounts,
  });

  final AdminController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onReviews;
  final VoidCallback onAccounts;

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
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              18,
              14,
              18,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _HomeHeader(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _Hero(
                totalPending:
                    controller.totalPending,
                onReviews:
                    onReviews,
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
              child: _OverviewStats(
                controller:
                    controller,
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
              child: _SectionHeading(
                title:
                    'Verification Queues',
                subtitle:
                    'Accounts waiting for admin review',
                action:
                    controller.totalPending > 0
                        ? 'Open reviews'
                        : null,
                onTap:
                    controller.totalPending > 0
                        ? onReviews
                        : null,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _QueueCard(
                      icon:
                          Icons.flight_takeoff_rounded,
                      title:
                          'Pilots',
                      count:
                          controller.pendingPilotCount,
                      subtitle:
                          'Pending verification',
                      foreground:
                          AdminColors.pilot,
                      background:
                          AdminColors.pilotSoft,
                      onTap:
                          onReviews,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _QueueCard(
                      icon:
                          Icons.apartment_rounded,
                      title:
                          'Companies',
                      count:
                          controller.pendingCompanyCount,
                      subtitle:
                          'Pending verification',
                      foreground:
                          AdminColors.company,
                      background:
                          AdminColors.companySoft,
                      onTap:
                          onReviews,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              18,
              22,
              18,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionHeading(
                title:
                    'Admin Tools',
                subtitle:
                    'Everything you need to control verification',
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              36,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _ToolCard(
                    icon:
                        Icons.manage_accounts_rounded,
                    title:
                        'Accounts Directory',
                    subtitle:
                        'Search pilots and companies, then filter by status',
                    badge:
                        '${controller.knownAccounts.length}',
                    onTap:
                        onAccounts,
                  ),
                  const SizedBox(height: 11),
                  _ToolCard(
                    icon:
                        Icons.fact_check_outlined,
                    title:
                        'Review Center',
                    subtitle:
                        'Approve or reject pending applications',
                    badge:
                        '${controller.totalPending}',
                    onTap:
                        onReviews,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Overview',
                style: TextStyle(
                  color: AdminColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monitor verification and keep TOTOTL moving.',
                style: TextStyle(
                  color: AdminColors.muted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        _LiveChip(),
      ],
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AdminColors.successSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: AdminColors.success,
            size: 7,
          ),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: AdminColors.success,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.totalPending,
    required this.onReviews,
  });

  final int totalPending;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071F34),
            Color(0xFF0A4358),
            Color(0xFF0C7480),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.navy.withOpacity(0.22),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.055),
              ),
            ),
          ),
          Positioned(
            right: 62,
            bottom: -92,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AdminColors.teal.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 20,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white.withOpacity(0.12),
              size: 82,
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
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'TOTOTL  ·  ADMIN CONTROL',
                  style: TextStyle(
                    color: Color(0xFFB8F4F1),
                    fontSize: 8.3,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Keep every account\ntrusted & ready.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totalPending == 0
                    ? 'No pending verification right now.'
                    : '$totalPending account${totalPending == 1 ? '' : 's'} waiting for your decision.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 10.8,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: onReviews,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AdminColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.fact_check_outlined,
                    size: 16,
                  ),
                  label: Text(
                    totalPending == 0
                        ? 'Open Review Center'
                        : 'Review $totalPending Now',
                    style: const TextStyle(
                      fontSize: 10.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStats extends StatelessWidget {
  const _OverviewStats({
    required this.controller,
  });

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.schedule_rounded,
            value: '${controller.totalPending}',
            label: 'Pending',
            color: AdminColors.warning,
            background: AdminColors.warningSoft,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniStat(
            icon: Icons.flight_takeoff_rounded,
            value: '${controller.pendingPilotCount}',
            label: 'Pilot Queue',
            color: AdminColors.pilot,
            background: AdminColors.pilotSoft,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniStat(
            icon: Icons.apartment_rounded,
            value: '${controller.pendingCompanyCount}',
            label: 'Company Queue',
            color: AdminColors.company,
            background: AdminColors.companySoft,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                color: AdminColors.muted,
                fontSize: 8.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.action,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
        if (action != null && onTap != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor:
                  AdminColors.tealDark,
            ),
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 9.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final String subtitle;
  final Color foreground;
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
          height: 142,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AdminColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: foreground,
                      size: 19,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: AdminColors.muted2,
                    size: 17,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$count',
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontSize: 8.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: AdminColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AdminColors.tealSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: AdminColors.tealDark,
                  size: 20,
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 9.4,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

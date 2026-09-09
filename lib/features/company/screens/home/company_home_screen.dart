import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
 import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/user_session_storage.dart';
import '../../../pilot/services/company_dashboard_service.dart';
import '../../controllers/company_dashboard_controller.dart';
import '../../models/company_dashboard_model.dart';
import '../jobs/company_job_detail_screen.dart';
import '../jobs/company_jobs_screen.dart';
import '../jobs/post_job_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen>
    with SingleTickerProviderStateMixin {
  late final CompanyDashboardController _controller;
  late final AnimationController _entrance;

  String _companyName = 'Company Account';
  bool _verified = false;

  @override
  void initState() {
    super.initState();

    _controller = CompanyDashboardController(
      CompanyDashboardService(ApiClient()),
    );
    _controller.load();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _loadCompanyIdentity();
  }

  Future<void> _loadCompanyIdentity() async {
    final profile = await UserSessionStorage.getProfile();
    final status = await UserSessionStorage.getStatus();

    final possibleName =
        profile?['company_name']?.toString().trim() ??
        profile?['name']?.toString().trim();

    if (!mounted) return;

    setState(() {
      if (possibleName != null && possibleName.isNotEmpty) {
        _companyName = possibleName;
      }
      _verified = status?.toLowerCase() == 'active' ||
          status?.toLowerCase() == 'approved' ||
          status?.toLowerCase() == 'verified';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _controller.refresh();

  Widget _entry({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.07).clamp(0.0, 0.62).toDouble();
    final end = (start + 0.34).clamp(0.0, 1.0).toDouble();

    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -170,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(0.11),
                      AppColors.blue.withOpacity(0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 390,
            left: -170,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.green.withOpacity(0.055),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.dashboard == null) {
                  return const _CompanyDashboardShimmer();
                }

                if (_controller.dashboard == null) {
                  return _DashboardErrorState(
                    message: _controller.errorMessage ??
                        'Unable to load company dashboard.',
                    onRetry: _controller.load,
                  );
                }

                final dashboard = _controller.dashboard!;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.blue,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 115),
                    children: [
                      _entry(
                        index: 0,
                        child: _CompanyHeader(
                          companyName: _companyName,
                          verified: _verified,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _entry(
                        index: 1,
                        child: _DashboardHero(
                          dashboard: dashboard,
                        ),
                      ),
                      const SizedBox(height: 23),
                      _entry(
                        index: 2,
                        child: const _SectionTitle(
                          title: 'Job Overview',
                          subtitle: 'Live status of your company job postings',
                          icon: Icons.dashboard_customize_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _entry(
                        index: 3,
                        child: _StatusGrid(
                          status: dashboard.jobsByStatus,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _entry(
                        index: 4,
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PostJobScreen(),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    'Post New Job',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CompanyJobsScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navy,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.work_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Manage Jobs',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _entry(
                        index: 5,
                        child: _SectionTitle(
                          title: 'Recent Applicants',
                          subtitle: dashboard.recentApplicants.isEmpty
                              ? 'No recent applications yet'
                              : 'Latest pilots across your job postings',
                          icon: Icons.people_alt_outlined,
                          trailing: dashboard.recentApplicants.isEmpty
                              ? null
                              : _CountBadge(
                                  count: dashboard.recentApplicants.length,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (dashboard.recentApplicants.isEmpty)
                        _entry(
                          index: 6,
                          child: const _EmptyApplicantsCard(),
                        )
                      else
                        ...dashboard.recentApplicants.take(5).toList().asMap().entries.map(
                          (entry) {
                            final application = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _entry(
                                index: 6 + entry.key,
                                child: _RecentApplicantCard(
                                  application: application,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CompanyJobDetailScreen(
                                          jobId: application.jobPostingId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      if (_controller.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        _InlineRefreshWarning(
                          message: _controller.errorMessage!,
                          onRetry: _refresh,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({
    required this.companyName,
    required this.verified,
  });

  final String companyName;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0C819B),
                Color(0xFF18BDBB),
              ],
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.16),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Dashboard',
                style: TextStyle(
                  color: AppColors.grey.withOpacity(0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    verified
                        ? Icons.verified_rounded
                        : Icons.business_center_outlined,
                    color: verified ? AppColors.green : AppColors.grey,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    verified ? 'Verified company' : 'Company account',
                    style: TextStyle(
                      color: verified ? AppColors.green : AppColors.grey,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.dashboard});

  final CompanyDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    final incoming = dashboard.incomingApplicationsCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF08223F),
            Color(0xFF0B4761),
            Color(0xFF0C8C9B),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.14),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -26,
            child: Icon(
              Icons.radar_rounded,
              color: Colors.white.withOpacity(0.075),
              size: 130,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF8BE2DF),
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'LIVE OVERVIEW',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Your marketplace at a glance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                incoming == 0
                    ? 'Everything is clear — no applications are waiting for a decision.'
                    : '$incoming application${incoming == 1 ? '' : 's'} waiting for your decision.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      value: '${dashboard.totalJobs}',
                      label: 'Total Jobs',
                      icon: Icons.work_outline_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: Colors.white.withOpacity(0.10),
                  ),
                  Expanded(
                    child: _HeroMetric(
                      value: '$incoming',
                      label: 'Awaiting Decision',
                      icon: Icons.mark_email_unread_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8BE2DF),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.status});

  final CompanyJobsByStatus status;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Draft',
                value: status.draft,
                icon: Icons.edit_note_rounded,
                accent: AppColors.orange,
                soft: AppColors.orangeBg,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Published',
                value: status.published,
                icon: Icons.public_rounded,
                accent: AppColors.green,
                soft: AppColors.greenBg,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Closed',
                value: status.closed,
                icon: Icons.lock_outline_rounded,
                accent: AppColors.blue,
                soft: AppColors.blueBg,
              ),
            ),
            SizedBox(
              width: width,
              child: _StatusCard(
                label: 'Cancelled',
                value: status.cancelled,
                icon: Icons.cancel_outlined,
                accent: const Color(0xFFE45252),
                soft: const Color(0xFFFFF1F1),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.soft,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.028),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.075),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.blue, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.grey.withOpacity(0.86),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count recent',
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecentApplicantCard extends StatelessWidget {
  const _RecentApplicantCard({
    required this.application,
    required this.onTap,
  });

  final CompanyDashboardApplicant application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pilot = application.pilotProfile;
    final job = application.jobPosting;
    final drone = application.drone;
    final statusStyle = _statusStyle(application.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.026),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.blue.withOpacity(0.13),
                          AppColors.green.withOpacity(0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${application.pilotProfileId}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilot #${application.pilotProfileId}',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pilot == null
                              ? 'Professional profile'
                              : '${pilot.experienceYears ?? 0} yrs experience · ${pilot.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.soft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _titleCase(application.status),
                      style: TextStyle(
                        color: statusStyle.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(11, 10, 8, 10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.cardBorder.withOpacity(0.8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job?.title ?? 'Job #${application.jobPostingId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (drone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${drone.displayName} · ${drone.capabilities.isEmpty ? 'No capabilities listed' : drone.capabilities.join(', ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 8.8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightGrey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyApplicantsCard extends StatelessWidget {
  const _EmptyApplicantsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: AppColors.green,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No recent applicants',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'New pilot applications will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRefreshWarning extends StatelessWidget {
  const _InlineRefreshWarning({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.orange,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 9.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.blue,
                size: 33,
              ),
              const SizedBox(height: 11),
              const Text(
                'Dashboard unavailable',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyDashboardShimmer extends StatefulWidget {
  const _CompanyDashboardShimmer();

  @override
  State<_CompanyDashboardShimmer> createState() =>
      _CompanyDashboardShimmerState();
}

class _CompanyDashboardShimmerState extends State<_CompanyDashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        Widget box({
          required double height,
          double? width,
          double radius = 16,
        }) {
          final t = _animation.value;
          return Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment(-1.6 + (3.2 * t), 0),
                end: Alignment(-0.6 + (3.2 * t), 0),
                colors: [
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                ],
              ),
            ),
          );
        }

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
          children: [
            Row(
              children: [
                box(height: 52, width: 52, radius: 17),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(height: 10, width: 110, radius: 6),
                      const SizedBox(height: 8),
                      box(height: 17, width: 190, radius: 7),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            box(height: 175, radius: 25),
            const SizedBox(height: 24),
            box(height: 35, width: 150, radius: 10),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: box(height: 72, radius: 19)),
                const SizedBox(width: 10),
                Expanded(child: box(height: 72, radius: 19)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: box(height: 72, radius: 19)),
                const SizedBox(width: 10),
                Expanded(child: box(height: 72, radius: 19)),
              ],
            ),
            const SizedBox(height: 26),
            box(height: 35, width: 175, radius: 10),
            const SizedBox(height: 12),
            box(height: 118, radius: 20),
            const SizedBox(height: 10),
            box(height: 118, radius: 20),
          ],
        );
      },
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.accent, this.soft);

  final Color accent;
  final Color soft;
}

_StatusStyle _statusStyle(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _StatusStyle(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return const _StatusStyle(
        Color(0xFFE45252),
        Color(0xFFFFF1F1),
      );
    case 'withdrawn':
      return const _StatusStyle(AppColors.grey, Color(0xFFF1F4F7));
    default:
      return const _StatusStyle(AppColors.orange, AppColors.orangeBg);
  }
}

String _titleCase(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return 'Pending';
  return '${clean[0].toUpperCase()}${clean.substring(1).toLowerCase()}';
}

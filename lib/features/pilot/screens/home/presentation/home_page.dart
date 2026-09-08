import 'package:flutter/material.dart';

import 'package:tototl_app/core/network/api_client.dart';
  import '../../../../../core/theme/app_colors.dart';
import '../../../controllers/pilot_dashboard_controller.dart';
import '../../../services/pilot_dashboard_service.dart';
import '../../applications/applications_screen.dart';
import '../../jobs/find_drone_jobs.dart';
import '../widgets/home_header.dart';
import '../widgets/job_card.dart';
import '../widgets/my_drone_card.dart';

// ============================================================================
// PILOT HOME SCREEN
// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pageAnimationController;
  late final PilotDashboardController _dashboardController;

  @override
  void initState() {
    super.initState();

    _dashboardController = PilotDashboardController(
      PilotDashboardService(
        ApiClient(),
      ),
    );

    _dashboardController.load();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1050,
      ),
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // PAGE ENTRANCE
  // ==========================================================================

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start =
    (index * 0.07)
        .clamp(
      0.0,
      0.68,
    )
        .toDouble();

    final end =
    (start + 0.34)
        .clamp(
      0.0,
      1.0,
    )
        .toDouble();

    final animation = CurvedAnimation(
      parent: _pageAnimationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(
            0,
            0.045,
          ),
          end: Offset.zero,
        ).animate(
          animation,
        ),
        child: child,
      ),
    );
  }

  // ==========================================================================
  // AVAILABILITY POPUP
  // ==========================================================================

  Future<List<AvailabilitySlot>?> _showAvailabilityDialog() {
    return showGeneralDialog<List<AvailabilitySlot>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Availability',
      barrierColor: Colors.black.withOpacity(
        0.30,
      ),
      transitionDuration: const Duration(
        milliseconds: 300,
      ),
      pageBuilder: (
          context,
          animation,
          secondaryAnimation,
          ) {
        return const AvailabilityPickerDialog();
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1,
            ).animate(
              curved,
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ==================================================================
          // TOP PREMIUM BACKGROUND
          // ==================================================================

          Positioned(
            top: -180,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(
                        0.12,
                      ),
                      AppColors.blue.withOpacity(
                        0.025,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 70,
            left: -135,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF16C6C7,
                      ).withOpacity(
                        0.055,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==================================================================
          // SECOND SOFT GLOW
          // ==================================================================

          Positioned(
            top: 620,
            right: -180,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(
                        0.035,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==================================================================
          // CONTENT
          // ==================================================================

          SafeArea(
            child: AnimatedBuilder(
              animation: _dashboardController,
              builder: (
                  context,
                  _,
                  ) {
                return RefreshIndicator(
                  color: AppColors.blue,
                  backgroundColor: Colors.white,
                  onRefresh: _dashboardController.refresh,
                  child: SingleChildScrollView(
                    physics:
                    const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                    padding:
                    const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      115,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                        const BoxConstraints(
                          maxWidth: 620,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // ==================================================
                            // HERO HEADER
                            // ==================================================

                            _animatedEntry(
                              index: 0,
                              child:
                              _buildPremiumHeroHeader(),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            _animatedEntry(
                              index: 1,
                              child: _PilotDashboardOverview(
                                controller: _dashboardController,
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            // ==================================================
                            // DRONE CARD
                            // ==================================================

                            _animatedEntry(
                              index: 2,
                              child: Transform.translate(
                                offset: const Offset(
                                  0,
                                  -2,
                                ),
                                child:
                                const MyDroneCard(),
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ==================================================
                            // RECOMMENDED JOBS
                            // ==================================================

                            _animatedEntry(
                              index: 3,
                              child:
                              _SectionHeader(
                                title:
                                'Latest Jobs',
                                icon: Icons
                                    .work_outline_rounded,
                                onSeeAll: () {
                                  Navigator.of(
                                    context,
                                  ).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const FindDroneJobsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                              height: 13,
                            ),

                            _LatestDashboardJob(
                              controller: _dashboardController,
                              onRetry: _dashboardController.load,
                              animatedEntry: (child) => _animatedEntry(
                                index: 4,
                                child: child,
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ==================================================
                            // AVAILABILITY
                            // ==================================================

                            _animatedEntry(
                              index: 4,
                              child:
                              const _SectionHeader(
                                title:
                                'My Availability',
                                icon: Icons
                                    .event_available_outlined,
                              ),
                            ),

                            const SizedBox(
                              height: 13,
                            ),

                            _animatedEntry(
                              index: 5,
                              child:
                              _AvailabilityLauncher(
                                onTap:
                                _showAvailabilityDialog,
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ==================================================
                            // APPLICATIONS
                            // ==================================================

                            _animatedEntry(
                              index: 6,
                              child:
                              _SectionHeader(
                                title:
                                'My Applications',
                                icon: Icons
                                    .assignment_outlined,
                                onSeeAll: () {
                                  Navigator.of(
                                    context,
                                  ).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const ApplicationsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                              height: 13,
                            ),

                            _animatedEntry(
                              index: 7,
                              child:
                              const ApplicationsScreen(
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PREMIUM HEADER
  // ==========================================================================

  Widget _buildPremiumHeroHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ================================================================
        // SMALL DECORATIVE GLOW
        // ================================================================


        Positioned(
          top: -45,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withOpacity(
                      0.09,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ================================================================
        // HEADER CONTENT
        // ================================================================

        Padding(
          padding: const EdgeInsets.fromLTRB(
            1,
            5,
            1,
            13,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const HomeHeader(),

              const SizedBox(
                height: 17,
              ),

              // ============================================================
              // PREMIUM ACCENT
              // ============================================================

              Row(
                children: [
                  Container(
                    width: 33,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient:
                      const LinearGradient(
                        colors: [
                          Color(
                            0xFF16C6C7,
                          ),
                          Color(
                            0xFF087E9C,
                          ),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Container(
                    width: 8,
                    height: 3,
                    decoration: BoxDecoration(
                      color:
                      AppColors.blue.withOpacity(
                        0.20,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
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

// ============================================================================
// PILOT DASHBOARD OVERVIEW
// ============================================================================

class _PilotDashboardOverview extends StatelessWidget {
  const _PilotDashboardOverview({
    required this.controller,
  });

  final PilotDashboardController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.dashboard == null) {
      return const _DashboardOverviewSkeleton();
    }

    if (controller.dashboard == null) {
      return _DashboardOverviewError(
        message: controller.errorMessage ?? 'Unable to load dashboard.',
        onRetry: controller.load,
      );
    }

    final dashboard = controller.dashboard!;
    final counts = dashboard.applicationsByStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071D39),
            Color(0xFF0A526C),
            Color(0xFF0FA6B4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087E9C).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Live overview from your pilot dashboard',
                      style: TextStyle(
                        color: Color(0xFFCDE7EC),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Color(0xFF72E5C2),
                      size: 7,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _DashboardMetric(
                  value: '${counts.pending}',
                  label: 'Pending',
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _DashboardMetric(
                  value: '${counts.accepted}',
                  label: 'Accepted',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _DashboardMetric(
                  value: '${dashboard.dronesCount}',
                  label: 'Drones',
                  icon: Icons.flight_takeoff_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniDashboardStatus(
                icon: Icons.cancel_outlined,
                label: 'Rejected',
                value: counts.rejected,
              ),
              const SizedBox(width: 8),
              _MiniDashboardStatus(
                icon: Icons.undo_rounded,
                label: 'Withdrawn',
                value: counts.withdrawn,
              ),
              const Spacer(),
              Text(
                '${dashboard.recentPublishedJobs.length} recent jobs',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 9, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFA7F1EF),
            size: 17,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 9.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDashboardStatus extends StatelessWidget {
  const _MiniDashboardStatus({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.72),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 8.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardOverviewSkeleton extends StatelessWidget {
  const _DashboardOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 196,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F5),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _DashboardOverviewError extends StatelessWidget {
  const _DashboardOverviewError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LATEST JOB FROM DASHBOARD
// ============================================================================

class _LatestDashboardJob extends StatelessWidget {
  const _LatestDashboardJob({
    required this.controller,
    required this.onRetry,
    required this.animatedEntry,
  });

  final PilotDashboardController controller;
  final VoidCallback onRetry;
  final Widget Function(Widget child) animatedEntry;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.dashboard == null) {
      return const _RecommendedJobShimmer();
    }

    final dashboard = controller.dashboard;

    if (dashboard == null) {
      return _RecommendedJobsStateCard(
        message: controller.errorMessage ?? 'Unable to load recent jobs.',
        showRetry: true,
        onRetry: onRetry,
      );
    }

    if (dashboard.recentPublishedJobs.isEmpty) {
      return _RecommendedJobsStateCard(
        message: 'No published jobs available right now.',
        showRetry: false,
        onRetry: onRetry,
      );
    }

    return animatedEntry(
      JobCard(
        job: dashboard.recentPublishedJobs.first,
      ),
    );
  }
}

// ============================================================================
// RECOMMENDED JOB STATES
// ============================================================================

class _RecommendedJobsStateCard extends StatelessWidget {
  const _RecommendedJobsStateCard({
    required this.message,
    required this.showRetry,
    required this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.028),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              showRetry
                  ? Icons.cloud_off_rounded
                  : Icons.work_outline_rounded,
              color: AppColors.blue,
              size: 21,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 9),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
              ),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendedJobShimmer extends StatefulWidget {
  const _RecommendedJobShimmer();

  @override
  State<_RecommendedJobShimmer> createState() =>
      _RecommendedJobShimmerState();
}

class _RecommendedJobShimmerState extends State<_RecommendedJobShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        Widget box({
          required double width,
          required double height,
          required double radius,
        }) {
          return Container(
            width: width,
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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  box(
                    width: 44,
                    height: 44,
                    radius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(
                          width: 120,
                          height: 10,
                          radius: 6,
                        ),
                        const SizedBox(height: 8),
                        box(
                          width: double.infinity,
                          height: 13,
                          radius: 7,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              box(
                width: double.infinity,
                height: 11,
                radius: 6,
              ),
              const SizedBox(height: 14),
              const Divider(
                height: 1,
                color: AppColors.cardBorder,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  box(
                    width: 105,
                    height: 28,
                    radius: 10,
                  ),
                  const Spacer(),
                  box(
                    width: 74,
                    height: 22,
                    radius: 9,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(
              0.075,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.blue,
            size: 16.5,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.2,
            ),
          ),
        ),

        if (onSeeAll != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(
                20,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      width: 3,
                    ),

                    Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      size: 9,
                      color:
                      AppColors.blue.withOpacity(
                        0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// AVAILABILITY LAUNCHER
// ============================================================================

class _AvailabilityLauncher extends StatefulWidget {
  const _AvailabilityLauncher({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_AvailabilityLauncher> createState() =>
      _AvailabilityLauncherState();
}

class _AvailabilityLauncherState
    extends State<_AvailabilityLauncher> {
  bool _isPressed = false;

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnimatedScale(
      duration: const Duration(
        milliseconds: 120,
      ),
      scale:
      _isPressed
          ? 0.985
          : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            20,
          ),
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() {
              _isPressed = true;
            });
          },
          onTapUp: (_) {
            setState(() {
              _isPressed = false;
            });
          },
          onTapCancel: () {
            setState(() {
              _isPressed = false;
            });
          },
          child: Ink(
            padding: const EdgeInsets.all(
              15,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color:
                AppColors.cardBorder.withOpacity(
                  0.9,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  AppColors.navy.withOpacity(
                    0.035,
                  ),
                  blurRadius: 16,
                  offset: const Offset(
                    0,
                    6,
                  ),
                ),
              ],
            ),
            child: Row(
              children: [
                // =========================================================
                // ICON
                // =========================================================

                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient:
                    const LinearGradient(
                      begin: Alignment.topLeft,
                      end:
                      Alignment.bottomRight,
                      colors: [
                        Color(
                          0xFF16C6C7,
                        ),
                        Color(
                          0xFF087E9C,
                        ),
                      ],
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        AppColors.blue.withOpacity(
                          0.20,
                        ),
                        blurRadius: 12,
                        offset: const Offset(
                          0,
                          4,
                        ),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .event_available_rounded,
                    size: 23,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                // =========================================================
                // TEXT
                // =========================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Your Availability',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AppColors.navy,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        "Tap to pick the dates and times you're free",
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color:
                          AppColors.grey.withOpacity(
                            0.88,
                          ),
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                    AppColors.blue.withOpacity(
                      0.065,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AVAILABILITY SLOT MODEL
// ============================================================================

class AvailabilitySlot {
  AvailabilitySlot({
    required this.date,
    required this.start,
    required this.end,
  });

  final DateTime date;

  TimeOfDay start;

  TimeOfDay end;
}

// ============================================================================
// AVAILABILITY PICKER
// ============================================================================

class AvailabilityPickerDialog extends StatefulWidget {
  const AvailabilityPickerDialog({
    super.key,
    this.initialSlots,
  });

  final List<AvailabilitySlot>? initialSlots;

  @override
  State<AvailabilityPickerDialog> createState() =>
      _AvailabilityPickerDialogState();
}

class _AvailabilityPickerDialogState
    extends State<AvailabilityPickerDialog> {
  late DateTime _visibleMonth;

  final Map<DateTime, AvailabilitySlot> _slots = {};

  static const List<String> _weekdayLabels = [
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  static const List<String> _monthLabels = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _visibleMonth = DateTime(
      now.year,
      now.month,
    );

    final initial =
        widget.initialSlots;

    if (initial != null) {
      for (final slot in initial) {
        _slots[
        _dateKey(
          slot.date,
        )] = slot;
      }
    }
  }

  // ==========================================================================
  // DATE
  // ==========================================================================

  DateTime _dateKey(
      DateTime date,
      ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  List<DateTime?> _buildMonthGrid() {
    final firstOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final leadingEmpty =
        firstOfMonth.weekday % 7;

    final cells =
    <DateTime?>[];

    for (
    int i = 0;
    i < leadingEmpty;
    i++
    ) {
      cells.add(
        null,
      );
    }

    for (
    int day = 1;
    day <= daysInMonth;
    day++
    ) {
      cells.add(
        DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          day,
        ),
      );
    }

    while (
    cells.length % 7 !=
        0) {
      cells.add(
        null,
      );
    }

    return cells;
  }

  // ==========================================================================
  // TOGGLE DATE
  // ==========================================================================

  void _toggleDate(
      DateTime date,
      ) {
    final key =
    _dateKey(
      date,
    );

    setState(() {
      if (_slots.containsKey(
        key,
      )) {
        _slots.remove(
          key,
        );
      } else {
        _slots[key] =
            AvailabilitySlot(
              date: key,
              start:
              const TimeOfDay(
                hour: 9,
                minute: 0,
              ),
              end:
              const TimeOfDay(
                hour: 12,
                minute: 0,
              ),
            );
      }
    });
  }

  // ==========================================================================
  // TIME
  // ==========================================================================

  Future<void> _pickTime(
      AvailabilitySlot slot, {
        required bool isStart,
      }) async {
    final picked =
    await showTimePicker(
      context: context,
      initialTime:
      isStart
          ? slot.start
          : slot.end,
      builder: (
          context,
          child,
          ) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(
            colorScheme:
            const ColorScheme.light(
              primary:
              AppColors.blue,
              onPrimary:
              Colors.white,
              onSurface:
              AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked ==
        null) {
      return;
    }

    setState(() {
      if (isStart) {
        slot.start =
            picked;
      } else {
        slot.end =
            picked;
      }
    });
  }

  // ==========================================================================
  // FORMATTERS
  // ==========================================================================

  String _formatTime(
      TimeOfDay time,
      ) {
    final hour =
    time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
    time.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    final period =
    time.period ==
        DayPeriod.am
        ? 'AM'
        : 'PM';

    return '$hour:$minute $period';
  }

  String _formatDate(
      DateTime date,
      ) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${_monthLabels[date.month - 1].substring(0, 3)}-'
        '${date.year}';
  }

  // ==========================================================================
  // MONTH NAVIGATION
  // ==========================================================================

  void _previousMonth() {
    setState(() {
      _visibleMonth =
          DateTime(
            _visibleMonth.year,
            _visibleMonth.month - 1,
          );
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth =
          DateTime(
            _visibleMonth.year,
            _visibleMonth.month + 1,
          );
    });
  }

  // ==========================================================================
  // BUILD DIALOG
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final screen =
        MediaQuery.of(context).size;

    final cells =
    _buildMonthGrid();

    final sortedSlots =
    _slots.values.toList()
      ..sort(
            (
            first,
            second,
            ) =>
            first.date.compareTo(
              second.date,
            ),
      );

    final today =
    _dateKey(
      DateTime.now(),
    );

    return Dialog(
      elevation: 0,
      backgroundColor:
      Colors.transparent,
      insetPadding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 25,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 410,
          maxHeight:
          screen.height * 0.88,
        ),
        child: Container(
          clipBehavior:
          Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              26,
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(
                  0.14,
                ),
                blurRadius: 38,
                offset: const Offset(
                  0,
                  16,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              // ============================================================
              // HEADER
              // ============================================================

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.fromLTRB(
                  19,
                  17,
                  13,
                  16,
                ),
                decoration:
                const BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topLeft,
                    end:
                    Alignment.bottomRight,
                    colors: [
                      Color(
                        0xFF0C819B,
                      ),
                      Color(
                        0xFF18BDBB,
                      ),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.14,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .event_available_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(
                      width: 11,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Your Availability',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),

                          SizedBox(
                            height: 3,
                          ),

                          Text(
                            'Pick dates, then set the time for each',
                            style:
                            TextStyle(
                              color:
                              Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                      style:
                      IconButton.styleFrom(
                        backgroundColor:
                        Colors.white.withOpacity(
                          0.11,
                        ),
                      ),
                      icon:
                      const Icon(
                        Icons.close_rounded,
                        color:
                        Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // ============================================================
              // CONTENT
              // ============================================================

              Flexible(
                child:
                SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // ====================================================
                      // MONTH NAVIGATION
                      // ====================================================

                      Row(
                        children: [
                          _CalendarNavButton(
                            icon: Icons
                                .chevron_left_rounded,
                            onTap:
                            _previousMonth,
                          ),

                          Expanded(
                            child: Center(
                              child:
                              AnimatedSwitcher(
                                duration:
                                const Duration(
                                  milliseconds:
                                  180,
                                ),
                                child: Text(
                                  '${_monthLabels[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                                  key:
                                  ValueKey(
                                    '${_visibleMonth.year}-${_visibleMonth.month}',
                                  ),
                                  style:
                                  const TextStyle(
                                    color:
                                    AppColors.navy,
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          _CalendarNavButton(
                            icon: Icons
                                .chevron_right_rounded,
                            onTap:
                            _nextMonth,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ====================================================
                      // WEEKDAYS
                      // ====================================================

                      Row(
                        children:
                        _weekdayLabels
                            .map(
                              (
                              label,
                              ) =>
                              Expanded(
                                child: Center(
                                  child: Text(
                                    label,
                                    style:
                                    TextStyle(
                                      color:
                                      AppColors.grey.withOpacity(
                                        0.72,
                                      ),
                                      fontSize: 10.5,
                                      fontWeight:
                                      FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                        )
                            .toList(),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      // ====================================================
                      // CALENDAR
                      // ====================================================

                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount:
                        cells.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final date =
                          cells[index];

                          if (date ==
                              null) {
                            return const SizedBox.shrink();
                          }

                          final key =
                          _dateKey(
                            date,
                          );

                          final selected =
                          _slots.containsKey(
                            key,
                          );

                          final isPast =
                          key.isBefore(
                            today,
                          );

                          final isToday =
                              key ==
                                  today;

                          return InkWell(
                            borderRadius:
                            BorderRadius.circular(
                              11,
                            ),
                            onTap:
                            isPast
                                ? null
                                : () {
                              _toggleDate(
                                date,
                              );
                            },
                            child:
                            AnimatedContainer(
                              duration:
                              const Duration(
                                milliseconds:
                                170,
                              ),
                              curve:
                              Curves.easeOutCubic,
                              margin:
                              const EdgeInsets.all(
                                2,
                              ),
                              alignment:
                              Alignment.center,
                              decoration:
                              BoxDecoration(
                                gradient:
                                selected
                                    ? const LinearGradient(
                                  begin:
                                  Alignment.topLeft,
                                  end:
                                  Alignment.bottomRight,
                                  colors: [
                                    Color(
                                      0xFF16C6C7,
                                    ),
                                    Color(
                                      0xFF087E9C,
                                    ),
                                  ],
                                )
                                    : null,
                                color:
                                selected
                                    ? null
                                    : isToday
                                    ? AppColors.blue
                                    .withOpacity(
                                  0.05,
                                )
                                    : Colors.transparent,
                                borderRadius:
                                BorderRadius.circular(
                                  10,
                                ),
                                border:
                                isToday &&
                                    !selected
                                    ? Border.all(
                                  color:
                                  AppColors.blue.withOpacity(
                                    0.55,
                                  ),
                                )
                                    : null,
                              ),
                              child: Text(
                                '${date.day}',
                                style:
                                TextStyle(
                                  fontSize: 12.5,
                                  fontWeight:
                                  FontWeight.w700,
                                  color:
                                  selected
                                      ? Colors.white
                                      : isPast
                                      ? AppColors.grey.withOpacity(
                                    0.32,
                                  )
                                      : AppColors.navy,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(
                        height: 21,
                      ),

                      // ====================================================
                      // SELECTED DATES TITLE
                      // ====================================================

                      Row(
                        children: [
                          Container(
                            width: 31,
                            height: 31,
                            decoration:
                            BoxDecoration(
                              color:
                              AppColors.blue.withOpacity(
                                0.07,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                9,
                              ),
                            ),
                            child:
                            const Icon(
                              Icons.schedule_rounded,
                              color:
                              AppColors.blue,
                              size: 15,
                            ),
                          ),

                          const SizedBox(
                            width: 9,
                          ),

                          const Text(
                            'Selected Dates and Times',
                            style:
                            TextStyle(
                              color:
                              AppColors.navy,
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 11,
                      ),

                      // ====================================================
                      // EMPTY
                      // ====================================================

                      if (sortedSlots.isEmpty)
                        Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 18,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            AppColors.bg,
                            borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                            border: Border.all(
                              color:
                              AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            'Tap dates above to add availability',
                            textAlign:
                            TextAlign.center,
                            style:
                            TextStyle(
                              color:
                              AppColors.grey.withOpacity(
                                0.82,
                              ),
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        ...sortedSlots.map(
                              (
                              slot,
                              ) =>
                              _SelectedAvailabilitySlot(
                                slot: slot,
                                dateText:
                                _formatDate(
                                  slot.date,
                                ),
                                startText:
                                _formatTime(
                                  slot.start,
                                ),
                                endText:
                                _formatTime(
                                  slot.end,
                                ),
                                onStartTap: () {
                                  _pickTime(
                                    slot,
                                    isStart: true,
                                  );
                                },
                                onEndTap: () {
                                  _pickTime(
                                    slot,
                                    isStart: false,
                                  );
                                },
                                onRemove: () {
                                  setState(() {
                                    _slots.remove(
                                      _dateKey(
                                        slot.date,
                                      ),
                                    );
                                  });
                                },
                              ),
                        ),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // ACTIONS
              // ============================================================

              Container(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  11,
                  18,
                  17,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color:
                      AppColors.cardBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop();
                        },
                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          AppColors.grey,
                          side: BorderSide(
                            color:
                            AppColors.cardBorder,
                          ),
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              13,
                            ),
                          ),
                        ),
                        child:
                        const Text(
                          'Cancel',
                          style:
                          TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Container(
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(
                            13,
                          ),
                          gradient:
                          const LinearGradient(
                            colors: [
                              Color(
                                0xFF16C6C7,
                              ),
                              Color(
                                0xFF087E9C,
                              ),
                            ],
                          ),
                        ),
                        child:
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop(
                              sortedSlots,
                            );
                          },
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.transparent,
                            shadowColor:
                            Colors.transparent,
                            foregroundColor:
                            Colors.white,
                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                13,
                              ),
                            ),
                          ),
                          child:
                          const Text(
                            'Ok',
                            style:
                            TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
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

// ============================================================================
// CALENDAR NAV
// ============================================================================

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;

  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      AppColors.blue.withOpacity(
        0.055,
      ),
      borderRadius:
      BorderRadius.circular(
        10,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          10,
        ),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            color:
            AppColors.blue,
            size: 19,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SELECTED SLOT
// ============================================================================

class _SelectedAvailabilitySlot extends StatelessWidget {
  const _SelectedAvailabilitySlot({
    required this.slot,
    required this.dateText,
    required this.startText,
    required this.endText,
    required this.onStartTap,
    required this.onEndTap,
    required this.onRemove,
  });

  final AvailabilitySlot slot;

  final String dateText;

  final String startText;

  final String endText;

  final VoidCallback onStartTap;

  final VoidCallback onEndTap;

  final VoidCallback onRemove;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.all(
        11,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                  AppColors.blue.withOpacity(
                    0.07,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    9,
                  ),
                ),
                child: const Icon(
                  Icons
                      .calendar_today_rounded,
                  color:
                  AppColors.blue,
                  size: 14,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  dateText,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    AppColors.navy,
                    fontSize: 12.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              InkWell(
                onTap: onRemove,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                child: const Padding(
                  padding:
                  EdgeInsets.all(
                    5,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color:
                    AppColors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 9,
          ),

          Row(
            children: [
              Expanded(
                child: _TimeChip(
                  text:
                  startText,
                  onTap:
                  onStartTap,
                ),
              ),

              const Padding(
                padding:
                EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                child: Text(
                  '—',
                  style:
                  TextStyle(
                    color:
                    AppColors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

              Expanded(
                child: _TimeChip(
                  text:
                  endText,
                  onTap:
                  onEndTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TIME CHIP
// ============================================================================

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.text,
    required this.onTap,
  });

  final String text;

  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      AppColors.blue.withOpacity(
        0.055,
      ),
      borderRadius:
      BorderRadius.circular(
        10,
      ),
      child: InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons
                    .schedule_rounded,
                size: 13,
                color:
                AppColors.blue,
              ),

              const SizedBox(
                width: 4,
              ),

              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    AppColors.blue,
                    fontSize: 10.5,
                    fontWeight:
                    FontWeight.w700,
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

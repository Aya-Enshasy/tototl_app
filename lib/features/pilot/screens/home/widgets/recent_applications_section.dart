import 'package:flutter/material.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/pilot/models/pilot_home_snapshot.dart';

class RecentApplicationsSection extends StatelessWidget {
  const RecentApplicationsSection({
    super.key,
    required this.applications,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.onSeeAll,
    required this.onExploreJobs,
    required this.onOpenApplication,
  });

  final List<PilotHomeApplicationItem> applications;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onSeeAll;
  final VoidCallback onExploreJobs;
  final ValueChanged<PilotHomeApplicationItem> onOpenApplication;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          count: applications.length,
          onSeeAll: onSeeAll,
        ),
        const SizedBox(height: 12),
        if (loading && applications.isEmpty)
          const _ApplicationsShimmer()
        else if (errorMessage != null && applications.isEmpty)
          _ApplicationsError(
            message: errorMessage!,
            onRetry: onRetry,
          )
        else if (applications.isEmpty)
          _EmptyApplications(onExploreJobs: onExploreJobs)
        else
          ...applications.take(3).map(
                (application) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ApplicationCard(
                    application: application,
                    onTap: () => onOpenApplication(application),
                  ),
                ),
              ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.onSeeAll,
  });

  final int count;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5A8).withOpacity(0.07),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: AppColors.logoTurquoiseDark,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Applications',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your latest job activity',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (count > 0)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.blue,
                      size: 9,
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

class _ApplicationCard extends StatefulWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
  });

  final PilotHomeApplicationItem application;
  final VoidCallback onTap;

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final application = widget.application;
    final visual = _statusVisual(application.status);

    return AnimatedScale(
      scale: _pressed ? 0.987 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.037),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    visual.icon,
                    color: visual.color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              application.jobTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13.8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: visual.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              application.statusLabel,
                              style: TextStyle(
                                color: visual.color,
                                fontSize: 9.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (application.company.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                application.company,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else
                            const Text(
                              'Company',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 10.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (application.location.isNotEmpty) ...[
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 7),
                              decoration: const BoxDecoration(
                                color: AppColors.lightGrey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                application.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 10.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppColors.grey.withOpacity(0.82),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            application.submittedLabel,
                            style: TextStyle(
                              color: AppColors.grey.withOpacity(0.86),
                              fontSize: 9.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.045),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.blue,
                    size: 18,
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


class _ApplicationsError extends StatelessWidget {
  const _ApplicationsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications({required this.onExploreJobs});

  final VoidCallback onExploreJobs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFFE1FAFA), Color(0xFFF8FBFC)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF13B6BC).withOpacity(0.08),
                  ),
                ),
              ),
              const Icon(
                Icons.flight_takeoff_rounded,
                color: AppColors.logoTurquoiseDark,
                size: 28,
              ),
              Positioned(
                right: -5,
                bottom: 6,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 14,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'No applications yet',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Explore published missions and send your first application when the right job appears.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey.withOpacity(0.9),
              fontSize: 10.8,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: onExploreJobs,
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.explore_outlined, size: 16),
            label: const Text(
              'Explore jobs',
              style: TextStyle(
                fontSize: 11.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsShimmer extends StatefulWidget {
  const _ApplicationsShimmer();

  @override
  State<_ApplicationsShimmer> createState() => _ApplicationsShimmerState();
}

class _ApplicationsShimmerState extends State<_ApplicationsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
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

        Widget glow({
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
                begin: Alignment(-1.8 + (3.6 * t), 0),
                end: Alignment(-0.8 + (3.6 * t), 0),
                colors: const [
                  Color(0xFFF0F5F6),
                  Color(0xFFFBFDFD),
                  Color(0xFFE8F1F4),
                  Color(0xFFFBFDFD),
                  Color(0xFFF0F5F6),
                ],
              ),
            ),
          );
        }

        Widget row() {
          return Container(
            height: 86,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                glow(width: 47, height: 47, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(child: glow(width: 145, height: 13, radius: 7)),
                          const SizedBox(width: 10),
                          glow(width: 56, height: 19, radius: 10),
                        ],
                      ),
                      const SizedBox(height: 9),
                      glow(width: 150, height: 9, radius: 5),
                      const SizedBox(height: 8),
                      glow(width: 86, height: 8, radius: 5),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            row(),
            const SizedBox(height: 9),
            row(),
            const SizedBox(height: 9),
            row(),
          ],
        );
      },
    );
  }
}

_StatusVisual _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return _StatusVisual(
        color: AppColors.green,
        background: AppColors.green.withOpacity(0.085),
        icon: Icons.verified_outlined,
      );
    case 'rejected':
      return _StatusVisual(
        color: AppColors.red,
        background: AppColors.red.withOpacity(0.075),
        icon: Icons.close_rounded,
      );
    case 'withdrawn':
      return _StatusVisual(
        color: AppColors.grey,
        background: AppColors.grey.withOpacity(0.075),
        icon: Icons.undo_rounded,
      );
    default:
      return _StatusVisual(
        color: AppColors.orange,
        background: AppColors.orange.withOpacity(0.085),
        icon: Icons.schedule_rounded,
      );
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.color,
    required this.background,
    required this.icon,
  });

  final Color color;
  final Color background;
  final IconData icon;
}

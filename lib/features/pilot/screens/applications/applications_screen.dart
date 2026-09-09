import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import '../../controllers/pilot_application_controller.dart';
import '../../models/pilot_application_model.dart';
import '../../services/pilot_application_service.dart';
import '../../services/pilot_job_service.dart';
import 'application_details_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  late final PilotApplicationController _controller;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();

    _controller = PilotApplicationController(
      PilotApplicationService(apiClient),
      jobService: PilotJobService(apiClient),
    );

    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();

    final success = await _controller.refresh();

    if (!mounted || success) return;

    final message = _controller.refreshErrorMessage;
    if (message == null || message.trim().isEmpty) return;

    _snack(message);
  }

  Future<void> _openDetails(PilotApplicationModel application) async {
    HapticFeedback.selectionClick();

    // Start the authoritative detail request before the route transition.
    // No list/cache snapshot is ever painted as detail data.
    final detailsFuture =
    _controller.service.getApplicationDetailsResult(application.id);

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ApplicationDetailsScreen(
          applicationId: application.id,
          detailsFuture: detailsFuture,
        ),
      ),
    );

    if (!mounted) return;

    // Only a real mutation deserves a refresh. We deliberately do not read a
    // cached detail snapshot here because that can reintroduce a stale flash.
    if (changed == true) {
      await _refresh();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return widget.compact ? _compact() : _fullScreen();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // COMPACT / HOME VERSION
  // ---------------------------------------------------------------------------

  Widget _compact() {
    final applications = _controller.applications;

    if (_controller.isLoading && applications.isEmpty) {
      return const _CompactApplicationsShimmer();
    }

    if (_controller.errorMessage != null && applications.isEmpty) {
      return _CompactMessage(
        icon: Icons.cloud_off_rounded,
        text: _controller.errorMessage!,
        actionLabel: 'Retry',
        onAction: _controller.load,
      );
    }

    if (applications.isEmpty) {
      return const _CompactMessage(
        icon: Icons.assignment_turned_in_outlined,
        text: 'No applications yet.',
      );
    }

    return Stack(
      children: [
        Column(
          children: applications
              .take(2)
              .map(
                (application) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ApplicationCard(
                application: application,
                compact: true,
                onTap: () => _openDetails(application),
              ),
            ),
          )
              .toList(),
        ),
        if (_controller.isRefreshing)
          const Positioned(
            top: 8,
            right: 8,
            child: _LiveRefreshBadge(compact: true),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FULL SCREEN
  // ---------------------------------------------------------------------------

  Widget _fullScreen() {
    final firstLoad =
        _controller.isLoading && _controller.applications.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ApplicationsBackdrop(),
          SafeArea(
            child: firstLoad
                ? const _ApplicationsPageShimmer()
                : Column(
              children: [
                _Header(
                  total: _controller.totalCount,
                  pending: _controller.pendingCount,
                  accepted: _controller.acceptedCount,
                  rejected: _controller.rejectedCount,
                  refreshing: _controller.isRefreshing,
                  onRefresh: _controller.isRefreshing ? null : _refresh,
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final applications = _controller.applications;

    if (_controller.errorMessage != null && applications.isEmpty) {
      return _FullMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load applications',
        text: _controller.errorMessage!,
        actionLabel: 'Try Again',
        onAction: _controller.load,
      );
    }

    if (applications.isEmpty) {
      return const _EmptyApplications();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final application = applications[index];

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index.clamp(0, 5) * 55).toInt()),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _ApplicationCard(
            application: application,
            onTap: () => _openDetails(application),
          ),
        );
      },
    );
  }
}

// =============================================================================
// BACKDROP
// =============================================================================

class _ApplicationsBackdrop extends StatelessWidget {
  const _ApplicationsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -175,
              right: -125,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF16C6C7).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 320,
              left: -160,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(0.055),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.rejected,
    required this.refreshing,
    required this.onRefresh,
  });

  final int total;
  final int pending;
  final int accepted;
  final int rejected;
  final bool refreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE7FAFA),
                      Color(0xFFF2F7FB),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.logoTurquoiseDark.withOpacity(0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.035),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.logoTurquoiseDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(height: 3),
                    Text(
                      'Mission Pipeline',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.55,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track every application and decision.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              refreshing
                  ? const _LiveRefreshBadge(compact: true)
                  : _RefreshButton(onTap: onRefresh),
            ],
          ),
          const SizedBox(height: 13),
          _PipelineHero(
            total: total,
            pending: pending,
            accepted: accepted,
            rejected: rejected,
          ),
        ],
      ),
    );
  }
}

class _PipelineHero extends StatelessWidget {
  const _PipelineHero({
    required this.total,
    required this.pending,
    required this.accepted,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int accepted;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071B2D),
            Color(0xFF0A3F54),
            Color(0xFF087C84),
          ],
          stops: [0, 0.62, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF063B4A).withOpacity(0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -58,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.055),
                  width: 19,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: -38,
            child: Icon(
              Icons.flight_takeoff_rounded,
              color: Colors.white.withOpacity(0.035),
              size: 128,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.09),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 12,
                            color: Color(0xFF73E1DD),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE PIPELINE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$total total',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        value: '$pending',
                        label: 'Pending',
                        icon: Icons.schedule_rounded,
                        tint: const Color(0xFFFFCC72),
                      ),
                    ),
                    const _HeroDivider(),
                    Expanded(
                      child: _HeroMetric(
                        value: '$accepted',
                        label: 'Accepted',
                        icon: Icons.verified_rounded,
                        tint: const Color(0xFF7DE2B2),
                      ),
                    ),
                    const _HeroDivider(),
                    Expanded(
                      child: _HeroMetric(
                        value: '$rejected',
                        label: 'Rejected',
                        icon: Icons.cancel_outlined,
                        tint: const Color(0xFFFFA0A0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    required this.tint,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: tint, size: 15.5),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17.5,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.61),
            fontSize: 8.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 45,
      color: Colors.white.withOpacity(0.10),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.035),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.refresh_rounded,
            color: AppColors.navy,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _LiveRefreshBadge extends StatelessWidget {
  const _LiveRefreshBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FAFA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.logoTurquoiseDark.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDots(),
          if (!compact) ...[
            const SizedBox(width: 7),
            const Text(
              'SYNCING',
              style: TextStyle(
                color: AppColors.logoTurquoiseDark,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + (index * 0.22)) % 1.0;
            final opacity = 0.28 + (0.72 * (1 - (phase - 0.5).abs() * 2));

            return Container(
              width: 4.5,
              height: 4.5,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 3),
              decoration: BoxDecoration(
                color: AppColors.logoTurquoiseDark.withOpacity(
                  opacity.clamp(0.28, 1.0).toDouble(),
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// =============================================================================
// APPLICATION CARD
// =============================================================================

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
    this.compact = false,
  });

  final PilotApplicationModel application;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(application.status);
    final job = application.job;

    final realTitle = job?.title.trim() ?? '';
    final title = realTitle.isNotEmpty
        ? realTitle
        : 'Mission #${application.jobPostingId}';

    final realCompany = job == null ? '' : application.companyLabel.trim();

    final rawLocation = job?.detailedLocationLabel.trim() ?? '';
    final location = rawLocation.toLowerCase() == 'not specified'
        ? ''
        : rawLocation;

    final pay = job?.payLabel.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 17 : 19),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFCFDFE),
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 17 : 19),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(compact ? 0.022 : 0.032),
                blurRadius: compact ? 10 : 15,
                offset: Offset(0, compact ? 3 : 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 17 : 19),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3.2,
                    decoration: BoxDecoration(
                      color: visual.foreground.withOpacity(0.82),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 13,
                    compact ? 11 : 12,
                    compact ? 10 : 11,
                    compact ? 11 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: compact ? 38 : 41,
                            height: compact ? 38 : 41,
                            decoration: BoxDecoration(
                              color: visual.background,
                              borderRadius: BorderRadius.circular(
                                compact ? 12 : 13,
                              ),
                              border: Border.all(
                                color: visual.foreground.withOpacity(0.09),
                              ),
                            ),
                            child: Icon(
                              visual.icon,
                              color: visual.foreground,
                              size: compact ? 18 : 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: compact ? 12.8 : 14,
                                          height: 1.1,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    _StatusPill(
                                      label: application.statusLabel,
                                      visual: visual,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetaLine(
                                        icon: realCompany.isNotEmpty
                                            ? Icons.business_outlined
                                            : Icons.tag_rounded,
                                        text: realCompany.isNotEmpty
                                            ? realCompany
                                            : 'Job #${application.jobPostingId}',
                                        compact: true,
                                        lighter: realCompany.isEmpty,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'APP #${application.id}',
                                      style: TextStyle(
                                        color: AppColors.lightGrey.withOpacity(0.95),
                                        fontSize: 7.8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: compact ? 25 : 27,
                            height: compact ? 25 : 27,
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 9),
                        Padding(
                          padding: const EdgeInsets.only(left: 1),
                          child: Row(
                            children: [
                              Expanded(
                                child: _InlineDetail(
                                  icon: Icons.schedule_rounded,
                                  text: application.submittedLabel,
                                ),
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(width: 11),
                                Expanded(
                                  child: _InlineDetail(
                                    icon: Icons.location_on_outlined,
                                    text: location,
                                  ),
                                ),
                              ] else if (pay.isNotEmpty) ...[
                                const SizedBox(width: 11),
                                Expanded(
                                  child: _InlineDetail(
                                    icon: Icons.payments_outlined,
                                    text: pay,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.visual,
    required this.compact,
  });

  final String label;
  final _StatusVisual visual;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3.5 : 4,
      ),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: visual.foreground.withOpacity(0.09),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4.5,
            height: 4.5,
            decoration: BoxDecoration(
              color: visual.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(
              color: visual.foreground,
              fontSize: compact ? 8.2 : 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.compact,
    this.lighter = false,
  });

  final IconData icon;
  final String text;
  final bool compact;
  final bool lighter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 10 : 11,
          color: AppColors.grey.withOpacity(lighter ? 0.50 : 0.78),
        ),
        const SizedBox(width: 4.5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.grey.withOpacity(lighter ? 0.64 : 0.92),
              fontSize: compact ? 9.2 : 9.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineDetail extends StatelessWidget {
  const _InlineDetail({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 11.5,
            color: AppColors.logoTurquoiseDark,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9.1,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusVisual {
  const _StatusVisual(
      this.foreground,
      this.background,
      this.icon,
      );

  final Color foreground;
  final Color background;
  final IconData icon;
}

_StatusVisual _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _StatusVisual(
        AppColors.green,
        AppColors.greenBg,
        Icons.verified_rounded,
      );
    case 'rejected':
      return const _StatusVisual(
        AppColors.red,
        AppColors.redBg,
        Icons.close_rounded,
      );
    case 'withdrawn':
      return _StatusVisual(
        AppColors.grey,
        Colors.grey.shade100,
        Icons.undo_rounded,
      );
    default:
      return const _StatusVisual(
        Color(0xFFE99A18),
        Color(0xFFFFF4E5),
        Icons.schedule_rounded,
      );
  }
}

// =============================================================================
// EMPTY / ERROR
// =============================================================================

class _CompactMessage extends StatelessWidget {
  const _CompactMessage({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: const BoxDecoration(
              color: AppColors.blueBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.blue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.8,
                height: 1.35,
              ),
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _FullMessage extends StatelessWidget {
  const _FullMessage({
    required this.icon,
    required this.title,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5FAFA), Color(0xFFF1F7FB)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(icon, color: AppColors.logoTurquoiseDark, size: 30),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.logoTurquoiseDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 19,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 70, 32, 120),
      children: [
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE5FAFA), Color(0xFFF1F6FB)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.send_time_extension_outlined,
              color: AppColors.logoTurquoiseDark,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 19),
        const Text(
          'Your mission pipeline starts here',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Once you apply to a published mission, its real application status will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PREMIUM SHIMMER — MATCHES THE REAL PAGE STRUCTURE
// =============================================================================

class _ApplicationsPageShimmer extends StatefulWidget {
  const _ApplicationsPageShimmer();

  @override
  State<_ApplicationsPageShimmer> createState() =>
      _ApplicationsPageShimmerState();
}

class _ApplicationsPageShimmerState extends State<_ApplicationsPageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ShimmerBlock(
                        animation: _controller,
                        width: 42,
                        height: 42,
                        radius: 13,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerBlock(
                              animation: _controller,
                              width: 78,
                              height: 8,
                              radius: 5,
                            ),
                            const SizedBox(height: 6),
                            _ShimmerBlock(
                              animation: _controller,
                              width: 156,
                              height: 20,
                              radius: 7,
                            ),
                            const SizedBox(height: 6),
                            _ShimmerBlock(
                              animation: _controller,
                              width: 190,
                              height: 9,
                              radius: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ShimmerBlock(
                        animation: _controller,
                        width: 40,
                        height: 40,
                        radius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  _HeroShimmer(animation: _controller),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (_, __) => _ApplicationCardShimmer(
                  animation: _controller,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroShimmer extends StatelessWidget {
  const _HeroShimmer({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3347),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(
                animation: animation,
                width: 95,
                height: 23,
                radius: 12,
                dark: true,
              ),
              const Spacer(),
              _ShimmerBlock(
                animation: animation,
                width: 48,
                height: 10,
                radius: 6,
                dark: true,
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 2 ? 0 : 16,
                  ),
                  child: Column(
                    children: [
                      _ShimmerBlock(
                        animation: animation,
                        width: 22,
                        height: 22,
                        radius: 11,
                        dark: true,
                      ),
                      const SizedBox(height: 7),
                      _ShimmerBlock(
                        animation: animation,
                        width: 34,
                        height: 17,
                        radius: 6,
                        dark: true,
                      ),
                      const SizedBox(height: 5),
                      _ShimmerBlock(
                        animation: animation,
                        width: 48,
                        height: 8,
                        radius: 5,
                        dark: true,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCardShimmer extends StatelessWidget {
  const _ApplicationCardShimmer({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(13, 12, 11, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ShimmerBlock(
                animation: animation,
                width: 41,
                height: 41,
                radius: 13,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ShimmerBlock(
                            animation: animation,
                            width: double.infinity,
                            height: 13,
                            radius: 6,
                          ),
                        ),
                        const SizedBox(width: 9),
                        _ShimmerBlock(
                          animation: animation,
                          width: 62,
                          height: 18,
                          radius: 9,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ShimmerBlock(
                      animation: animation,
                      width: 128,
                      height: 8,
                      radius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ShimmerBlock(
                animation: animation,
                width: 27,
                height: 27,
                radius: 14,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _InlineMetaShimmer(animation: animation)),
              const SizedBox(width: 14),
              Expanded(child: _InlineMetaShimmer(animation: animation)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineMetaShimmer extends StatelessWidget {
  const _InlineMetaShimmer({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ShimmerBlock(
          animation: animation,
          width: 23,
          height: 23,
          radius: 8,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ShimmerBlock(
            animation: animation,
            width: double.infinity,
            height: 8,
            radius: 4,
          ),
        ),
      ],
    );
  }
}

class _CompactApplicationsShimmer extends StatefulWidget {
  const _CompactApplicationsShimmer();

  @override
  State<_CompactApplicationsShimmer> createState() =>
      _CompactApplicationsShimmerState();
}

class _CompactApplicationsShimmerState
    extends State<_CompactApplicationsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CompactCardShimmer(animation: _controller),
        const SizedBox(height: 8),
        _CompactCardShimmer(animation: _controller),
      ],
    );
  }
}

class _CompactCardShimmer extends StatelessWidget {
  const _CompactCardShimmer({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _ShimmerBlock(
            animation: animation,
            width: 38,
            height: 38,
            radius: 12,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ShimmerBlock(
                        animation: animation,
                        width: double.infinity,
                        height: 12,
                        radius: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ShimmerBlock(
                      animation: animation,
                      width: 58,
                      height: 17,
                      radius: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ShimmerBlock(
                  animation: animation,
                  width: 110,
                  height: 8,
                  radius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ShimmerBlock(
            animation: animation,
            width: 25,
            height: 25,
            radius: 13,
          ),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.animation,
    required this.width,
    required this.height,
    required this.radius,
    this.dark = false,
  });

  final Animation<double> animation;
  final double width;
  final double height;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final t = animation.value;

    final base = dark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF0F4F7);
    final highlight = dark
        ? Colors.white.withOpacity(0.17)
        : const Color(0xFFF9FBFC);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + (3.6 * t), 0),
          end: Alignment(-0.8 + (3.6 * t), 0),
          colors: [base, highlight, base],
        ),
      ),
    );
  }
}

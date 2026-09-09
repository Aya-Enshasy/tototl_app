import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/pilot/screens/applications/apply_for_job_screen.dart';
import 'package:tototl_app/features/pilot/screens/applications/application_details_screen.dart';

import '../../models/pilot_job_model.dart';
import '../../services/pilot_job_service.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({
    super.key,
    required this.jobId,
    this.detailsFuture,
  });

  final int jobId;

  /// Optional request started by the previous screen before navigation.
  /// This makes the route transition useful loading time without ever showing
  /// list/demo data as if it were authoritative detail data.
  final Future<PilotJobModel>? detailsFuture;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final PilotJobService _service;
  late final AnimationController _pageAnimationController;

  PilotJobModel? _job;

  bool _loading = true;
  bool _refreshing = false;
  bool _saved = false;
  String? _errorMessage;

  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();

    _service = PilotJobService(ApiClient());

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    unawaited(
      _load(
        initialFuture: widget.detailsFuture,
        initial: true,
      ),
    );
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _load({
    Future<PilotJobModel>? initialFuture,
    bool initial = false,
    bool showRefreshError = false,
  }) async {
    if (_refreshing && !initial) return;

    final serial = ++_requestSerial;
    final hasContent = _job != null;

    if (mounted) {
      setState(() {
        if (!hasContent) {
          _loading = true;
        } else {
          _refreshing = true;
        }
        _errorMessage = null;
      });
    }

    try {
      final job = await (initialFuture ?? _service.getJobDetails(widget.jobId));

      if (!mounted || serial != _requestSerial) return;

      final firstContent = _job == null;

      setState(() {
        _job = job;
        _loading = false;
        _refreshing = false;
        _errorMessage = null;
      });

      if (firstContent) {
        _pageAnimationController
          ..reset()
          ..forward();
      }
    } catch (e) {
      if (!mounted || serial != _requestSerial) return;

      final stillHasContent = _job != null;

      setState(() {
        _loading = false;
        _refreshing = false;

        if (!stillHasContent) {
          _errorMessage = e.toString();
        }
      });

      if (stillHasContent && showRefreshError) {
        _showSnack(
          'Couldn’t refresh right now. Your last loaded job details are still shown.',
        );
      }
    }
  }

  Future<void> _manualRefresh() async {
    HapticFeedback.selectionClick();
    await _load(showRefreshError: true);
  }

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.045).clamp(0.0, 0.52).toDouble();
    final end = (start + 0.38).clamp(0.0, 1.0).toDouble();

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
          begin: const Offset(0, 0.020),
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
          const _JobDetailsBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  saved: _saved,
                  updating: _refreshing,
                  onBack: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  onSave: () {
                    HapticFeedback.selectionClick();
                    setState(() => _saved = !_saved);
                  },
                ),
                Expanded(
                  child: _loading
                      ? const _PremiumJobDetailShimmer()
                      : _errorMessage != null && _job == null
                      ? _DetailError(
                    message: _errorMessage!,
                    onRetry: () => _load(initial: true),
                  )
                      : _content(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget? _buildBottomAction() {
    final job = _job;

    if (_loading || job == null) return null;

    final application = job.application;

    if (application?.hasApplied == true) {
      final applicationId = application?.id;
      final visual = _applicationVisual(application?.status ?? '');

      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppColors.cardBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.045),
                blurRadius: 22,
                offset: const Offset(0, -7),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: visual.foreground.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 29,
                        height: 29,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.72),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: visual.foreground,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Application',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              application?.statusLabel.trim().isEmpty == true
                                  ? 'Submitted'
                                  : application!.statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: visual.foreground,
                                fontSize: 12.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (applicationId != null) ...[
                const SizedBox(width: 9),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () async {
                      HapticFeedback.selectionClick();

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ApplicationDetailsScreen(
                            applicationId: applicationId,
                          ),
                        ),
                      );

                      if (mounted) {
                        unawaited(_load());
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                    ),
                    label: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.045),
              blurRadius: 22,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ApplyForJobScreen(job: job),
                ),
              );

              if (mounted) {
                unawaited(_load());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Apply for this mission',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
                SizedBox(width: 9),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final job = _job!;

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _manualRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
        children: [
          _animatedEntry(
            index: 0,
            child: _MissionHero(job: job),
          ),
          const SizedBox(height: 13),
          _animatedEntry(
            index: 1,
            child: _MissionSnapshot(job: job),
          ),
          if (job.application?.hasApplied == true) ...[
            const SizedBox(height: 13),
            _animatedEntry(
              index: 2,
              child: _ApplicationStatusBanner(
                application: job.application!,
              ),
            ),
          ],
          const SizedBox(height: 13),
          _animatedEntry(
            index: 3,
            child: _MissionBriefCard(job: job),
          ),
          const SizedBox(height: 13),
          _animatedEntry(
            index: 4,
            child: _MissionLogisticsCard(job: job),
          ),
          if (job.requirementLines.isNotEmpty) ...[
            const SizedBox(height: 13),
            _animatedEntry(
              index: 5,
              child: _RequirementsCard(job: job),
            ),
          ],
          if (job.requiredCapabilities.isNotEmpty) ...[
            const SizedBox(height: 13),
            _animatedEntry(
              index: 6,
              child: _CapabilitiesCard(
                capabilities: job.requiredCapabilities,
              ),
            ),
          ],
          if (job.attachments.isNotEmpty) ...[
            const SizedBox(height: 13),
            _animatedEntry(
              index: 7,
              child: _AttachmentsCard(
                attachments: job.attachments,
              ),
            ),
          ],
          if (job.company != null) ...[
            const SizedBox(height: 13),
            _animatedEntry(
              index: 8,
              child: _CompanyPreviewCard(
                company: job.company!,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(message),
        ),
      );
  }
}

// ============================================================================
// PAGE BACKGROUND
// ============================================================================

class _JobDetailsBackground extends StatelessWidget {
  const _JobDetailsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -145,
          right: -130,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withOpacity(0.09),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 470,
          left: -170,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.logoTurquoise.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TOP BAR
// ============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.saved,
    required this.updating,
    required this.onBack,
    required this.onSave,
  });

  final bool saved;
  final bool updating;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 7),
      child: Row(
        children: [
          _TopCircleButton(
            tooltip: 'Back',
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mission Details',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Review the opportunity before you apply',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: updating
                ? Container(
              key: const ValueKey('updating'),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.055),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 13,
                    color: AppColors.blue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Updating',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
                : _TopCircleButton(
              key: const ValueKey('save'),
              tooltip: saved ? 'Remove saved job' : 'Save job',
              icon: saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              selected: saved,
              onTap: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.blue.withOpacity(0.09)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.blue.withOpacity(0.18)
                    : AppColors.cardBorder,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.blue : AppColors.navy,
              size: 17.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HERO
// ============================================================================

class _MissionHero extends StatelessWidget {
  const _MissionHero({
    required this.job,
  });

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    final company = job.company;
    final location = job.detailedLocationLabel.trim();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071D39),
            Color(0xFF0A4055),
            Color(0xFF087E91),
          ],
          stops: [0.0, 0.56, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087E91).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -62,
            child: Container(
              width: 195,
              height: 195,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.055),
                  width: 28,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 13,
            child: Icon(
              _categoryIcon(job.serviceCategory),
              color: Colors.white.withOpacity(0.065),
              size: 104,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 19, 19, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroChip(
                      icon: _categoryIcon(job.serviceCategory),
                      label: job.categoryLabel,
                    ),
                    const Spacer(),
                    if (company?.verified == true)
                      const _VerifiedHeroChip(),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  job.title.trim().isEmpty ? 'Untitled Mission' : job.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.55,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      color: Colors.white.withOpacity(0.64),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        company?.displayName ?? 'Hiring company',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MISSION VALUE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.52),
                              fontSize: 8.4,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.payLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.logoTurquoiseLight,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (location.isNotEmpty &&
                        location.toLowerCase() != 'not specified')
                      Flexible(
                        child: _HeroLocation(
                          text: location,
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.logoTurquoiseLight,
            size: 13,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedHeroChip extends StatelessWidget {
  const _VerifiedHeroChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: AppColors.logoTurquoiseLight,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLocation extends StatelessWidget {
  const _HeroLocation({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: Colors.white.withOpacity(0.72),
            size: 12,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.76),
                fontSize: 9.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SNAPSHOT
// ============================================================================

class _MissionSnapshot extends StatelessWidget {
  const _MissionSnapshot({
    required this.job,
  });

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    return _PremiumSurface(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'AT A GLANCE',
            title: 'Mission snapshot',
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.payments_outlined,
                  label: 'Budget',
                  value: job.payLabel,
                  accent: AppColors.green,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.calendar_today_outlined,
                  label: 'Mission',
                  value: job.dateLabel,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _SnapshotMetric(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'Service',
                  value: job.categoryLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.blue,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.065),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 16,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 8.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 10.2,
              height: 1.18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.cardBorder,
    );
  }
}

// ============================================================================
// MISSION BRIEF
// ============================================================================

class _MissionBriefCard extends StatelessWidget {
  const _MissionBriefCard({
    required this.job,
  });

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    final description = job.description.trim();

    return _PremiumSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.notes_rounded,
            title: 'Mission Brief',
            subtitle: 'Scope and expectations from the company',
          ),
          const SizedBox(height: 14),
          Text(
            description.isEmpty
                ? 'No mission description was provided.'
                : description,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.7,
              height: 1.66,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOGISTICS
// ============================================================================

class _MissionLogisticsCard extends StatelessWidget {
  const _MissionLogisticsCard({
    required this.job,
  });

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    return _PremiumSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.route_outlined,
            title: 'Mission Logistics',
            subtitle: 'Where, when and how the mission is funded',
          ),
          const SizedBox(height: 14),
          _LogisticsTile(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: _location(job),
          ),
          const _SoftDivider(),
          _LogisticsTile(
            icon: Icons.calendar_month_outlined,
            label: 'Schedule',
            value: _schedule(job),
          ),
          const _SoftDivider(),
          _LogisticsTile(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: '${job.paymentTypeLabel} • ${job.payLabel}',
            valueColor: AppColors.green,
          ),
        ],
      ),
    );
  }

  String _location(PilotJobModel job) {
    final value = job.detailedLocationLabel.trim();
    return value.isEmpty ? 'Not specified' : value;
  }

  String _schedule(PilotJobModel job) {
    final start = _formatDate(job.startDate);
    final end = _formatDate(job.endDate);

    if (start == 'Not specified' && end == 'Not specified') {
      return 'Not specified';
    }

    if (end == 'Not specified' || start == end) return start;

    return '$start  →  $end';
  }
}

class _LogisticsTile extends StatelessWidget {
  const _LogisticsTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.navy,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.055),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.blue,
              size: 17,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 9.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 12.2,
                      height: 1.35,
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

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        color: AppColors.cardBorder,
      ),
    );
  }
}

// ============================================================================
// REQUIREMENTS
// ============================================================================

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({
    required this.job,
  });

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    return _PremiumSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.fact_check_outlined,
            title: 'Pilot Requirements',
            subtitle: 'What the company expects from the selected pilot',
          ),
          const SizedBox(height: 14),
          ...job.requirementLines.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.065),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.green,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12.3,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

// ============================================================================
// CAPABILITIES
// ============================================================================

class _CapabilitiesCard extends StatelessWidget {
  const _CapabilitiesCard({
    required this.capabilities,
  });

  final List<String> capabilities;

  @override
  Widget build(BuildContext context) {
    return _PremiumSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.memory_rounded,
            title: 'Aircraft Match',
            subtitle: 'Drone capabilities requested for this mission',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: capabilities
                .map(
                  (item) => _CapabilityChip(label: item),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.green.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.green,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 10.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ATTACHMENTS
// ============================================================================

class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard({
    required this.attachments,
  });

  final List<PilotJobAttachmentModel> attachments;

  @override
  Widget build(BuildContext context) {
    return _PremiumSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.attach_file_rounded,
            title: 'Mission Files',
            subtitle:
            '${attachments.length} ${attachments.length == 1 ? 'attachment' : 'attachments'} shared by the company',
          ),
          const SizedBox(height: 13),
          ...attachments.map(
                (attachment) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.cardBorder.withOpacity(0.72),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      attachment.isImage
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      color: AppColors.blue,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name.trim().isEmpty
                              ? 'Attachment'
                              : attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 11.7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (attachment.size > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            _fileSize(attachment.size),
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 9.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.grey,
                    size: 16,
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

// ============================================================================
// COMPANY PREVIEW
// ============================================================================

class _CompanyPreviewCard extends StatelessWidget {
  const _CompanyPreviewCard({
    required this.company,
  });

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    final name = company.displayName.trim().isEmpty
        ? 'Hiring Company'
        : company.displayName.trim();

    return _PremiumSurface(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -48,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.logoTurquoise.withOpacity(0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8FBFB),
                          Color(0xFFD9F1F6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HIRING COMPANY',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 15.2,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.25,
                                ),
                              ),
                            ),
                            if (company.verified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.logoTurquoise,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          company.verified
                              ? 'Verified company on TOTOTL'
                              : 'Company on TOTOTL',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.045),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: AppColors.blue,
                      size: 16,
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

// ============================================================================
// APPLICATION STATUS
// ============================================================================

class _ApplicationStatusBanner extends StatelessWidget {
  const _ApplicationStatusBanner({
    required this.application,
  });

  final PilotJobApplicationSummary application;

  @override
  Widget build(BuildContext context) {
    final visual = _applicationVisual(application.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: visual.foreground.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _applicationIcon(application.status),
              color: visual.foreground,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your application',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  application.statusLabel.trim().isEmpty
                      ? 'Submitted'
                      : application.statusLabel,
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_outward_rounded,
            color: visual.foreground.withOpacity(0.65),
            size: 17,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMMON SURFACES
// ============================================================================

class _PremiumSurface extends StatelessWidget {
  const _PremiumSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: AppColors.cardBorder.withOpacity(0.90),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.032),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
  });

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 8.2,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14.3,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.blue,
            size: 18,
          ),
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 9.6,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FIRST-LOAD PREMIUM SHIMMER
// ============================================================================

class _PremiumJobDetailShimmer extends StatefulWidget {
  const _PremiumJobDetailShimmer();

  @override
  State<_PremiumJobDetailShimmer> createState() =>
      _PremiumJobDetailShimmerState();
}

class _PremiumJobDetailShimmerState extends State<_PremiumJobDetailShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
        final t = _animation.value;

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 34),
          children: [
            _HeroSkeleton(t: t),
            const SizedBox(height: 13),
            _SnapshotSkeleton(t: t),
            const SizedBox(height: 13),
            _SectionSkeleton(
              t: t,
              lines: const [0.92, 0.84, 0.70],
            ),
            const SizedBox(height: 13),
            _LogisticsSkeleton(t: t),
          ],
        );
      },
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({
    required this.t,
  });

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D2A42),
            Color(0xFF0C5062),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(
                t: t,
                width: 92,
                height: 27,
                radius: 16,
                dark: true,
              ),
              const Spacer(),
              _ShimmerBlock(
                t: t,
                width: 70,
                height: 27,
                radius: 16,
                dark: true,
              ),
            ],
          ),
          const Spacer(),
          _ShimmerBlock(
            t: t,
            width: 245,
            height: 20,
            radius: 8,
            dark: true,
          ),
          const SizedBox(height: 9),
          _ShimmerBlock(
            t: t,
            width: 186,
            height: 20,
            radius: 8,
            dark: true,
          ),
          const SizedBox(height: 12),
          _ShimmerBlock(
            t: t,
            width: 122,
            height: 10,
            radius: 5,
            dark: true,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ShimmerBlock(
                t: t,
                width: 118,
                height: 17,
                radius: 7,
                dark: true,
              ),
              const Spacer(),
              _ShimmerBlock(
                t: t,
                width: 105,
                height: 28,
                radius: 12,
                dark: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotSkeleton extends StatelessWidget {
  const _SnapshotSkeleton({
    required this.t,
  });

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      padding: const EdgeInsets.all(15),
      decoration: _skeletonCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBlock(
            t: t,
            width: 104,
            height: 13,
            radius: 6,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _MetricSkeleton(t: t)),
                const _MetricDivider(),
                Expanded(child: _MetricSkeleton(t: t)),
                const _MetricDivider(),
                Expanded(child: _MetricSkeleton(t: t)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton({
    required this.t,
  });

  final double t;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShimmerBlock(
          t: t,
          width: 33,
          height: 33,
          radius: 10,
        ),
        const SizedBox(height: 8),
        _ShimmerBlock(
          t: t,
          width: 42,
          height: 7,
          radius: 4,
        ),
        const SizedBox(height: 6),
        _ShimmerBlock(
          t: t,
          width: 60,
          height: 9,
          radius: 5,
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({
    required this.t,
    required this.lines,
  });

  final double t;
  final List<double> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _skeletonCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(
                t: t,
                width: 38,
                height: 38,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBlock(
                      t: t,
                      width: 126,
                      height: 12,
                      radius: 6,
                    ),
                    const SizedBox(height: 7),
                    _ShimmerBlock(
                      t: t,
                      width: 180,
                      height: 8,
                      radius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lines.asMap().entries.map(
                (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == lines.length - 1 ? 0 : 9,
              ),
              child: FractionallySizedBox(
                widthFactor: entry.value,
                alignment: Alignment.centerLeft,
                child: _ShimmerBlock(
                  t: t,
                  width: double.infinity,
                  height: 10,
                  radius: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogisticsSkeleton extends StatelessWidget {
  const _LogisticsSkeleton({
    required this.t,
  });

  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _skeletonCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _ShimmerBlock(
                t: t,
                width: 38,
                height: 38,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShimmerBlock(
                  t: t,
                  width: double.infinity,
                  height: 12,
                  radius: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
                (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == 2 ? 0 : 12,
              ),
              child: Row(
                children: [
                  _ShimmerBlock(
                    t: t,
                    width: 38,
                    height: 38,
                    radius: 12,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBlock(
                          t: t,
                          width: 52,
                          height: 7,
                          radius: 4,
                        ),
                        const SizedBox(height: 6),
                        _ShimmerBlock(
                          t: t,
                          width: double.infinity,
                          height: 10,
                          radius: 5,
                        ),
                      ],
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

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.t,
    required this.width,
    required this.height,
    required this.radius,
    this.dark = false,
  });

  final double t;
  final double width;
  final double height;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final base = dark
        ? Colors.white.withOpacity(0.085)
        : const Color(0xFFEAF0F3);

    final highlight = dark
        ? Colors.white.withOpacity(0.22)
        : const Color(0xFFF9FCFD);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + (3.6 * t), 0),
          end: Alignment(-0.8 + (3.6 * t), 0),
          colors: [
            base,
            highlight,
            base,
          ],
          stops: const [0.18, 0.50, 0.82],
        ),
      ),
    );
  }
}

BoxDecoration _skeletonCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(23),
    border: Border.all(
      color: AppColors.cardBorder,
      width: 0.8,
    ),
  );
}

// ============================================================================
// ERROR
// ============================================================================

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.blue,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Couldn’t load this mission',
                textAlign: TextAlign.center,
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
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 17,
                ),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
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

// ============================================================================
// HELPERS
// ============================================================================

class _VisualPair {
  const _VisualPair(
      this.foreground,
      this.background,
      );

  final Color foreground;
  final Color background;
}

_VisualPair _applicationVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _VisualPair(
        AppColors.green,
        AppColors.greenBg,
      );
    case 'rejected':
      return _VisualPair(
        Colors.red.shade700,
        Colors.red.shade50,
      );
    case 'withdrawn':
      return _VisualPair(
        AppColors.grey,
        Colors.grey.shade100,
      );
    default:
      return const _VisualPair(
        AppColors.blue,
        AppColors.blueBg,
      );
  }
}

IconData _applicationIcon(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return Icons.check_circle_outline_rounded;
    case 'rejected':
      return Icons.cancel_outlined;
    case 'withdrawn':
      return Icons.undo_rounded;
    default:
      return Icons.schedule_rounded;
  }
}

IconData _categoryIcon(String category) {
  switch (category.trim().toLowerCase()) {
    case 'inspection':
      return Icons.manage_search_rounded;
    case 'mapping':
      return Icons.map_outlined;
    case 'photography':
      return Icons.photo_camera_outlined;
    case 'construction':
      return Icons.construction_outlined;
    case 'surveying':
      return Icons.straighten_rounded;
    default:
      return Icons.flight_takeoff_rounded;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not specified';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';

  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'C';

  return parts.map((part) => part[0].toUpperCase()).join();
}

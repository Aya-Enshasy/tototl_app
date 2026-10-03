import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/pilot/screens/applications/apply_for_job_screen.dart';
import 'package:tototl_app/features/pilot/screens/applications/application_details_screen.dart';
import 'package:tototl_app/features/pilot/screens/jobs/pilot_company_profile_screen.dart';

import '../../models/pilot_job_model.dart';
import '../../services/pilot_job_service.dart';
import 'package:tototl_app/core/localization/app_language.dart';

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
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.98),
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E9EC), width: .8),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A2D46).withOpacity(.055),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: visual.foreground.withOpacity(.12),
                      width: .7,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 29,
                        height: 29,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.76),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          _applicationIcon(application?.status ?? ''),
                          color: visual.foreground,
                          size: 14.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'APPLICATION',
                              style: TextStyle(
                                color: Color(0xFF7E8F9B),
                                fontSize: 6.9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
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
                                fontSize: 10.2,
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
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
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
                      elevation: 0,
                      backgroundColor: const Color(0xFF0B3147),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_outward_rounded, size: 14),
                      ],
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.98),
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E9EC), width: .8),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A2D46).withOpacity(.055),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 49,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A9AAA),
                  Color(0xFF087D92),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A9AAA).withOpacity(.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 15.5,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Apply for this mission',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.05,
                      ),
                    ),
                  ],
                ),
              ),
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
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
        children: [
          _animatedEntry(
            index: 0,
            child: _MissionHero(job: job),
          ),
          const SizedBox(height: 10),
          _animatedEntry(
            index: 1,
            child: _MissionSnapshot(job: job),
          ),
          if (job.application?.hasApplied == true) ...[
            const SizedBox(height: 10),
            _animatedEntry(
              index: 2,
              child: _ApplicationStatusBanner(
                application: job.application!,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _animatedEntry(
            index: 3,
            child: _MissionBriefCard(job: job),
          ),
          const SizedBox(height: 10),
          _animatedEntry(
            index: 4,
            child: _MissionLogisticsCard(job: job),
          ),
          if (job.requirementLines.isNotEmpty) ...[
            const SizedBox(height: 10),
            _animatedEntry(
              index: 5,
              child: _RequirementsCard(job: job),
            ),
          ],
          if (job.requiredCapabilities.isNotEmpty) ...[
            const SizedBox(height: 10),
            _animatedEntry(
              index: 6,
              child: _CapabilitiesCard(
                capabilities: job.requiredCapabilities,
              ),
            ),
          ],
          if (job.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            _animatedEntry(
              index: 7,
              child: _AttachmentsCard(
                attachments: job.attachments,
              ),
            ),
          ],
          if (job.company != null) ...[
            const SizedBox(height: 10),
            _animatedEntry(
              index: 8,
              child: _CompanyPreviewCard(
                company: job.company!,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PilotCompanyProfileScreen(company: job.company!),
                    ),
                  );
                },
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
    return Container(
      color: const Color(0xFFF7FAFB),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10AEB8).withOpacity(.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 430,
            left: -170,
            child: IgnorePointer(
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0A2D46).withOpacity(.045),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
      child: Row(
        children: [
          _TopCircleButton(
            tooltip: AppLanguage.text('Back'),
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('Mission Details'),
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 15.4,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLanguage.text('Everything you need before applying'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D8E9B),
                    fontSize: 9.5,
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
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.7,
                      color: Color(0xFF079DAB),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Updating',
                    style: TextStyle(
                      color: Color(0xFF079DAB),
                      fontSize: 8.8,
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
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE7F8F8)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF12AAB5).withOpacity(.20)
                    : const Color(0xFFDDE6EA),
                width: .8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A2D46).withOpacity(.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: selected
                  ? const Color(0xFF079DAB)
                  : const Color(0xFF0A2D46),
              size: 16.5,
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
    final asset = _jobCategoryAsset(job.serviceCategory);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFDCE6E9),
          width: .8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2D46).withOpacity(.055),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE9F5F6),
                    alignment: Alignment.center,
                    child: Icon(
                      _categoryIcon(job.serviceCategory),
                      color: const Color(0xFF0A9AAA),
                      size: 42,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x18051A2B),
                        Color(0x32051A2B),
                        Color(0xC20A2437),
                      ],
                      stops: [0, .48, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: 13,
                  child: _HeroChip(
                    icon: _categoryIcon(job.serviceCategory),
                    label: job.categoryLabel,
                  ),
                ),
                if (company?.verified == true)
                  const Positioned(
                    right: 13,
                    top: 13,
                    child: _VerifiedHeroChip(),
                  ),
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title.trim().isEmpty
                            ? 'Untitled Mission'
                            : job.title.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.8,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_rounded,
                            color: Color(0xFFD6ECEF),
                            size: 12.5,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              company?.displayName ?? 'Hiring company',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE9F4F5),
                                fontSize: 9.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (location.isNotEmpty &&
                              !location.toLowerCase().contains('not specified'))
                            Flexible(
                              child: _HeroLocation(text: location),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
            child: Row(
              children: [
                Expanded(
                  child: _HeroBottomStat(
                    label: 'MISSION VALUE',
                    value: job.payLabel,
                    icon: Icons.payments_outlined,
                    accent: const Color(0xFF089B91),
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: const Color(0xFFE2E9EC),
                ),
                Expanded(
                  child: _HeroBottomStat(
                    label: 'SCHEDULE',
                    value: job.dateLabel,
                    icon: Icons.calendar_today_outlined,
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

class _HeroBottomStat extends StatelessWidget {
  const _HeroBottomStat({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = const Color(0xFF0A2D46),
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: accent.withOpacity(.075),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 14.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8B9AA5),
                    fontSize: 7.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .65,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF071D2C).withOpacity(.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(.14),
          width: .7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF6DE1DA),
            size: 12,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.8,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF071D2C).withOpacity(.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(.14),
          width: .7,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Color(0xFF6DE1DA),
            size: 12.5,
          ),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.4,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: Color(0xFFD5E9EB),
          size: 11.5,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFFD5E9EB),
              fontSize: 8.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
    return Row(
      children: [
        Expanded(
          child: _SnapshotMetric(
            icon: Icons.payments_outlined,
            label: AppLanguage.text('Budget'),
            value: job.payLabel,
            accent: const Color(0xFF07998F),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SnapshotMetric(
            icon: Icons.calendar_today_outlined,
            label: AppLanguage.text('Mission'),
            value: job.dateLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SnapshotMetric(
            icon: Icons.flight_takeoff_rounded,
            label: AppLanguage.text('Service'),
            value: job.categoryLabel,
            accent: const Color(0xFF7A66C7),
          ),
        ),
      ],
    );
  }
}


class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = const Color(0xFF0B92B0),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDDE6EA),
          width: .75,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2D46).withOpacity(.028),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: accent.withOpacity(.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 14),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8796A2),
              fontSize: 8.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0A2D46),
              fontSize: 9.5,
              height: 1.15,
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
    return const SizedBox(width: 8);
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
          _CardHeader(
            icon: Icons.notes_rounded,
            title: AppLanguage.text('Mission Brief'),
            subtitle: AppLanguage.text('Scope and expectations'),
          ),
          const SizedBox(height: 12),
          Text(
            description.isEmpty
                ? 'No mission description was provided.'
                : description,
            style: const TextStyle(
              color: Color(0xFF425665),
              fontSize: 11.2,
              height: 1.55,
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
          _CardHeader(
            icon: Icons.route_outlined,
            title: AppLanguage.text('Mission Logistics'),
            subtitle: AppLanguage.text('Location, schedule and payment'),
          ),
          const SizedBox(height: 12),
          _LogisticsTile(
            icon: Icons.location_on_outlined,
            label: AppLanguage.text('Location'),
            value: _location(job),
          ),
          const _SoftDivider(),
          _LogisticsTile(
            icon: Icons.calendar_month_outlined,
            label: AppLanguage.text('Schedule'),
            value: _schedule(job),
          ),
          const _SoftDivider(),
          _LogisticsTile(
            icon: Icons.payments_outlined,
            label: AppLanguage.text('Payment'),
            value: '${job.paymentTypeLabel} • ${job.payLabel}',
            valueColor: const Color(0xFF07998F),
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
    this.valueColor = const Color(0xFF0A2D46),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0A9AAA),
            size: 15.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A99A4),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 10.8,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Divider(
        height: 1,
        color: Color(0xFFE7ECEF),
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
          _CardHeader(
            icon: Icons.fact_check_outlined,
            title: AppLanguage.text('Pilot Requirements'),
            subtitle: AppLanguage.text('What the company expects'),
          ),
          const SizedBox(height: 12),
          ...job.requirementLines.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F4),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF139979),
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF425665),
                          fontSize: 10.7,
                          height: 1.4,
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
          _CardHeader(
            icon: Icons.memory_rounded,
            title: AppLanguage.text('Aircraft Match'),
            subtitle: AppLanguage.text('Required drone capabilities'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: capabilities
                .map((item) => _CapabilityChip(label: item))
                .toList(growable: false),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF159B7A).withOpacity(.11),
          width: .7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF159B7A),
            size: 11.5,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF14795F),
              fontSize: 8.9,
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
            title: AppLanguage.text('Mission Files'),
            subtitle:
            '${attachments.length} ${attachments.length == 1 ? 'attachment' : 'attachments'} shared',
          ),
          const SizedBox(height: 12),
          ...attachments.map(
                (attachment) => Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFC),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFFE3EAED),
                  width: .7,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F8),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: attachment.isImage &&
                        attachment.url.trim().isNotEmpty
                        ? Image.network(
                      attachment.url.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF0A9AAA),
                        size: 17,
                      ),
                    )
                        : const Icon(
                      Icons.insert_drive_file_outlined,
                      color: Color(0xFF0A9AAA),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name.trim().isEmpty
                              ? 'Attachment'
                              : attachment.name.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0A2D46),
                            fontSize: 10.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (attachment.size > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            _fileSize(attachment.size),
                            style: const TextStyle(
                              color: Color(0xFF8A99A4),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF91A0A9),
                    size: 17,
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
    required this.onTap,
  });

  final PilotJobCompanySummary company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = company.displayName.trim().isEmpty
        ? 'Hiring Company'
        : company.displayName.trim();
    final location = company.locationLabel.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3147),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A2D46).withOpacity(.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(.8),
                    width: 1.2,
                  ),
                ),
                child: company.hasProfilePhoto
                    ? Image.network(
                  company.profilePhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _CompanyInitials(
                    value: name,
                  ),
                )
                    : _CompanyInitials(value: name),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HIRING COMPANY',
                      style: TextStyle(
                        color: Color(0xFF75DCD6),
                        fontSize: 7.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
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
                              color: Colors.white,
                              fontSize: 11.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (company.verified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF75DCD6),
                            size: 13.5,
                          ),
                        ],
                      ],
                    ),
                    if (location.isNotEmpty &&
                        !location.toLowerCase().contains('not specified')) ...[
                      const SizedBox(height: 4),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB9CBD2),
                          fontSize: 8.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  color: Color(0xFF75DCD6),
                  size: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyInitials extends StatelessWidget {
  const _CompanyInitials({
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE7FBF9),
            Color(0xFFDCEFF3),
          ],
        ),
      ),
      child: Text(
        _initials(value),
        style: const TextStyle(
          color: Color(0xFF0A2D46),
          fontSize: 15,
          fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: visual.foreground.withOpacity(.14),
          width: .75,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.78),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _applicationIcon(application.status),
              color: visual.foreground,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your application',
                  style: TextStyle(
                    color: Color(0xFF536875),
                    fontSize: 8.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  application.statusLabel.trim().isEmpty
                      ? 'Submitted'
                      : application.statusLabel,
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_outward_rounded,
            color: visual.foreground.withOpacity(.60),
            size: 15,
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
    this.padding = const EdgeInsets.all(14),
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
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFDDE6EA),
          width: .75,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2D46).withOpacity(.028),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
            color: Color(0xFF0A9AAA),
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            letterSpacing: .75,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0A2D46),
            fontSize: 12.7,
            fontWeight: FontWeight.w900,
            letterSpacing: -.12,
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0A9AAA),
            size: 15.5,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8796A2),
                    fontSize: 8.6,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
          children: [
            _HeroSkeleton(t: t),
            const SizedBox(height: 10),
            _SnapshotSkeleton(t: t),
            const SizedBox(height: 10),
            _SectionSkeleton(
              t: t,
              lines: const [0.92, 0.84, 0.70],
            ),
            const SizedBox(height: 10),
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
              Text(
                AppLanguage.text('Couldn’t load this mission'),
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
                label: Text(
                  AppLanguage.text('Try Again'),
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


String _jobCategoryAsset(String rawCategory) {
  final value = rawCategory.trim().toLowerCase();

  if (value.contains('inspection')) {
    return 'assets/images/Inspection.png';
  }
  if (value.contains('mapping')) {
    return 'assets/images/Mapping.png';
  }
  if (value.contains('photography') || value.contains('photo')) {
    return 'assets/images/Photography.png';
  }
  if (value.contains('construction')) {
    return 'assets/images/Construction.png';
  }
  if (value.contains('surveying') || value.contains('survey')) {
    return 'assets/images/Surveying.png';
  }
  return 'assets/images/Other.png';
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import '../../models/drone_model.dart';
import '../../models/pilot_application_model.dart';
import '../../models/pilot_job_model.dart';
import '../../services/drone_service.dart';
import '../../services/pilot_application_service.dart';
import '../../services/pilot_job_service.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  const ApplicationDetailsScreen({
    super.key,
    required this.applicationId,
    this.initialApplication,
  });

  final int applicationId;
  final PilotApplicationModel? initialApplication;

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState
    extends State<ApplicationDetailsScreen> {
  late final PilotApplicationService _applicationService;
  late final PilotJobService _jobService;
  late final DroneService _droneService;

  PilotApplicationModel? _application;

  bool _firstLoading = true;
  bool _refreshing = false;
  bool _withdrawing = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _applicationService = PilotApplicationService(ApiClient());
    _jobService = PilotJobService(ApiClient());
    _droneService = DroneService(ApiClient());

    _application = widget.initialApplication;
    _firstLoading = widget.initialApplication == null;

    _bootstrap();
  }

  // ---------------------------------------------------------------------------
  // LOCAL FIRST, THEN SILENT REFRESH
  // ---------------------------------------------------------------------------

  Future<void> _bootstrap() async {
    if (_application != null) {
      // initialApplication is already usable, so do not hide it behind a
      // loading state on first frame.
      _firstLoading = false;
      _error = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_refreshSilently());
        }
      });
      return;
    }

    final cached =
    await _applicationService.getCachedApplication(widget.applicationId);

    if (!mounted) return;

    if (cached != null) {
      setState(() {
        _application = cached;
        _firstLoading = false;
        _error = null;
      });

      unawaited(_refreshSilently());
      return;
    }

    await _loadFresh(blocking: true);
  }

  Future<void> _refreshSilently() async {
    await _loadFresh(blocking: false);
  }

  Future<void> _manualRefresh() async {
    HapticFeedback.selectionClick();
    await _loadFresh(blocking: false, showRefreshError: true);
  }

  Future<void> _loadFresh({
    required bool blocking,
    bool showRefreshError = false,
  }) async {
    if (_refreshing) return;

    if (mounted) {
      setState(() {
        if (blocking) {
          _firstLoading = true;
        } else {
          _refreshing = true;
        }
        _error = null;
      });
    }

    try {
      var application = await _applicationService.getApplicationDetails(
        widget.applicationId,
      );

      PilotJobModel? job =
          application.job ?? _application?.job ?? widget.initialApplication?.job;

      DroneModel? drone = application.drone ??
          _application?.drone ??
          widget.initialApplication?.drone;

      Future<PilotJobModel?>? jobFuture;
      Future<DroneModel?>? droneFuture;

      if (job == null && application.jobPostingId > 0) {
        jobFuture = _safeLoadJob(application.jobPostingId);
      }

      if (drone == null && application.droneId > 0) {
        droneFuture = _safeLoadDrone(application.droneId);
      }

      // Both requests are started before either is awaited, so they can run
      // concurrently when both relationships are missing.
      if (jobFuture != null) {
        job = await jobFuture;
      }

      if (droneFuture != null) {
        drone = await droneFuture;
      }

      application = application.copyWith(
        job: job,
        drone: drone,
      );

      if (!mounted) return;

      setState(() {
        _application = application;
        _firstLoading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      final hasUsableData = _application != null;

      setState(() {
        _firstLoading = false;
        _refreshing = false;
        if (!hasUsableData) {
          _error = e.toString();
        }
      });

      if (hasUsableData && showRefreshError) {
        _snack(e.toString());
      }
    }
  }

  Future<PilotJobModel?> _safeLoadJob(int jobId) async {
    try {
      return await _jobService.getJobDetails(jobId);
    } catch (_) {
      // Closed/cancelled jobs can legitimately be unavailable to a pilot.
      return null;
    }
  }

  Future<DroneModel?> _safeLoadDrone(int droneId) async {
    try {
      return await _droneService.getDrone(droneId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // WITHDRAW
  // ---------------------------------------------------------------------------

  Future<void> _withdraw() async {
    final application = _application;

    if (application == null ||
        !application.isPending ||
        _withdrawing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
          actionsPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          title: const Row(
            children: [
              Icon(
                Icons.undo_rounded,
                color: AppColors.red,
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Withdraw application?',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your pending application will be withdrawn and can no longer move forward in this application flow.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Application'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _withdrawing = true);

    try {
      final updated = await _applicationService.withdrawApplication(
        application.id,
      );

      if (!mounted) return;

      setState(() {
        _application = updated.copyWith(
          job: application.job,
          drone: application.drone,
        );
        _withdrawing = false;
        _changed = true;
      });

      _snack('Application withdrawn.', success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _withdrawing = false);
      _snack(e.toString());
    }
  }

  void _back() => Navigator.of(context).pop(_changed);

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            const _DetailsBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: _firstLoading && _application == null
                        ? const _DetailShimmer()
                        : _error != null && _application == null
                        ? _ErrorState(
                      message: _error!,
                      onRetry: () => _loadFresh(blocking: true),
                    )
                        : _content(),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _bottomAction(),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 16, 7),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _back,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Details',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17.5,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Status, job and aircraft overview',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 220),
            child: _refreshStateSlot(),
          ),
        ],
      ),
    );
  }

  Widget _refreshStateSlot() {
    if (_refreshing) {
      return const _SyncPill(key: ValueKey('sync'));
    }

    return _RoundIconButton(
      key: const ValueKey('refresh'),
      icon: Icons.refresh_rounded,
      onTap: _manualRefresh,
    );
  }

  Widget _content() {
    final application = _application!;
    final visual = _statusVisual(application.status);

    return RefreshIndicator(
      color: AppColors.logoTurquoiseDark,
      backgroundColor: Colors.white,
      onRefresh: _manualRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          _HeroCard(
            application: application,
            visual: visual,
          ),
          const SizedBox(height: 14),
          _ApplicationOverview(application: application),
          const SizedBox(height: 14),
          _jobSection(application),
          const SizedBox(height: 14),
          _droneSection(application),
          if (application.coverMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Cover Message',
              subtitle: 'Message sent with your application',
              icon: Icons.chat_bubble_outline_rounded,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  application.coverMessage,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
          if (!application.isPending) ...[
            const SizedBox(height: 14),
            _statusSection(application),
          ],
        ],
      ),
    );
  }

  Widget _jobSection(PilotApplicationModel application) {
    final job = application.job;

    return _SectionCard(
      title: 'Job',
      subtitle: 'The mission linked to this application',
      icon: Icons.work_outline_rounded,
      child: job == null
          ? _UnavailableRelation(
        title: 'Job #${application.jobPostingId}',
        message:
        'The application is still available, but full job details are not currently accessible.',
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 15.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: job.detailedLocationLabel,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.payments_outlined,
                  label: 'Pay',
                  value: job.payLabel,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MetricTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date',
                  value: job.dateLabel,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _droneSection(PilotApplicationModel application) {
    final drone = application.drone;

    return _SectionCard(
      title: 'Drone Selected',
      subtitle: 'Aircraft committed to this application',
      icon: Icons.flight_rounded,
      child: drone == null
          ? _UnavailableRelation(
        title: 'Drone #${application.droneId}',
        message:
        'The selected drone ID is preserved even though its full profile is not available right now.',
      )
          : Row(
        children: [
          _DroneThumbnail(drone: drone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drone.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (drone.yearLabel.isNotEmpty)
                      _SmallPill(
                        icon: Icons.calendar_today_outlined,
                        text: drone.yearLabel,
                      ),
                    if (drone.flightTimeLabel != 'Not specified')
                      _SmallPill(
                        icon: Icons.timer_outlined,
                        text: drone.flightTimeLabel,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.greenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.green,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSection(PilotApplicationModel application) {
    final visual = _statusVisual(application.status);

    final rows = <Widget>[];

    if (application.decisionLabel.isNotEmpty) {
      rows.add(
        _DetailRow(
          label: 'Decision',
          value: application.decisionLabel,
        ),
      );
    }

    if (application.withdrawnLabel.isNotEmpty) {
      rows.add(
        _DetailRow(
          label: 'Withdrawn',
          value: application.withdrawnLabel,
        ),
      );
    }

    return _SectionCard(
      title: 'Application Status',
      subtitle: 'Latest decision on your submission',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: visual.background,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  visual.icon,
                  color: visual.foreground,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  application.statusLabel,
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 11),
            ...rows,
          ],
          if (application.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    application.rejectionReason,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _bottomAction() {
    final application = _application;

    if (application == null || !application.isPending) {
      return null;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.045),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _withdrawing ? null : _withdraw,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              disabledForegroundColor: AppColors.red.withOpacity(0.55),
              backgroundColor: _withdrawing
                  ? AppColors.redBg.withOpacity(0.65)
                  : Colors.white,
              side: BorderSide(
                color: AppColors.red.withOpacity(
                  _withdrawing ? 0.22 : 0.65,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                _withdrawing
                    ? Icons.hourglass_top_rounded
                    : Icons.undo_rounded,
                key: ValueKey(_withdrawing),
                size: 18,
              ),
            ),
            label: Text(
              _withdrawing
                  ? 'Withdrawing application...'
                  : 'Withdraw Application',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _snack(
      String message, {
        bool success = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.green : AppColors.navy,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Text(message),
        ),
      );
  }
}

// =============================================================================
// BACKDROP / TOP BAR
// =============================================================================

class _DetailsBackdrop extends StatelessWidget {
  const _DetailsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -160,
          right: -130,
          child: Container(
            width: 330,
            height: 330,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF16C6C7).withOpacity(0.11),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 350,
          left: -160,
          child: Container(
            width: 310,
            height: 310,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.blue.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
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
          ),
          child: Icon(
            icon,
            color: AppColors.navy,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FAFA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_rounded,
            color: AppColors.logoTurquoiseDark,
            size: 13,
          ),
          SizedBox(width: 5),
          Text(
            'Updating',
            style: TextStyle(
              color: AppColors.logoTurquoiseDark,
              fontSize: 9.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HERO
// =============================================================================

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.application,
    required this.visual,
  });

  final PilotApplicationModel application;
  final _StatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071B2C),
            Color(0xFF0A3C52),
            Color(0xFF087C89),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07394A).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -55,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF42DBD5).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -70,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.035),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
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
                        color: Colors.white.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: visual.foreground,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            application.statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${application.id}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  application.jobTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                  ),
                ),
                if (application.companyLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        color: Colors.white.withOpacity(0.68),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          application.companyLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Colors.white.withOpacity(0.65),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Submitted ${application.submittedLabel}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.76),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

// =============================================================================
// OVERVIEW / SECTIONS
// =============================================================================

class _ApplicationOverview extends StatelessWidget {
  const _ApplicationOverview({required this.application});

  final PilotApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Application',
      subtitle: 'Submission reference details',
      icon: Icons.assignment_outlined,
      child: Row(
        children: [
          Expanded(
            child: _ReferenceTile(
              label: 'Application',
              value: '#${application.id}',
              icon: Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReferenceTile(
              label: 'Job',
              value: '#${application.jobPostingId}',
              icon: Icons.work_outline_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReferenceTile(
              label: 'Drone',
              value: '#${application.droneId}',
              icon: Icons.flight_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
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
                  color: const Color(0xFFEAF9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.logoTurquoiseDark,
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
                        fontSize: 14.5,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.blue,
            size: 15,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 8.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.5,
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.grey, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DroneThumbnail extends StatelessWidget {
  const _DroneThumbnail({required this.drone});

  final DroneModel drone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 66,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16C6C7), Color(0xFFE7F0F4)],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: drone.imageUrl.trim().isEmpty
            ? const _DroneFallback()
            : Image.network(
          drone.imageUrl,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => const _DroneFallback(),
        ),
      ),
    );
  }
}

class _DroneFallback extends StatelessWidget {
  const _DroneFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF7F8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.flight_takeoff_rounded,
        color: AppColors.logoTurquoiseDark,
        size: 28,
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.grey, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 8.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableRelation extends StatelessWidget {
  const _UnavailableRelation({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.blue,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.2,
                    height: 1.4,
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

// =============================================================================
// STATUS
// =============================================================================

class _StatusVisual {
  final Color foreground;
  final Color background;
  final IconData icon;

  const _StatusVisual(
      this.foreground,
      this.background,
      this.icon,
      );
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
// ERROR
// =============================================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.blueBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.blue,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to open application',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15.5,
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
                height: 1.45,
              ),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.logoTurquoiseDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STRUCTURED SHIMMER
// =============================================================================

class _DetailShimmer extends StatefulWidget {
  const _DetailShimmer();

  @override
  State<_DetailShimmer> createState() => _DetailShimmerState();
}

class _DetailShimmerState extends State<_DetailShimmer>
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
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          children: [
            Container(
              height: 184,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B2638), Color(0xFF0B5967)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _glow(74, 23, 12, dark: true),
                  const SizedBox(height: 20),
                  _glow(220, 20, 8, dark: true),
                  const SizedBox(height: 9),
                  _glow(150, 10, 6, dark: true),
                  const Spacer(),
                  _glow(130, 28, 10, dark: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionSkeleton(metrics: true),
            const SizedBox(height: 14),
            _sectionSkeleton(),
            const SizedBox(height: 14),
            _sectionSkeleton(image: true),
          ],
        );
      },
    );
  }

  Widget _sectionSkeleton({
    bool metrics = false,
    bool image = false,
  }) {
    return Container(
      height: image ? 132 : 142,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _glow(38, 38, 12),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _glow(104, 11, 6),
                  const SizedBox(height: 6),
                  _glow(145, 7, 5),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (image)
            Row(
              children: [
                _glow(72, 60, 16),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _glow(145, 12, 6),
                      const SizedBox(height: 8),
                      _glow(90, 20, 10),
                    ],
                  ),
                ),
              ],
            )
          else if (metrics)
            Row(
              children: [
                Expanded(child: _glow(double.infinity, 42, 12)),
                const SizedBox(width: 8),
                Expanded(child: _glow(double.infinity, 42, 12)),
                const SizedBox(width: 8),
                Expanded(child: _glow(double.infinity, 42, 12)),
              ],
            )
          else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: _glow(190, 12, 6),
              ),
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: _glow(140, 8, 5),
              ),
            ],
        ],
      ),
    );
  }

  Widget _glow(
      double width,
      double height,
      double radius, {
        bool dark = false,
      }) {
    final t = _controller.value;

    return Container(
      width: width.isInfinite ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + (3.6 * t), 0),
          end: Alignment(-0.8 + (3.6 * t), 0),
          colors: dark
              ? [
            Colors.white.withOpacity(0.07),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.07),
          ]
              : const [
            Color(0xFFEEF4F5),
            Color(0xFFFBFDFD),
            Color(0xFFE3F0F2),
            Color(0xFFFBFDFD),
            Color(0xFFEEF4F5),
          ],
        ),
      ),
    );
  }
}

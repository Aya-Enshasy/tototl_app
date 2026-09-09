import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';
import 'package:tototl_app/features/chat/screens/chat_screen.dart';

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
    this.detailsFuture,
    this.initialApplication,
  });

  final int applicationId;

  /// Preferred entry path. Start this request from the previous screen before
  /// navigation, then pass the same Future here. This gives the route transition
  /// a head start without ever painting stale list/cache data as detail data.
  final Future<PilotApplicationDetailsResult>? detailsFuture;

  /// Kept only for source compatibility with older navigation calls.
  /// It is intentionally NOT rendered on first load.
  @Deprecated(
    'Pass detailsFuture instead. initialApplication is not displayed as fresh detail data.',
  )
  final PilotApplicationModel? initialApplication;

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  late final PilotApplicationService _applicationService;
  late final PilotJobService _jobService;
  late final DroneService _droneService;

  PilotApplicationModel? _application;
  ApplicationCompanyChatTarget? _companyChatTarget;

  bool _loading = true;
  bool _refreshing = false;
  bool _relationsLoading = false;
  bool _withdrawing = false;
  bool _openingChat = false;
  bool _changed = false;
  String? _error;

  int _loadSerial = 0;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    _applicationService = PilotApplicationService(apiClient);
    _jobService = PilotJobService(apiClient);
    _droneService = DroneService(apiClient);

    // IMPORTANT: no cached/list/initial object is assigned to _application.
    // First paint is a deliberate loading state until the authoritative detail
    // endpoint succeeds.
    unawaited(_loadAuthoritative(initialFuture: widget.detailsFuture));
  }

  // ---------------------------------------------------------------------------
  // AUTHORITATIVE DATA FLOW
  // ---------------------------------------------------------------------------

  Future<void> _loadAuthoritative({
    Future<PilotApplicationDetailsResult>? initialFuture,
    bool manual = false,
  }) async {
    final serial = ++_loadSerial;

    if (mounted) {
      setState(() {
        if (_application == null) {
          _loading = true;
        } else if (manual) {
          _refreshing = true;
        }
        _error = null;
      });
    }

    try {
      final result = await (initialFuture ??
          _applicationService.getApplicationDetailsResult(
            widget.applicationId,
          ));

      if (!mounted || serial != _loadSerial) return;

      // This is real detail-endpoint data. It can safely replace the loader.
      setState(() {
        _application = result.application;
        _companyChatTarget = result.companyChatTarget;
        _loading = false;
        _refreshing = false;
        _relationsLoading = _needsRelationHydration(result.application);
        _error = null;
      });

      await _hydrateRelations(
        result.application,
        serial: serial,
      );
    } catch (e) {
      if (!mounted || serial != _loadSerial) return;

      final hasRealData = _application != null;

      setState(() {
        _loading = false;
        _refreshing = false;
        _relationsLoading = false;
        if (!hasRealData) {
          _error = e.toString();
        }
      });

      if (hasRealData && manual) {
        _snack(
          'Couldn’t refresh right now. Your last loaded details are still shown.',
        );
      }
    }
  }

  bool _needsRelationHydration(PilotApplicationModel application) {
    return (application.job == null && application.jobPostingId > 0) ||
        (application.drone == null && application.droneId > 0);
  }

  Future<void> _hydrateRelations(
      PilotApplicationModel base, {
        required int serial,
      }) async {
    if (!_needsRelationHydration(base)) {
      if (!mounted || serial != _loadSerial) return;
      setState(() => _relationsLoading = false);
      return;
    }

    PilotJobModel? job = base.job;
    DroneModel? drone = base.drone;

    final Future<PilotJobModel?> jobFuture = job != null ||
        base.jobPostingId <= 0
        ? Future<PilotJobModel?>.value(job)
        : _safeLoadJob(base.jobPostingId);

    final Future<DroneModel?> droneFuture = drone != null || base.droneId <= 0
        ? Future<DroneModel?>.value(drone)
        : _safeLoadDrone(base.droneId);

    // Start both relation requests together.
    final values = await Future.wait<dynamic>([
      jobFuture,
      droneFuture,
    ]);

    job = values[0] as PilotJobModel?;
    drone = values[1] as DroneModel?;

    if (!mounted || serial != _loadSerial) return;

    setState(() {
      _application = base.copyWith(
        job: job,
        drone: drone,
      );
      _relationsLoading = false;
    });
  }

  Future<PilotJobModel?> _safeLoadJob(int jobId) async {
    try {
      return await _jobService.getJobDetails(jobId);
    } catch (_) {
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

  Future<void> _manualRefresh() async {
    if (_refreshing) return;
    HapticFeedback.selectionClick();
    await _loadAuthoritative(manual: true);
  }

  // ---------------------------------------------------------------------------
  // CHAT
  // ---------------------------------------------------------------------------

  Future<void> _openCompanyChat() async {
    final application = _application;
    if (application == null || !application.isAccepted || _openingChat) return;

    HapticFeedback.mediumImpact();
    setState(() => _openingChat = true);

    try {
      var target = _companyChatTarget;

      // Some API responses may expose company identity only through the Job
      // relationship. Resolve it lazily so the detail screen itself remains fast.
      target ??= await _applicationService.resolveCompanyChatTargetFromJob(
        application.jobPostingId,
      );

      if (!mounted) return;

      if (target == null || target.userId <= 0) {
        _snack(
          'Company chat is not available for this application yet.',
        );
        return;
      }

      final chatTarget = target;

      final currentUserId = await UserSessionStorage.getUserId();
      final currentUserName = await UserSessionStorage.getName();
      final currentUserPhoto =
          await UserSessionStorage.getProfilePhotoUrl() ?? '';

      if (!mounted) return;

      if (currentUserId == null || currentUserId <= 0) {
        _snack('Your account session could not be identified.');
        return;
      }

      final companyName = chatTarget.name.trim().isNotEmpty &&
          chatTarget.name.trim().toLowerCase() != 'company'
          ? chatTarget.name.trim()
          : application.companyLabel.trim().isNotEmpty
          ? application.companyLabel.trim()
          : 'Company';

      _companyChatTarget = chatTarget;

      setState(() => _openingChat = false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            currentUserId: currentUserId.toString(),
            currentUserName:
            currentUserName?.trim().isNotEmpty == true
                ? currentUserName!.trim()
                : 'Pilot',
            currentUserPhotoUrl: currentUserPhoto,
            partnerId: chatTarget.userId.toString(),
            partnerName: companyName,
            partnerPhotoUrl: chatTarget.photoUrl,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _snack('Couldn’t open company chat right now.');
      }
    } finally {
      if (mounted && _openingChat) {
        setState(() => _openingChat = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // WITHDRAW
  // ---------------------------------------------------------------------------

  Future<void> _withdraw() async {
    final application = _application;
    if (application == null || !application.isPending || _withdrawing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
          actionsPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          title: const Row(
            children: [
              _DialogIcon(),
              SizedBox(width: 10),
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
            'This pending application will be withdrawn and can no longer move forward.',
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
                  _TopBar(
                    onBack: _back,
                    onRefresh: _loading ? null : _manualRefresh,
                    refreshing: _refreshing,
                  ),
                  Expanded(
                    child: _loading && _application == null
                        ? const _PremiumLoadingState()
                        : _error != null && _application == null
                        ? _ErrorState(
                      message: _error!,
                      onRetry: () => _loadAuthoritative(),
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
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _HeroCard(
              application: application,
              visual: visual,
            ),
          ),
          const SizedBox(height: 13),
          _StatusJourney(application: application),
          if (application.isAccepted) ...[
            const SizedBox(height: 13),
            _CompanyChatSection(
              companyName: application.companyLabel,
              loading: _openingChat,
              onTap: _openCompanyChat,
            ),
          ],
          const SizedBox(height: 13),
          _ApplicationOverview(application: application),
          const SizedBox(height: 13),
          _jobSection(application),
          const SizedBox(height: 13),
          _droneSection(application),
          if (application.coverMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            _MessageSection(message: application.coverMessage),
          ],
          if (!application.isPending) ...[
            const SizedBox(height: 13),
            _DecisionSection(application: application),
          ],
        ],
      ),
    );
  }

  Widget _jobSection(PilotApplicationModel application) {
    final job = application.job;

    return _PremiumSection(
      icon: Icons.work_outline_rounded,
      eyebrow: 'MISSION',
      title: 'Job Overview',
      child: job == null && _relationsLoading
          ? const _InlineRelationLoader(kind: 'mission')
          : job == null
          ? _UnavailableRelation(
        icon: Icons.work_off_outlined,
        title: 'Mission details unavailable',
        message:
        'The application is valid, but this job’s full details are not currently accessible.',
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
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 9),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: job.detailedLocationLabel,
          ),
          const SizedBox(height: 14),
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
                  label: 'Mission date',
                  value: job.dateLabel,
                  color: AppColors.logoTurquoiseDark,
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

    return _PremiumSection(
      icon: Icons.flight_rounded,
      eyebrow: 'AIRCRAFT',
      title: 'Selected Drone',
      child: drone == null && _relationsLoading
          ? const _InlineRelationLoader(kind: 'aircraft')
          : drone == null
          ? _UnavailableRelation(
        icon: Icons.flight_outlined,
        title: 'Drone profile unavailable',
        message:
        'Drone #${application.droneId} is still linked to this application, but its full profile could not be loaded.',
      )
          : _DroneSummary(drone: drone),
    );
  }

  Widget? _bottomAction() {
    final application = _application;
    if (_loading || application == null || !application.isPending) return null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.05),
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
              side: BorderSide(
                color: AppColors.red.withOpacity(0.7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _withdrawing
                ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.red,
              ),
            )
                : const Icon(Icons.undo_rounded, size: 18),
            label: Text(
              _withdrawing ? 'Withdrawing...' : 'Withdraw Application',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.green : AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          content: Text(message),
        ),
      );
  }
}

// =============================================================================
// TOP / BACKGROUND
// =============================================================================

class _DetailsBackdrop extends StatelessWidget {
  const _DetailsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -170,
              right: -115,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF16C6C7).withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 260,
              left: -170,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(0.05),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onRefresh,
    required this.refreshing,
  });

  final VoidCallback onBack;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 9, 14, 7),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Details',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17.5,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Live status & mission overview',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: refreshing
                ? const _SyncPill(key: ValueKey('sync'))
                : _RoundButton(
              key: const ValueKey('refresh'),
              icon: Icons.refresh_rounded,
              onTap: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: onTap == null ? AppColors.lightGrey : AppColors.navy,
            size: 18,
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
      height: 37,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.logoTurquoiseDark.withOpacity(0.08),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.7,
              color: AppColors.logoTurquoiseDark,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Updating',
            style: TextStyle(
              color: AppColors.logoTurquoiseDark,
              fontSize: 9,
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
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06192A),
            Color(0xFF0A3850),
            Color(0xFF087984),
          ],
          stops: [0, 0.58, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07394A).withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -62,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 18,
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -42,
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: 132,
              color: Colors.white.withOpacity(0.035),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroStatusPill(
                      label: application.statusLabel,
                      color: visual.foreground,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'APP #${application.id}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 8.8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                Text(
                  application.jobTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21.5,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.55,
                  ),
                ),
                if (application.companyLabel.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        color: Colors.white.withOpacity(0.62),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          application.companyLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMiniInfo(
                        icon: Icons.schedule_rounded,
                        label: 'Submitted',
                        value: application.submittedLabel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroMiniInfo(
                        icon: Icons.flight_outlined,
                        label: 'Drone',
                        value: '#${application.droneId}',
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

class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.55),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMiniInfo extends StatelessWidget {
  const _HeroMiniInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.045)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.58), size: 13),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 7.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 9.5,
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

// =============================================================================
// JOURNEY
// =============================================================================

class _StatusJourney extends StatelessWidget {
  const _StatusJourney({required this.application});

  final PilotApplicationModel application;

  @override
  Widget build(BuildContext context) {
    final status = application.status.trim().toLowerCase();
    final accepted = status == 'accepted';
    final rejected = status == 'rejected';
    final withdrawn = status == 'withdrawn';
    final pending = !accepted && !rejected && !withdrawn;

    final finalColor = accepted
        ? AppColors.green
        : rejected
        ? AppColors.red
        : withdrawn
        ? AppColors.grey
        : AppColors.lightGrey;

    final finalLabel = accepted
        ? 'Accepted'
        : rejected
        ? 'Not selected'
        : withdrawn
        ? 'Withdrawn'
        : 'Decision';

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Application journey',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Spacer(),
              Icon(
                Icons.route_rounded,
                color: AppColors.logoTurquoiseDark,
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: _JourneyStep(
                  icon: Icons.send_rounded,
                  label: 'Submitted',
                  color: AppColors.green,
                  complete: true,
                ),
              ),
              _JourneyLine(
                color: pending ? AppColors.logoTurquoiseDark : AppColors.green,
              ),
              Expanded(
                child: _JourneyStep(
                  icon: pending
                      ? Icons.hourglass_top_rounded
                      : Icons.fact_check_outlined,
                  label: pending ? 'In review' : 'Reviewed',
                  color: pending
                      ? AppColors.logoTurquoiseDark
                      : AppColors.green,
                  complete: true,
                  pulse: pending,
                ),
              ),
              _JourneyLine(
                color: pending ? AppColors.cardBorder : finalColor,
              ),
              Expanded(
                child: _JourneyStep(
                  icon: accepted
                      ? Icons.check_rounded
                      : rejected
                      ? Icons.close_rounded
                      : withdrawn
                      ? Icons.undo_rounded
                      : Icons.flag_outlined,
                  label: finalLabel,
                  color: finalColor,
                  complete: !pending,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.icon,
    required this.label,
    required this.color,
    required this.complete,
    this.pulse = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool complete;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final effective = complete ? color : AppColors.lightGrey;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: effective.withOpacity(complete ? 0.10 : 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: effective.withOpacity(complete ? 0.26 : 0.10),
            ),
            boxShadow: pulse
                ? [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ]
                : null,
          ),
          child: Icon(icon, color: effective, size: 15),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: complete ? AppColors.navy : AppColors.lightGrey,
            fontSize: 8.7,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _JourneyLine extends StatelessWidget {
  const _JourneyLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// =============================================================================
// CHAT CTA
// =============================================================================

class _CompanyChatSection extends StatelessWidget {
  const _CompanyChatSection({
    required this.companyName,
    required this.loading,
    required this.onTap,
  });

  final String companyName;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = companyName.trim().isEmpty ? 'the company' : companyName;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9FBFA),
            Color(0xFFF8FFFF),
          ],
        ),
        border: Border.all(
          color: AppColors.logoTurquoiseDark.withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoTurquoiseDark.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -35,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.logoTurquoiseDark.withOpacity(0.055),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0D8AA5),
                            Color(0xFF16C6C7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.logoTurquoiseDark.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Company Communication',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your application was accepted',
                            style: TextStyle(
                              color: AppColors.green.withOpacity(0.92),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
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
                        color: AppColors.greenBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            color: AppColors.green,
                            size: 10,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'UNLOCKED',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Coordinate mission details directly with $displayName through your secure in-app chat.',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.8,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: FilledButton(
                    onPressed: loading ? null : onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.logoTurquoiseDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      AppColors.logoTurquoiseDark.withOpacity(0.55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: loading
                          ? const Row(
                        key: ValueKey('chat-loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Opening chat...',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                          : const Row(
                        key: ValueKey('chat-ready'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_rounded, size: 17),
                          SizedBox(width: 8),
                          Text(
                            'Chat with Company',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),
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
// SECTIONS
// =============================================================================

class _ApplicationOverview extends StatelessWidget {
  const _ApplicationOverview({required this.application});

  final PilotApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return _PremiumSection(
      icon: Icons.assignment_outlined,
      eyebrow: 'REFERENCE',
      title: 'Application Overview',
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

class _PremiumSection extends StatelessWidget {
  const _PremiumSection({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.028),
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
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8F9FA),
                      Color(0xFFF5FCFD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.logoTurquoiseDark.withOpacity(0.07),
                  ),
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
                      eyebrow,
                      style: TextStyle(
                        color: AppColors.logoTurquoiseDark.withOpacity(0.68),
                        fontSize: 7.4,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14.5,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
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

class _MessageSection extends StatelessWidget {
  const _MessageSection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _PremiumSection(
      icon: Icons.chat_bubble_outline_rounded,
      eyebrow: 'YOUR MESSAGE',
      title: 'Cover Message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.logoTurquoiseDark.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12.2,
                  height: 1.58,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection({required this.application});

  final PilotApplicationModel application;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(application.status);
    final accepted = application.isAccepted;
    final rejected = application.status.trim().toLowerCase() == 'rejected';
    final withdrawn = application.status.trim().toLowerCase() == 'withdrawn';

    final title = accepted
        ? 'Application Accepted'
        : rejected
        ? 'Application Not Selected'
        : withdrawn
        ? 'Application Withdrawn'
        : application.statusLabel;

    final message = accepted
        ? 'The company selected your application. Company communication is now available above.'
        : rejected
        ? 'This application was not selected for the mission.'
        : withdrawn
        ? 'You withdrew this application from the selection process.'
        : 'Your application status has been updated.';

    return _PremiumSection(
      icon: accepted
          ? Icons.verified_rounded
          : rejected
          ? Icons.cancel_outlined
          : Icons.fact_check_outlined,
      eyebrow: 'DECISION',
      title: 'Application Status',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: visual.foreground.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: visual.foreground.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    accepted
                        ? Icons.check_rounded
                        : rejected
                        ? Icons.close_rounded
                        : Icons.undo_rounded,
                    color: visual.foreground,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: visual.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.8,
                height: 1.45,
              ),
            ),
            if (application.decisionLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _DecisionMeta(
                label: 'Decision date',
                value: application.decisionLabel,
              ),
            ],
            if (application.withdrawnLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _DecisionMeta(
                label: 'Withdrawn',
                value: application.withdrawnLabel,
              ),
            ],
            if (application.rejectionReason.trim().isNotEmpty) ...[
              const SizedBox(height: 11),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      application.rejectionReason,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionMeta extends StatelessWidget {
  const _DecisionMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 9.3,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 9.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SMALL UI
// =============================================================================

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9FA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: AppColors.logoTurquoiseDark,
              size: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 7.9,
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
        color: const Color(0xFFF8FAFC),
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
                    fontSize: 8.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10.5,
                    height: 1.2,
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
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.grey, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
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
        ),
      ],
    );
  }
}

class _DroneSummary extends StatelessWidget {
  const _DroneSummary({required this.drone});

  final DroneModel drone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (drone.yearLabel.trim().isNotEmpty)
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
          width: 31,
          height: 31,
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
    );
  }
}

class _DroneThumbnail extends StatelessWidget {
  const _DroneThumbnail({required this.drone});

  final DroneModel drone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 72,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16C6C7), Color(0xFFE7F0F4)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
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
  const _SmallPill({required this.icon, required this.text});

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
              fontSize: 8.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableRelation extends StatelessWidget {
  const _UnavailableRelation({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.lightGrey, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.5,
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

class _InlineRelationLoader extends StatelessWidget {
  const _InlineRelationLoader({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.logoTurquoiseDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Loading latest $kind details...',
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STATUS VISUALS
// =============================================================================

class _StatusVisual {
  final Color foreground;
  final Color background;

  const _StatusVisual(this.foreground, this.background);
}

_StatusVisual _statusVisual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted':
      return const _StatusVisual(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return const _StatusVisual(AppColors.red, AppColors.redBg);
    case 'withdrawn':
      return _StatusVisual(AppColors.grey, Colors.grey.shade100);
    default:
      return const _StatusVisual(
        AppColors.logoTurquoiseDark,
        Color(0xFFEAF9FA),
      );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.redBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.undo_rounded,
        color: AppColors.red,
        size: 19,
      ),
    );
  }
}

// =============================================================================
// LOADING / ERROR
// =============================================================================

class _PremiumLoadingState extends StatelessWidget {
  const _PremiumLoadingState();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerLoader();
  }
}

class _ShimmerLoader extends StatefulWidget {
  const _ShimmerLoader();

  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
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
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.logoTurquoiseDark,
                    ),
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loading latest application details',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Getting the current status directly from the server...',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            _box(188, 27),
            const SizedBox(height: 13),
            _box(114, 21),
            const SizedBox(height: 13),
            _box(156, 22),
            const SizedBox(height: 13),
            _box(148, 22),
          ],
        );
      },
    );
  }

  Widget _box(double height, double radius) {
    final t = _controller.value;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + 3.6 * t, 0),
          end: Alignment(-0.8 + 3.6 * t, 0),
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9FA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.logoTurquoiseDark.withOpacity(0.08),
                ),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.logoTurquoiseDark,
                size: 29,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Couldn’t load application details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
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

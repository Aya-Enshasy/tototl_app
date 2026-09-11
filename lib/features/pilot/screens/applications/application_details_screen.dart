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
import '../message/messages_screen.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  const ApplicationDetailsScreen({
    super.key,
    required this.applicationId,
    this.detailsFuture,
    this.initialApplication,
  });

  final int applicationId;

  /// Preferred navigation path. The caller may start this network request before
  /// the route transition. It is still not rendered until every relation we can
  /// authoritatively resolve has completed its first hydration attempt.
  final Future<PilotApplicationDetailsResult>? detailsFuture;

  /// Retained only so older call sites still compile. It is NEVER painted as
  /// detail data. This prevents list/default values from flashing before the
  /// authoritative detail response arrives.
  @Deprecated(
    'Use detailsFuture. initialApplication is not rendered on first load.',
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

    // Deliberately leave _application null. First paint is shimmer only.
    unawaited(
      _loadAuthoritative(initialFuture: widget.detailsFuture),
    );
  }

  // ---------------------------------------------------------------------------
  // AUTHORITATIVE + ATOMIC DATA FLOW
  // ---------------------------------------------------------------------------

  Future<void> _loadAuthoritative({
    Future<PilotApplicationDetailsResult>? initialFuture,
    bool manual = false,
  }) async {
    final serial = ++_loadSerial;
    final hadRealData = _application != null;

    if (mounted) {
      setState(() {
        if (!hadRealData) {
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

      // Do not publish the bare application yet. /applications/{id} is the
      // authoritative application record, but the job/drone relations are not
      // guaranteed by the API. Resolve both off-screen first.
      final hydrated = await _hydrateBeforePaint(result.application);

      if (!mounted || serial != _loadSerial) return;

      // One atomic swap: shimmer -> correct data. No fake/default intermediate.
      setState(() {
        _application = hydrated;
        _companyChatTarget = result.companyChatTarget;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || serial != _loadSerial) return;

      setState(() {
        _loading = false;
        _refreshing = false;
        if (!hadRealData) {
          _error = e.toString();
        }
      });

      if (hadRealData && manual) {
        _snack(
          'Couldn’t refresh right now. The last confirmed details are still shown.',
        );
      }
    }
  }

  Future<PilotApplicationModel> _hydrateBeforePaint(
      PilotApplicationModel base,
      ) async {
    final jobFuture = base.job != null || base.jobPostingId <= 0
        ? Future<PilotJobModel?>.value(base.job)
        : _safeLoadJob(base.jobPostingId);

    final droneFuture = base.drone != null || base.droneId <= 0
        ? Future<DroneModel?>.value(base.drone)
        : _safeLoadDrone(base.droneId);

    final values = await Future.wait<dynamic>([
      jobFuture,
      droneFuture,
    ]);

    final job = values[0] as PilotJobModel?;
    final drone = values[1] as DroneModel?;

    return base.copyWith(
      job: job,
      drone: drone,
    );
  }

  Future<PilotJobModel?> _safeLoadJob(int jobId) async {
    try {
      return await _jobService.getJobDetails(jobId);
    } catch (_) {
      // Old closed/cancelled jobs may not be visible through the pilot's
      // Published-only job endpoint. Missing data stays missing — never fake it.
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
      final target = _companyChatTarget ??
          await _applicationService.resolveCompanyChatTargetFromJob(
            application.jobPostingId,
          );

      if (!mounted) return;

      // Firebase chat must use the COMPANY USER ID, not company_profile_id.
      if (target == null || target.userId <= 0) {
        _snack('Company chat is not available for this application yet.');
        return;
      }

      final realCompany = application.job == null
          ? ''
          : application.companyLabel.trim();

      final companyName = target.name.trim().isNotEmpty &&
          target.name.trim().toLowerCase() != 'company'
          ? target.name.trim()
          : realCompany.isNotEmpty
          ? realCompany
          : 'Company';

      _companyChatTarget = target;

      if (mounted) {
        setState(() => _openingChat = false);
      }

      // MessagesScreen is now the single bridge into chat:
      // - current user id/name/photo -> UserSessionStorage
      // - company user id/name/photo -> accepted application/job target
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessagesScreen(
            companyUserId: target.userId,
            companyName: companyName,
            companyPhotoUrl: target.photoUrl,
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
              _WithdrawDialogIcon(),
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

      // The mutation response may not contain relations. Keep only relations that
      // were already confirmed from network on this screen.
      final hydrated = updated.copyWith(
        job: application.job,
        drone: application.drone,
      );

      if (!mounted) return;

      setState(() {
        _application = hydrated;
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
                    onRefresh: _loading || _refreshing ? null : _manualRefresh,
                    refreshing: _refreshing,
                  ),
                  Expanded(
                    child: _loading && _application == null
                        ? const _DetailsPageShimmer()
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

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 36),
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 13 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _HeroCard(
            application: application,
            visual: visual,
          ),
        ),
        const SizedBox(height: 14),
        _StatusJourney(application: application),
        if (application.isAccepted) ...[
          const SizedBox(height: 14),
          _CompanyChatCard(
            companyName: application.job == null
                ? ''
                : application.companyLabel.trim(),
            busy: _openingChat,
            onTap: _openCompanyChat,
          ),
        ],
        const SizedBox(height: 14),
        _ApplicationSnapshot(application: application),
        const SizedBox(height: 14),
        _jobSection(application),
        const SizedBox(height: 14),
        _droneSection(application),
        if (application.coverMessage.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _MessageSection(message: application.coverMessage.trim()),
        ],
        if (!application.isPending) ...[
          const SizedBox(height: 14),
          _DecisionSection(application: application),
        ],
      ],
    );
  }

  Widget _jobSection(PilotApplicationModel application) {
    final job = application.job;

    return _PremiumSection(
      icon: Icons.work_outline_rounded,
      eyebrow: 'MISSION',
      title: 'Mission Details',
      child: job == null
          ? _UnavailableRelation(
        icon: Icons.work_off_outlined,
        title: 'Job #${application.jobPostingId}',
        message:
        'Full mission details are not available from the current pilot endpoint. No replacement data is being invented.',
      )
          : _JobContent(
        job: job,
        companyName: application.companyLabel.trim(),
      ),
    );
  }

  Widget _droneSection(PilotApplicationModel application) {
    final drone = application.drone;

    return _PremiumSection(
      icon: Icons.flight_rounded,
      eyebrow: 'AIRCRAFT',
      title: 'Committed Drone',
      child: drone == null
          ? _UnavailableRelation(
        icon: Icons.flight_outlined,
        title: 'Drone #${application.droneId}',
        message:
        'This is the real drone ID linked to the application. Its full profile could not be retrieved.',
      )
          : _DroneContent(drone: drone),
    );
  }

  Widget? _bottomAction() {
    final application = _application;

    if (_loading || application == null || !application.isPending) {
      return null;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.985),
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.055),
              blurRadius: 24,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _withdrawing ? null : _withdraw,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(
                color: AppColors.red.withOpacity(0.48),
              ),
              backgroundColor: AppColors.red.withOpacity(0.025),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _withdrawing
                  ? const Row(
                key: ValueKey('withdrawing'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionDots(color: AppColors.red),
                  SizedBox(width: 9),
                  Text(
                    'Withdrawing...',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              )
                  : const Row(
                key: ValueKey('withdraw'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.undo_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Withdraw Application',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
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
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(message),
        ),
      );
  }
}

// =============================================================================
// BACKGROUND + TOP BAR
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
              top: -180,
              right: -120,
              child: Container(
                width: 340,
                height: 340,
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
              top: 380,
              left: -175,
              child: Container(
                width: 310,
                height: 310,
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
      padding: const EdgeInsets.fromLTRB(11, 10, 14, 8),
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
                    fontSize: 16,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Verified application record',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          refreshing
              ? const _SyncBadge()
              : _RoundButton(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
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
                color: AppColors.navy.withOpacity(0.03),
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

class _SyncBadge extends StatelessWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FAFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.logoTurquoiseDark.withOpacity(0.10),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionDots(color: AppColors.logoTurquoiseDark),
          SizedBox(width: 7),
          Text(
            'SYNCING',
            style: TextStyle(
              color: AppColors.logoTurquoiseDark,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionDots extends StatefulWidget {
  const _ActionDots({required this.color});

  final Color color;

  @override
  State<_ActionDots> createState() => _ActionDotsState();
}

class _ActionDotsState extends State<_ActionDots>
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
            final phase = (_controller.value + index * 0.22) % 1;
            final strength = 1 - (phase - 0.5).abs() * 2;
            return Container(
              width: 4.5,
              height: 4.5,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 3),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(
                  (0.28 + 0.72 * strength).clamp(0.28, 1.0).toDouble(),
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
    final job = application.job;
    final realTitle = job?.title.trim() ?? '';
    final title = realTitle.isNotEmpty
        ? realTitle
        : 'Application #${application.id}';

    final company = job == null ? '' : application.companyLabel.trim();
    final droneName = application.drone?.title.trim() ?? '';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06182A),
            Color(0xFF0A3A50),
            Color(0xFF087D85),
          ],
          stops: [0, 0.60, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF063E4D).withOpacity(0.22),
            blurRadius: 32,
            offset: const Offset(0, 14),
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
                  color: Colors.white.withOpacity(0.055),
                  width: 18,
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -43,
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: 138,
              color: Colors.white.withOpacity(0.035),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 19, 19, 19),
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
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                if (company.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        color: Colors.white.withOpacity(0.60),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.79),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 9),
                  Text(
                    'Job #${application.jobPostingId}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 19),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMiniInfo(
                        icon: Icons.schedule_rounded,
                        label: 'Submitted',
                        value: application.submittedLabel,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _HeroMiniInfo(
                        icon: Icons.flight_outlined,
                        label: 'Aircraft',
                        value: droneName.isNotEmpty
                            ? droneName
                            : 'Drone #${application.droneId}',
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
  const _HeroStatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
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
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF80E2DE), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.47),
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.91),
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
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
// STATUS JOURNEY
// =============================================================================

class _StatusJourney extends StatelessWidget {
  const _StatusJourney({required this.application});

  final PilotApplicationModel application;

  @override
  Widget build(BuildContext context) {
    final status = application.status.trim().toLowerCase();
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final isRejected = status == 'rejected';
    final isWithdrawn = status == 'withdrawn';

    final decisionColor = isAccepted
        ? AppColors.green
        : isRejected
        ? AppColors.red
        : isWithdrawn
        ? AppColors.grey
        : AppColors.lightGrey;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.route_outlined,
                color: AppColors.logoTurquoiseDark,
                size: 17,
              ),
              SizedBox(width: 8),
              Text(
                'APPLICATION JOURNEY',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.55,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const _JourneyNode(
                icon: Icons.send_rounded,
                label: 'Submitted',
                color: AppColors.logoTurquoiseDark,
                active: true,
              ),
              Expanded(
                child: _JourneyLine(
                  active: true,
                  color: isPending ? const Color(0xFFE99A18) : decisionColor,
                ),
              ),
              _JourneyNode(
                icon: isPending
                    ? Icons.schedule_rounded
                    : Icons.fact_check_outlined,
                label: isPending ? 'In review' : 'Reviewed',
                color: isPending ? const Color(0xFFE99A18) : decisionColor,
                active: true,
              ),
              Expanded(
                child: _JourneyLine(
                  active: !isPending,
                  color: decisionColor,
                ),
              ),
              _JourneyNode(
                icon: isAccepted
                    ? Icons.verified_rounded
                    : isRejected
                    ? Icons.close_rounded
                    : isWithdrawn
                    ? Icons.undo_rounded
                    : Icons.flag_outlined,
                label: isAccepted
                    ? 'Accepted'
                    : isRejected
                    ? 'Rejected'
                    : isWithdrawn
                    ? 'Withdrawn'
                    : 'Decision',
                color: decisionColor,
                active: !isPending,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.10) : AppColors.bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? color.withOpacity(0.22) : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: active ? color : AppColors.lightGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppColors.navy : AppColors.lightGrey,
              fontSize: 8.3,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyLine extends StatelessWidget {
  const _JourneyLine({
    required this.active,
    required this.color,
  });

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.42) : AppColors.cardBorder,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// =============================================================================
// SNAPSHOT
// =============================================================================

class _ApplicationSnapshot extends StatelessWidget {
  const _ApplicationSnapshot({required this.application});

  final PilotApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return _PremiumSection(
      icon: Icons.grid_view_rounded,
      eyebrow: 'RECORD',
      title: 'Application Snapshot',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SnapshotTile(
                  icon: Icons.tag_rounded,
                  label: 'Application',
                  value: '#${application.id}',
                  tint: AppColors.blue,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SnapshotTile(
                  icon: Icons.work_outline_rounded,
                  label: 'Job',
                  value: '#${application.jobPostingId}',
                  tint: AppColors.logoTurquoiseDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _SnapshotTile(
                  icon: Icons.flight_outlined,
                  label: 'Drone',
                  value: '#${application.droneId}',
                  tint: AppColors.green,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SnapshotTile(
                  icon: Icons.schedule_rounded,
                  label: 'Submitted',
                  value: application.submittedLabel,
                  tint: const Color(0xFFE99A18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 9.8,
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
// PREMIUM SECTION
// =============================================================================

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
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.035),
            blurRadius: 20,
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
                    colors: [Color(0xFFE7FAFA), Color(0xFFF0F6FA)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.logoTurquoiseDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: AppColors.logoTurquoiseDark,
                        fontSize: 7.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.75,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
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

// =============================================================================
// JOB
// =============================================================================

class _JobContent extends StatelessWidget {
  const _JobContent({
    required this.job,
    required this.companyName,
  });

  final PilotJobModel job;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final location = job.detailedLocationLabel.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16.5,
            height: 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
        if (companyName.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.business_outlined,
            text: companyName,
          ),
        ],
        if (location.isNotEmpty && location.toLowerCase() != 'not specified') ...[
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: location,
          ),
        ],
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _MissionMetric(
                icon: Icons.payments_outlined,
                label: 'Mission Value',
                value: job.payLabel,
                tint: AppColors.green,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _MissionMetric(
                icon: Icons.calendar_month_outlined,
                label: 'Mission Date',
                value: job.dateLabel,
                tint: AppColors.logoTurquoiseDark,
              ),
            ),
          ],
        ),
      ],
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
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10.8,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionMetric extends StatelessWidget {
  const _MissionMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: tint.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
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

// =============================================================================
// DRONE
// =============================================================================

class _DroneContent extends StatelessWidget {
  const _DroneContent({required this.drone});

  final DroneModel drone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          _DroneThumb(drone: drone),
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
                    fontSize: 15,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    if (drone.yearLabel.trim().isNotEmpty)
                      _MicroChip(
                        icon: Icons.calendar_today_outlined,
                        label: drone.yearLabel,
                      ),
                    if (drone.flightTimeLabel.trim().isNotEmpty)
                      _MicroChip(
                        icon: Icons.timer_outlined,
                        label: drone.flightTimeLabel,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
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
      ),
    );
  }
}

class _DroneThumb extends StatelessWidget {
  const _DroneThumb({required this.drone});

  final DroneModel drone;

  @override
  Widget build(BuildContext context) {
    final url = drone.imageUrl.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 68,
        height: 68,
        child: url.isEmpty
            ? Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE5FAFA), Color(0xFFEAF1F8)],
            ),
          ),
          child: const Icon(
            Icons.flight_takeoff_rounded,
            color: AppColors.logoTurquoiseDark,
            size: 27,
          ),
        )
            : Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const _ImageShimmer();
          },
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.bg,
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.logoTurquoiseDark,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageShimmer extends StatefulWidget {
  const _ImageShimmer();

  @override
  State<_ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<_ImageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.8 + 3.6 * t, 0),
              end: Alignment(-0.8 + 3.6 * t, 0),
              colors: const [
                Color(0xFFEDF2F5),
                Color(0xFFF9FBFC),
                Color(0xFFEDF2F5),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MicroChip extends StatelessWidget {
  const _MicroChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 8.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CHAT
// =============================================================================

class _CompanyChatCard extends StatelessWidget {
  const _CompanyChatCard({
    required this.companyName,
    required this.busy,
    required this.onTap,
  });

  final String companyName;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = companyName.isEmpty ? 'Company' : companyName;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9FAF6), Color(0xFFF7FCFB)],
        ),
        border: Border.all(color: AppColors.green.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.green.withOpacity(0.10)),
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: AppColors.green,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIRECT COMMUNICATION',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 7.8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Your accepted application can now move into coordination.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 9.4,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: busy ? null : onTap,
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: busy
                        ? const _ActionDots(color: Colors.white)
                        : const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
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
// MESSAGE / DECISION
// =============================================================================

class _MessageSection extends StatelessWidget {
  const _MessageSection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _PremiumSection(
      icon: Icons.notes_rounded,
      eyebrow: 'SUBMISSION',
      title: 'Cover Message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.75)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 11.5,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
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
    final rejection = application.rejectionReason.trim();

    String detail = application.decisionLabel.trim();
    if (detail.isEmpty && application.status.trim().toLowerCase() == 'withdrawn') {
      detail = application.withdrawnLabel.trim();
    }

    return _PremiumSection(
      icon: visual.icon,
      eyebrow: 'OUTCOME',
      title: 'Application Decision',
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
                Icon(visual.icon, color: visual.foreground, size: 18),
                const SizedBox(width: 8),
                Text(
                  application.statusLabel,
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ],
            if (rejection.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rejection,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// UNAVAILABLE RELATION
// =============================================================================

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(icon, color: AppColors.grey, size: 17),
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
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.8,
                    height: 1.45,
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

class _WithdrawDialogIcon extends StatelessWidget {
  const _WithdrawDialogIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: const BoxDecoration(
        color: AppColors.redBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.undo_rounded,
        color: AppColors.red,
        size: 18,
      ),
    );
  }
}

// =============================================================================
// STATUS VISUAL
// =============================================================================

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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE7FAFA), Color(0xFFF0F6FA)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.logoTurquoiseDark,
                size: 31,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Couldn’t load this application',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
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
// FULL PAGE SHIMMER — NOTHING FAKE IS PAINTED BEFORE REAL DATA
// =============================================================================

class _DetailsPageShimmer extends StatefulWidget {
  const _DetailsPageShimmer();

  @override
  State<_DetailsPageShimmer> createState() => _DetailsPageShimmerState();
}

class _DetailsPageShimmerState extends State<_DetailsPageShimmer>
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
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 36),
          children: [
            _HeroLoadingCard(animation: _controller),
            const SizedBox(height: 14),
            _JourneyLoadingCard(animation: _controller),
            const SizedBox(height: 14),
            _SectionLoadingCard(animation: _controller, height: 172),
            const SizedBox(height: 14),
            _SectionLoadingCard(animation: _controller, height: 190),
            const SizedBox(height: 14),
            _SectionLoadingCard(animation: _controller, height: 150),
          ],
        );
      },
    );
  }
}

class _HeroLoadingCard extends StatelessWidget {
  const _HeroLoadingCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3448),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(
                animation: animation,
                width: 76,
                height: 24,
                radius: 12,
                dark: true,
              ),
              const Spacer(),
              _ShimmerBlock(
                animation: animation,
                width: 57,
                height: 23,
                radius: 12,
                dark: true,
              ),
            ],
          ),
          const SizedBox(height: 21),
          _ShimmerBlock(
            animation: animation,
            width: double.infinity,
            height: 22,
            radius: 8,
            dark: true,
          ),
          const SizedBox(height: 9),
          _ShimmerBlock(
            animation: animation,
            width: 210,
            height: 18,
            radius: 7,
            dark: true,
          ),
          const SizedBox(height: 11),
          _ShimmerBlock(
            animation: animation,
            width: 128,
            height: 10,
            radius: 5,
            dark: true,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _HeroMiniLoading(animation: animation),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _HeroMiniLoading(animation: animation),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniLoading extends StatelessWidget {
  const _HeroMiniLoading({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ShimmerBlock(
            animation: animation,
            width: 18,
            height: 18,
            radius: 9,
            dark: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShimmerBlock(
                  animation: animation,
                  width: 45,
                  height: 7,
                  radius: 4,
                  dark: true,
                ),
                const SizedBox(height: 6),
                _ShimmerBlock(
                  animation: animation,
                  width: double.infinity,
                  height: 9,
                  radius: 5,
                  dark: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyLoadingCard extends StatelessWidget {
  const _JourneyLoadingCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBlock(
            animation: animation,
            width: 135,
            height: 10,
            radius: 5,
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Column(
                  children: [
                    _ShimmerBlock(
                      animation: animation,
                      width: 34,
                      height: 34,
                      radius: 17,
                    ),
                    const SizedBox(height: 6),
                    _ShimmerBlock(
                      animation: animation,
                      width: 46,
                      height: 7,
                      radius: 4,
                    ),
                  ],
                ),
                if (i < 2)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ShimmerBlock(
                        animation: animation,
                        width: double.infinity,
                        height: 2,
                        radius: 1,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLoadingCard extends StatelessWidget {
  const _SectionLoadingCard({
    required this.animation,
    required this.height,
  });

  final Animation<double> animation;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(
                animation: animation,
                width: 39,
                height: 39,
                radius: 13,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBlock(
                    animation: animation,
                    width: 54,
                    height: 7,
                    radius: 4,
                  ),
                  const SizedBox(height: 6),
                  _ShimmerBlock(
                    animation: animation,
                    width: 125,
                    height: 13,
                    radius: 6,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ShimmerBlock(
            animation: animation,
            width: double.infinity,
            height: 14,
            radius: 6,
          ),
          const SizedBox(height: 9),
          _ShimmerBlock(
            animation: animation,
            width: 220,
            height: 10,
            radius: 5,
          ),
          if (height > 175) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _ShimmerBlock(
                    animation: animation,
                    width: double.infinity,
                    height: 48,
                    radius: 14,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ShimmerBlock(
                    animation: animation,
                    width: double.infinity,
                    height: 48,
                    radius: 14,
                  ),
                ),
              ],
            ),
          ],
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
        ? Colors.white.withOpacity(0.075)
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
          begin: Alignment(-1.8 + 3.6 * t, 0),
          end: Alignment(-0.8 + 3.6 * t, 0),
          colors: [base, highlight, base],
        ),
      ),
    );
  }
}

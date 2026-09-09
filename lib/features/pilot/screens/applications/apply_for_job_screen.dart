import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import '../../models/drone_model.dart';
import '../../models/pilot_job_model.dart';
import '../../services/drone_service.dart';
import '../../services/pilot_application_service.dart';
import 'application_details_screen.dart';

class ApplyForJobScreen extends StatefulWidget {
  const ApplyForJobScreen({
    super.key,
    required this.job,
  });

  final PilotJobModel job;

  @override
  State<ApplyForJobScreen> createState() => _ApplyForJobScreenState();
}

class _ApplyForJobScreenState extends State<ApplyForJobScreen> {
  final TextEditingController _coverController = TextEditingController();

  late final DroneService _droneService;
  late final PilotApplicationService _applicationService;

  final List<DroneModel> _drones = <DroneModel>[];

  int? _selectedDroneId;
  bool _loading = true;
  bool _refreshingFleet = false;
  bool _submitting = false;
  String? _error;

  DroneModel? get _selectedDrone {
    final id = _selectedDroneId;
    if (id == null) return null;

    for (final drone in _drones) {
      if (drone.id == id) return drone;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    _droneService = DroneService(ApiClient());
    _applicationService = PilotApplicationService(ApiClient());

    _bootstrapDrones();
  }

  @override
  void dispose() {
    _coverController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOCAL-FIRST FLEET
  // ---------------------------------------------------------------------------

  Future<void> _bootstrapDrones() async {
    final cached = await _droneService.getCachedDrones();

    if (!mounted) return;

    if (cached != null) {
      setState(() {
        _replaceDrones(cached);
        _loading = false;
        _error = null;
      });

      unawaited(_refreshDronesSilently());
      return;
    }

    await _loadDronesBlocking();
  }

  Future<void> _loadDronesBlocking() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _droneService.getMyDrones();

      if (!mounted) return;

      setState(() {
        _replaceDrones(result);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshDronesSilently() async {
    if (_refreshingFleet) return;

    setState(() {
      _refreshingFleet = true;
    });

    try {
      final result = await _droneService.getMyDrones();

      if (!mounted) return;

      setState(() {
        _replaceDrones(result);
        _refreshingFleet = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _refreshingFleet = false;
      });
    }
  }

  void _replaceDrones(List<DroneModel> result) {
    final previousSelection = _selectedDroneId;

    _drones
      ..clear()
      ..addAll(result);

    if (_drones.isEmpty) {
      _selectedDroneId = null;
      return;
    }

    final previousStillExists = previousSelection != null &&
        _drones.any((item) => item.id == previousSelection);

    if (previousStillExists) {
      _selectedDroneId = previousSelection;
      return;
    }

    if (_drones.length == 1) {
      _selectedDroneId = _drones.first.id;
    } else {
      _selectedDroneId = null;
    }
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_submitting) return;

    final drone = _selectedDrone;

    if (drone == null) {
      _snack('Select one of your registered drones first.');
      return;
    }

    if (widget.job.application?.hasApplied == true) {
      _snack('You already applied to this job.');
      return;
    }

    final cover = _coverController.text.trim();

    if (cover.length > 2000) {
      _snack('Cover message cannot exceed 2000 characters.');
      return;
    }

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);

    try {
      final result = await _applicationService.applyToJob(
        jobId: widget.job.id,
        droneId: drone.id,
        coverMessage: cover.isEmpty ? null : cover,
      );

      if (!mounted) return;

      // Start a fresh detail request before opening the next screen. The
      // response returned by Apply is valid, but the details endpoint is the
      // authoritative source for the detail page and may contain newer fields.
      final detailsFuture =
      _applicationService.getApplicationDetailsResult(result.id);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ApplicationDetailsScreen(
            applicationId: result.id,
            detailsFuture: detailsFuture,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _submitting = false);
      _snack(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ApplyBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _loading
                      ? const _PageShimmer()
                      : _error != null
                      ? _LoadError(
                    message: _error!,
                    onRetry: _loadDronesBlocking,
                  )
                      : _content(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      _loading || _error != null ? null : _bottomBar(),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 16, 7),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _submitting
                ? null
                : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply for Job',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Choose your aircraft and send your application',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_refreshingFleet) const _SyncPill(),
        ],
      ),
    );
  }

  Widget _content() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      children: [
        _JobHero(job: widget.job),
        const SizedBox(height: 20),
        _StepHeader(
          number: '01',
          title: 'Select your aircraft',
          subtitle:
          'Choose the registered drone you will use for this mission.',
          icon: Icons.flight_takeoff_rounded,
          trailing: _refreshingFleet ? 'Updating fleet' : null,
        ),
        const SizedBox(height: 12),
        if (_drones.isEmpty)
          const _NoDrones()
        else
          ..._drones.map(
                (drone) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DroneCard(
                drone: drone,
                job: widget.job,
                selected: _selectedDroneId == drone.id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDroneId = drone.id);
                },
              ),
            ),
          ),
        const SizedBox(height: 10),
        const _StepHeader(
          number: '02',
          title: 'Add a cover message',
          subtitle:
          'Optional — briefly explain why you are a strong fit for the mission.',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        const SizedBox(height: 12),
        _CoverMessageCard(controller: _coverController),
        const SizedBox(height: 13),
        const _PrivacyNote(),
      ],
    );
  }

  Widget _bottomBar() {
    final canSubmit = !_submitting &&
        _drones.isNotEmpty &&
        _selectedDroneId != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.05),
              blurRadius: 22,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.logoTurquoiseDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.lightGrey.withOpacity(0.3),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                _submitting
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
                key: ValueKey(_submitting),
                size: 18,
              ),
            ),
            label: Text(
              _submitting
                  ? 'Submitting application...'
                  : _selectedDroneId == null && _drones.isNotEmpty
                  ? 'Select a drone to continue'
                  : 'Submit Application',
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

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
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

class _ApplyBackdrop extends StatelessWidget {
  const _ApplyBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -165,
          right: -130,
          child: Container(
            width: 335,
            height: 335,
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
          top: 390,
          left: -165,
          child: Container(
            width: 300,
            height: 300,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            icon,
            color: onTap == null
                ? AppColors.lightGrey
                : AppColors.navy,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'Updating',
            style: TextStyle(
              color: AppColors.logoTurquoiseDark,
              fontSize: 8.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// JOB HERO
// =============================================================================

class _JobHero extends StatelessWidget {
  const _JobHero({required this.job});

  final PilotJobModel job;

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
            Color(0xFF0A4056),
            Color(0xFF087E8D),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF083B4E).withOpacity(0.16),
            blurRadius: 27,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -55,
            child: Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5DE1D9).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -76,
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
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
            child: Column(
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
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        job.categoryLabel,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.work_outline_rounded,
                      color: Color(0xFF8AECE8),
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMeta(
                        icon: Icons.location_on_outlined,
                        text: job.locationLabel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF61E1D7).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF87F0EA).withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        job.payLabel,
                        style: const TextStyle(
                          color: Color(0xFF9CF3EE),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
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

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.64),
          size: 13,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.73),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STEP HEADER
// =============================================================================

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE9FAFA),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFF16C6C7).withOpacity(0.10),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.logoTurquoiseDark,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    number,
                    style: TextStyle(
                      color: AppColors.logoTurquoiseDark.withOpacity(0.65),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 10.3,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FAFA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.logoTurquoiseDark,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// DRONE CARD
// =============================================================================

class _DroneCard extends StatelessWidget {
  const _DroneCard({
    required this.drone,
    required this.job,
    required this.selected,
    required this.onTap,
  });

  final DroneModel drone;
  final PilotJobModel job;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final required = job.requiredCapabilities.map(_normalize).toSet();
    final available = drone.capabilities.map(_normalize).toSet();
    final matched = required.where(available.contains).length;
    final fullMatch = required.isEmpty || matched == required.length;

    final matchColor = fullMatch
        ? AppColors.green
        : const Color(0xFFE99A18);

    final matchBg = fullMatch
        ? AppColors.greenBg
        : const Color(0xFFFFF4E5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.logoTurquoiseDark
                  : AppColors.cardBorder,
              width: selected ? 1.45 : 0.85,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.logoTurquoiseDark.withOpacity(0.10)
                    : AppColors.navy.withOpacity(0.035),
                blurRadius: selected ? 22 : 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DroneImage(drone: drone),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drone.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (drone.yearLabel.isNotEmpty) ...[
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.grey,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            drone.yearLabel,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (drone.yearLabel.isNotEmpty &&
                            drone.flightTimeLabel != 'Not specified')
                          Container(
                            width: 3,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.lightGrey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (drone.flightTimeLabel != 'Not specified')
                          Flexible(
                            child: Text(
                              drone.flightTimeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: matchBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        required.isEmpty
                            ? 'Compatible with this job'
                            : fullMatch
                            ? 'Full capability match'
                            : '$matched/${required.length} capability match',
                        style: TextStyle(
                          color: matchColor,
                          fontSize: 8.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.logoTurquoiseDark
                      : AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.logoTurquoiseDark
                        : AppColors.cardBorder,
                  ),
                ),
                child: Icon(
                  selected
                      ? Icons.check_rounded
                      : Icons.circle_outlined,
                  color: selected ? Colors.white : AppColors.lightGrey,
                  size: selected ? 17 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_\s-]+'), ' ');
  }
}

class _DroneImage extends StatelessWidget {
  const _DroneImage({required this.drone});

  final DroneModel drone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 70,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16C6C7).withOpacity(0.75),
            AppColors.cardBorder,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(13),
          bottomLeft: Radius.circular(13),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(19),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(19),
        ),
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
        size: 27,
      ),
    );
  }
}

// =============================================================================
// COVER MESSAGE
// =============================================================================

class _CoverMessageCard extends StatelessWidget {
  const _CoverMessageCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        minLines: 5,
        maxLines: 8,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 12.5,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText:
          'Tell the company about your experience, equipment, or approach to this mission...',
          hintStyle: TextStyle(
            color: AppColors.grey.withOpacity(0.62),
            fontSize: 11.5,
            height: 1.45,
          ),
          counterStyle: const TextStyle(
            color: AppColors.lightGrey,
            fontSize: 9,
          ),
          filled: true,
          fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.all(14),
          border: _border(AppColors.cardBorder),
          enabledBorder: _border(AppColors.cardBorder),
          focusedBorder: _border(
            AppColors.logoTurquoiseDark,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(
      Color color, {
        double width = 0.8,
      }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF16C6C7).withOpacity(0.09),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.logoTurquoiseDark,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your selected registered aircraft will be attached to this application for the company to review.',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 10.2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY / ERROR
// =============================================================================

class _NoDrones extends StatelessWidget {
  const _NoDrones();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.flight_takeoff_rounded,
            color: AppColors.logoTurquoiseDark,
            size: 28,
          ),
          SizedBox(height: 10),
          Text(
            'No registered drones yet',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Add a drone to your fleet before applying to this job.',
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

class _LoadError extends StatelessWidget {
  const _LoadError({
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
              'Unable to load your fleet',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15.5,
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

class _PageShimmer extends StatefulWidget {
  const _PageShimmer();

  @override
  State<_PageShimmer> createState() => _PageShimmerState();
}

class _PageShimmerState extends State<_PageShimmer>
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
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
          children: [
            Container(
              height: 168,
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
                  _glow(82, 22, 11, dark: true),
                  const SizedBox(height: 18),
                  _glow(225, 19, 8, dark: true),
                  const SizedBox(height: 9),
                  _glow(150, 10, 6, dark: true),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: _glow(double.infinity, 28, 10, dark: true)),
                      const SizedBox(width: 10),
                      _glow(74, 28, 10, dark: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _glow(42, 42, 13),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _glow(145, 13, 6),
                    const SizedBox(height: 7),
                    _glow(205, 8, 5),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _droneSkeleton(),
            const SizedBox(height: 10),
            _droneSkeleton(),
            const SizedBox(height: 20),
            Row(
              children: [
                _glow(42, 42, 13),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _glow(160, 13, 6),
                    const SizedBox(height: 7),
                    _glow(220, 8, 5),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: _glow(double.infinity, 118, 15),
            ),
          ],
        );
      },
    );
  }

  Widget _droneSkeleton() {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _glow(76, 70, 18),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _glow(150, 12, 6),
                const SizedBox(height: 8),
                _glow(82, 8, 5),
                const SizedBox(height: 9),
                _glow(118, 20, 10),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _glow(32, 32, 16),
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

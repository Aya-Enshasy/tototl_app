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
  final _coverController = TextEditingController();

  late final DroneService _droneService;
  late final PilotApplicationService _applicationService;

  final List<DroneModel> _drones = [];
  int? _selectedDroneId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  DroneModel? get _selectedDrone {
    if (_selectedDroneId == null) return null;
    for (final drone in _drones) {
      if (drone.id == _selectedDroneId) return drone;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _droneService = DroneService(ApiClient());
    _applicationService = PilotApplicationService(ApiClient());
    _loadDrones();
  }

  @override
  void dispose() {
    _coverController.dispose();
    super.dispose();
  }

  Future<void> _loadDrones() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _droneService.getMyDrones();
      if (!mounted) return;

      setState(() {
        _drones
          ..clear()
          ..addAll(result);
        if (_drones.length == 1) {
          _selectedDroneId = _drones.first.id;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

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
    setState(() => _submitting = true);

    try {
      final result = await _applicationService.applyToJob(
        jobId: widget.job.id,
        droneId: drone.id,
        coverMessage: cover.isEmpty ? null : cover,
      );

      if (!mounted) return;

      final enriched = result.copyWith(
        job: widget.job,
        drone: drone,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ApplicationDetailsScreen(
            applicationId: result.id,
            initialApplication: enriched,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          _glow(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _loading
                      ? const _PageShimmer()
                      : _error != null
                          ? _LoadError(message: _error!, onRetry: _loadDrones)
                          : _content(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _loading || _error != null ? null : _bottomBar(),
    );
  }

  Widget _glow() {
    return Positioned(
      top: -160,
      right: -130,
      child: IgnorePointer(
        child: Container(
          width: 330,
          height: 330,
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
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const Expanded(
            child: Text(
              'Apply for Job',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _content() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _jobCard(),
        const SizedBox(height: 22),
        const Text(
          'Select a registered drone',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'The API requires a drone that already belongs to your pilot account.',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        const Text(
          'Cover message',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _coverController,
          minLines: 5,
          maxLines: 8,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13.5,
            height: 1.45,
          ),
          decoration: InputDecoration(
            hintText: 'Optional: tell the company why you are a good fit for this mission...',
            hintStyle: const TextStyle(
              color: AppColors.lightGrey,
              fontSize: 12.5,
              height: 1.4,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: _border(AppColors.cardBorder),
            enabledBorder: _border(AppColors.cardBorder),
            focusedBorder: _border(AppColors.blue, width: 1.3),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.blue, size: 17),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Only drone_id and the optional cover_message are sent to the Apply API.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _jobCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF122A3A), Color(0xFF0D3B4A), Color(0xFF087E8F)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.job.categoryLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            widget.job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.job.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 11.5,
                  ),
                ),
              ),
              Text(
                widget.job.payLabel,
                style: const TextStyle(
                  color: AppColors.logoTurquoiseLight,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _submitting || _drones.isEmpty ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _submitting ? 'Submitting...' : 'Submit Application',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 0.8}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }
}

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
    final accent = fullMatch ? AppColors.green : AppColors.orange;
    final bg = fullMatch ? AppColors.greenBg : AppColors.orangeBg;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.cardBorder,
              width: selected ? 1.5 : 0.9,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.flight_rounded, color: accent),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drone.title,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (drone.yearLabel.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            drone.yearLabel,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppColors.blue : AppColors.lightGrey,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  required.isEmpty
                      ? 'Compatible'
                      : fullMatch
                          ? 'Full capability match'
                          : '$matched/${required.length} required capabilities',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.5,
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

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_\s-]+'), ' ');
  }
}

class _NoDrones extends StatelessWidget {
  const _NoDrones();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.flight_takeoff_rounded, color: AppColors.blue, size: 32),
          SizedBox(height: 10),
          Text(
            'No registered drones',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Add a drone from My Drones before applying.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
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
            const Icon(Icons.cloud_off_rounded, color: AppColors.blue, size: 42),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 11.8),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

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
      builder: (_, __) {
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _box(160),
            const SizedBox(height: 18),
            _box(120),
            const SizedBox(height: 10),
            _box(120),
            const SizedBox(height: 10),
            _box(120),
          ],
        );
      },
    );
  }

  Widget _box(double height) {
    final t = _controller.value;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment(-1.6 + 3.2 * t, 0),
          end: Alignment(-0.6 + 3.2 * t, 0),
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

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

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  late final PilotApplicationService _applicationService;
  late final PilotJobService _jobService;
  late final DroneService _droneService;

  PilotApplicationModel? _application;
  bool _loading = true;
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var application =
          await _applicationService.getApplicationDetails(widget.applicationId);

      PilotJobModel? job = application.job ?? widget.initialApplication?.job;
      DroneModel? drone = application.drone ?? widget.initialApplication?.drone;

      if (job == null && application.jobPostingId > 0) {
        try {
          job = await _jobService.getJobDetails(application.jobPostingId);
        } catch (_) {
          // /jobs/{id} is Published-only for pilots. A closed/cancelled job
          // may legitimately be unavailable while the application still exists.
        }
      }

      if (drone == null && application.droneId > 0) {
        try {
          drone = await _droneService.getDrone(application.droneId);
        } catch (_) {
          // Keep the application even if the related drone cannot be fetched.
        }
      }

      application = application.copyWith(job: job, drone: drone);

      if (!mounted) return;
      setState(() {
        _application = application;
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

  Future<void> _withdraw() async {
    final application = _application;
    if (application == null || !application.isPending || _withdrawing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: const Text(
          'This will withdraw your pending application. The withdrawn status is terminal in this flow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Application'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _withdrawing = true);

    try {
      final updated =
          await _applicationService.withdrawApplication(application.id);

      if (!mounted) return;
      setState(() {
        _application = updated.copyWith(
          job: application.job,
          drone: application.drone,
        );
        _withdrawing = false;
        _changed = true;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Application withdrawn.'),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _withdrawing = false);
      _snack(e.toString());
    }
  }

  void _back() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
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
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _loading
                      ? const _DetailShimmer()
                      : _error != null
                          ? _ErrorState(message: _error!, onRetry: _load)
                          : _content(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomAction(),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const Expanded(
            child: Text(
              'Application Details',
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
    final application = _application!;
    final visual = _statusVisual(application.status);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          _hero(application, visual),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Application',
            icon: Icons.assignment_outlined,
            child: Column(
              children: [
                _DetailRow(label: 'Application ID', value: '#${application.id}'),
                _DetailRow(label: 'Submitted', value: application.submittedLabel),
                _DetailRow(label: 'Job ID', value: '#${application.jobPostingId}'),
                _DetailRow(label: 'Drone ID', value: '#${application.droneId}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _jobSection(application),
          const SizedBox(height: 14),
          _droneSection(application),
          if (application.coverMessage.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Cover Message',
              icon: Icons.chat_bubble_outline_rounded,
              child: Text(
                application.coverMessage,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.55,
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

  Widget _hero(PilotApplicationModel application, _StatusVisual visual) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Text(
            application.jobTitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (application.companyLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              application.companyLabel,
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _jobSection(PilotApplicationModel application) {
    final job = application.job;

    return _SectionCard(
      title: 'Job',
      icon: Icons.work_outline_rounded,
      child: job == null
          ? _UnavailableRelation(
              title: 'Job #${application.jobPostingId}',
              message:
                  'Full job details are not guaranteed by the application endpoint. If the job is no longer Published, the pilot job endpoint may also be unavailable.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  job.detailedLocationLabel,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Pay',
                        value: job.payLabel,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(label: 'Date', value: job.dateLabel),
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
      icon: Icons.flight_rounded,
      child: drone == null
          ? _UnavailableRelation(
              title: 'Drone #${application.droneId}',
              message:
                  'The committed drone ID remains part of the application even when the full drone object cannot be loaded.',
            )
          : Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.greenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: AppColors.green,
                  ),
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
              ],
            ),
    );
  }

  Widget _statusSection(PilotApplicationModel application) {
    final children = <Widget>[];

    if (application.decisionLabel.isNotEmpty) {
      children.add(_DetailRow(label: 'Decision', value: application.decisionLabel));
    }
    if (application.withdrawnLabel.isNotEmpty) {
      children.add(_DetailRow(label: 'Withdrawn', value: application.withdrawnLabel));
    }
    if (application.rejectionReason.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rejection reason',
                style: TextStyle(color: AppColors.grey, fontSize: 11.5),
              ),
              const SizedBox(height: 5),
              Text(
                application.rejectionReason,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (children.isEmpty) {
      children.add(
        Text(
          application.statusLabel,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return _SectionCard(
      title: 'Application Status',
      icon: Icons.fact_check_outlined,
      child: Column(children: children),
    );
  }

  Widget? _bottomAction() {
    if (_loading || _error != null || _application == null) return null;
    if (!_application!.isPending) return null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _withdrawing ? null : _withdraw,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.blue, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ?? AppColors.navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableRelation extends StatelessWidget {
  const _UnavailableRelation({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

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
      return const _StatusVisual(AppColors.blue, AppColors.blueBg);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
            const SizedBox(height: 12),
            const Text(
              'Couldn’t load this application',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 11.8),
            ),
            const SizedBox(height: 14),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            _box(168),
            const SizedBox(height: 14),
            _box(178),
            const SizedBox(height: 14),
            _box(150),
            const SizedBox(height: 14),
            _box(128),
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

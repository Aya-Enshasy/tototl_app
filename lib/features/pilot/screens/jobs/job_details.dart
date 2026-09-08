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
  });

  final int jobId;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final PilotJobService _service;
  late final AnimationController _pageAnimationController;

  PilotJobModel? _job;
  bool _loading = true;
  bool _saved = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _service = PilotJobService(ApiClient());

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _load();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final job = await _service.getJobDetails(widget.jobId);

      if (!mounted) return;

      setState(() {
        _job = job;
        _loading = false;
      });

      _pageAnimationController
        ..reset()
        ..forward();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.045).clamp(0.0, 0.65).toDouble();
    final end = (start + 0.30).clamp(0.0, 1.0).toDouble();

    final animation = CurvedAnimation(
      parent: _pageAnimationController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
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
          _backgroundGlow(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: _loading
                      ? const _JobDetailShimmer()
                      : _errorMessage != null
                          ? _DetailError(
                              message: _errorMessage!,
                              onRetry: _load,
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
    if (_loading || _errorMessage != null || _job == null) {
      return null;
    }

    final job = _job!;
    final application = job.application;

    if (application?.hasApplied == true) {
      final applicationId = application?.id;
      final statusLabel = application?.statusLabel ?? '';

      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.blueBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: AppColors.blue,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusLabel.isEmpty
                              ? 'Application submitted'
                              : 'Application $statusLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (applicationId != null) ...[
                const SizedBox(width: 9),
                SizedBox(
                  height: 50,
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
                        await _load();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(fontWeight: FontWeight.w800),
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
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ApplyForJobScreen(job: job),
                ),
              );

              if (mounted) {
                await _load();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text(
              'Apply for this Job',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backgroundGlow() {
    return Stack(
      children: [
        Positioned(
          top: -150,
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
          top: 650,
          left: -170,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.logoTurquoise.withOpacity(0.035),
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 7),
      child: Row(
        children: [
          _TopIconButton(
            tooltip: 'Back',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            icon: Icons.arrow_back_ios_new_rounded,
          ),
          const Expanded(
            child: Text(
              'Job Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _TopIconButton(
            tooltip: _saved ? 'Remove saved job' : 'Save job',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _saved = !_saved);
            },
            icon: _saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            selected: _saved,
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final job = _job!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
        children: [
          _animatedEntry(index: 0, child: _JobHero(job: job)),
          const SizedBox(height: 14),
          _animatedEntry(index: 1, child: _JobSummary(job: job)),
          if (job.application?.hasApplied == true) ...[
            const SizedBox(height: 14),
            _animatedEntry(
              index: 2,
              child: _ApplicationStatusCard(
                application: job.application!,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _animatedEntry(
            index: 3,
            child: _SectionCard(
              icon: Icons.notes_rounded,
              title: 'Description',
              child: Text(
                job.description.isEmpty
                    ? 'No description provided.'
                    : job.description,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _animatedEntry(
            index: 4,
            child: _SectionCard(
              icon: Icons.location_on_outlined,
              title: 'Location',
              child: Column(
                children: [
                  _LocationRow(
                    label: 'Country',
                    value: _fallback(job.country),
                  ),
                  if (job.state.isNotEmpty)
                    _LocationRow(label: 'State', value: job.state),
                  if (job.city.isNotEmpty)
                    _LocationRow(label: 'City', value: job.city),
                  if (job.region.isNotEmpty)
                    _LocationRow(label: 'Region', value: job.region),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _animatedEntry(
            index: 5,
            child: _SectionCard(
              icon: Icons.calendar_month_outlined,
              title: 'Schedule',
              child: Column(
                children: [
                  _LocationRow(
                    label: 'Start',
                    value: _date(job.startDate),
                  ),
                  _LocationRow(
                    label: 'End',
                    value: _date(job.endDate),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _animatedEntry(
            index: 6,
            child: _SectionCard(
              icon: Icons.payments_outlined,
              title: 'Budget',
              child: Column(
                children: [
                  _LocationRow(
                    label: 'Type',
                    value: job.paymentTypeLabel,
                  ),
                  _LocationRow(
                    label: 'Budget',
                    value: job.payLabel,
                    valueColor: AppColors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _animatedEntry(
            index: 7,
            child: _RequirementsCard(job: job),
          ),
          if (job.requiredCapabilities.isNotEmpty) ...[
            const SizedBox(height: 14),
            _animatedEntry(
              index: 8,
              child: _SectionCard(
                icon: Icons.flight_takeoff_rounded,
                title: 'Required Drone Capabilities',
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: job.requiredCapabilities
                      .map((item) => _CapabilityChip(label: item))
                      .toList(),
                ),
              ),
            ),
          ],
          if (job.attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            _animatedEntry(
              index: 9,
              child: _AttachmentsCard(attachments: job.attachments),
            ),
          ],
          if (job.company != null) ...[
            const SizedBox(height: 14),
            _animatedEntry(
              index: 10,
              child: _CompanyCard(company: job.company!),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _date(DateTime? date) {
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

  String _fallback(String value) =>
      value.trim().isEmpty ? 'Not specified' : value.trim();
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.blue.withOpacity(0.09)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.blue.withOpacity(0.20)
                    : AppColors.cardBorder,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.blue : AppColors.navy,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

class _JobHero extends StatelessWidget {
  const _JobHero({required this.job});

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    final company = job.company;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF122A3A),
            Color(0xFF0D3B4A),
            Color(0xFF087E8F),
          ],
          stops: [0, 0.60, 1],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3B4A).withOpacity(0.16),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -23,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.035),
              ),
            ),
          ),
          Positioned(
            right: 15,
            top: 15,
            child: Icon(
              _categoryIcon(job.serviceCategory),
              color: Colors.white.withOpacity(0.10),
              size: 80,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (company != null && company.verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.logoTurquoiseLight,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Verified company',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              Text(
                job.title.isEmpty ? 'Untitled Job' : job.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                company?.displayName ?? job.categoryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.74),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                job.payLabel,
                style: const TextStyle(
                  color: AppColors.logoTurquoiseLight,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
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
}

class _JobSummary extends StatelessWidget {
  const _JobSummary({required this.job});

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.032),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.payments_outlined,
                  label: 'Pay',
                  value: job.payLabel,
                  accent: AppColors.green,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: job.dateLabel,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  icon: Icons.category_outlined,
                  label: 'Service',
                  value: job.categoryLabel,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: AppColors.cardBorder),
          ),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.065),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.blue,
                  size: 15,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  job.detailedLocationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.navy,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Icon(icon, color: accent.withOpacity(0.78), size: 15),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              height: 1.2,
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
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: AppColors.cardBorder,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.blue, size: 16),
              ),
              const SizedBox(width: 9),
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

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.job});

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    final lines = job.requirementLines;

    return _SectionCard(
      icon: Icons.verified_user_outlined,
      title: 'Requirements',
      child: lines.isEmpty
          ? const Text(
              'No additional requirements.',
              style: TextStyle(color: AppColors.grey, fontSize: 12.5),
            )
          : Column(
              children: lines.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
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
                              fontSize: 12.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.065),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.green.withOpacity(0.09)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard({required this.attachments});

  final List<PilotJobAttachmentModel> attachments;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.attach_file_rounded,
      title: 'Attachments (${attachments.length})',
      child: Column(
        children: attachments.map((attachment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  attachment.isImage
                      ? Icons.image_outlined
                      : Icons.insert_drive_file_outlined,
                  color: AppColors.blue,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    attachment.name.isEmpty ? 'Attachment' : attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (attachment.size > 0)
                  Text(
                    _size(attachment.size),
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.company});

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.business_outlined,
      title: 'About the Company',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                company.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (company.verified)
              const Icon(
                Icons.verified_rounded,
                color: AppColors.logoTurquoiseLight,
                size: 17,
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  const _ApplicationStatusCard({required this.application});

  final PilotJobApplicationSummary application;

  @override
  Widget build(BuildContext context) {
    final visual = _applicationVisual(application.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: visual.foreground.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            color: visual.foreground,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You already applied',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  application.statusLabel,
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 11.5,
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

class _VisualPair {
  final Color foreground;
  final Color background;

  const _VisualPair(this.foreground, this.background);
}

_VisualPair _applicationVisual(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return const _VisualPair(AppColors.green, AppColors.greenBg);
    case 'rejected':
      return _VisualPair(Colors.red.shade700, Colors.red.shade50);
    case 'withdrawn':
      return _VisualPair(AppColors.grey, Colors.grey.shade100);
    default:
      return const _VisualPair(AppColors.blue, AppColors.blueBg);
  }
}

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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Couldn’t load this job',
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
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11.8,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobDetailShimmer extends StatefulWidget {
  const _JobDetailShimmer();

  @override
  State<_JobDetailShimmer> createState() => _JobDetailShimmerState();
}

class _JobDetailShimmerState extends State<_JobDetailShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
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
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
          children: [
            _skeleton(180, 24),
            const SizedBox(height: 14),
            _skeleton(138, 20),
            const SizedBox(height: 14),
            _skeleton(132, 20),
            const SizedBox(height: 14),
            _skeleton(150, 20),
          ],
        );
      },
    );
  }

  Widget _skeleton(double height, double radius) {
    final t = _animation.value;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.6 + (3.2 * t), 0),
          end: Alignment(-0.6 + (3.2 * t), 0),
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

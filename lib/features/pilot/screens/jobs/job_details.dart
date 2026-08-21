import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../company/profile/company_public_profile_screen.dart';
import '../applications/apply_for_job_screen.dart';
import '../shared/pilot_data.dart';

// ============================================================================
// JOB DETAILS SCREEN
// ============================================================================

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({
    super.key,
    this.job = solarFarmJob,
  });

  final PilotJob job;

  @override
  State<JobDetailsScreen> createState() =>
      _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _saved = false;

  late final AnimationController _pageAnimationController;

  @override
  void initState() {
    super.initState();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 950,
      ),
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ENTRY ANIMATION
  // ==========================================================================

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start =
    (index * 0.045)
        .clamp(
      0.0,
      0.65,
    )
        .toDouble();

    final end =
    (start + 0.30)
        .clamp(
      0.0,
      1.0,
    )
        .toDouble();

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
          begin: const Offset(
            0,
            0.035,
          ),
          end: Offset.zero,
        ).animate(
          animation,
        ),
        child: child,
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: AppColors.bg,

      body: Stack(
        children: [
          // ==================================================================
          // SOFT BACKGROUND DECORATION
          // ==================================================================

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
                      AppColors.blue.withOpacity(
                        0.09,
                      ),
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
                      AppColors.logoTurquoiseLight.withOpacity(
                        0.035,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==================================================================
          // SCREEN
          // ==================================================================

          SafeArea(
            child: Column(
              children: [
                // ============================================================
                // TOP BAR
                // ============================================================

                _TopBar(
                  saved: _saved,
                  onBack: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  onSave: () {
                    HapticFeedback.selectionClick();

                    setState(() {
                      _saved = !_saved;
                    });
                  },
                ),

                // ============================================================
                // SCROLL CONTENT
                // ============================================================

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      30,
                    ),
                    children: [
                      // ======================================================
                      // HERO
                      // ======================================================

                      _animatedEntry(
                        index: 0,
                        child: _JobHero(
                          job: job,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ======================================================
                      // SUMMARY
                      // ======================================================

                      _animatedEntry(
                        index: 1,
                        child: _JobSummary(
                          job: job,
                        ),
                      ),

                      // ======================================================
                      // SERVICE CATEGORY
                      // ======================================================

                      if (job.serviceCategory.isNotEmpty) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        _animatedEntry(
                          index: 2,
                          child: _SectionCard(
                            icon: Icons.category_outlined,
                            title: 'Service Category',
                            child: Text(
                              job.serviceCategory,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // ======================================================
                      // DESCRIPTION
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 3,
                        child: _SectionCard(
                          icon: Icons.notes_rounded,
                          title: 'Description',
                          child: Text(
                            job.description,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.65,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      // ======================================================
                      // LOCATION
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 4,
                        child: _SectionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          child: Column(
                            children: [
                              _LocationRow(
                                'Country',
                                job.country,
                              ),

                              _LocationRow(
                                'City',
                                job.city,
                              ),

                              if (job.region.isNotEmpty)
                                _LocationRow(
                                  'Region',
                                  job.region,
                                ),

                              if (job.address != null)
                                _LocationRow(
                                  'Address',
                                  job.address!,
                                ),

                              if (job.indoorOutdoor != null)
                                _LocationRow(
                                  'Type',
                                  job.indoorOutdoor!,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ======================================================
                      // SCHEDULE
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 5,
                        child: _SectionCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Schedule',
                          child: Column(
                            children: [
                              _LocationRow(
                                'Date',
                                job.date,
                              ),

                              if (job.startTime != null)
                                _LocationRow(
                                  'Start Time',
                                  job.startTime!,
                                ),

                              if (job.flexibleSchedule)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(
                                    top: 5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withOpacity(
                                      0.065,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      11,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        color: AppColors.green,
                                        size: 15,
                                      ),

                                      SizedBox(
                                        width: 7,
                                      ),

                                      Text(
                                        'Flexible schedule',
                                        style: TextStyle(
                                          color: AppColors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ======================================================
                      // BUDGET
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 6,
                        child: _SectionCard(
                          icon: Icons.payments_outlined,
                          title: 'Budget',
                          child: Column(
                            children: [
                              _LocationRow(
                                'Payment Type',
                                job.paymentType,
                              ),

                              _BudgetRow(
                                label: 'Budget',
                                value: job.pay,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ======================================================
                      // REQUIRED SKILLS
                      // ======================================================

                      if (job.requiredSkills.isNotEmpty) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        _animatedEntry(
                          index: 7,
                          child: _SectionCard(
                            icon: Icons.auto_awesome_outlined,
                            title: 'Skills Required',
                            child: Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: job.requiredSkills
                                  .map(
                                    (skill) => _CapabilityChip(
                                  label: skill,
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],

                      // ======================================================
                      // REQUIREMENTS
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 8,
                        child: _SectionCard(
                          icon: Icons.verified_user_outlined,
                          title: 'Requirements',
                          child: _Checklist(
                            items: job.requirements,
                            icon: Icons.verified_outlined,
                          ),
                        ),
                      ),

                      // ======================================================
                      // DRONE CAPABILITIES
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 9,
                        child: _SectionCard(
                          icon: Icons.flight_takeoff_rounded,
                          title: 'Required Drone Capabilities',
                          child: Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: job.capabilities
                                .map(
                                  (capability) => _CapabilityChip(
                                label: capability,
                              ),
                            )
                                .toList(),
                          ),
                        ),
                      ),

                      // ======================================================
                      // SAFETY
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 10,
                        child: _SectionCard(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Safety Requirements',
                          child: _Checklist(
                            items: job.safetyRequirements,
                            icon: Icons.health_and_safety_outlined,
                          ),
                        ),
                      ),

                      // ======================================================
                      // ATTACHMENTS
                      // ======================================================

                      if (job.attachments.isNotEmpty) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        _animatedEntry(
                          index: 11,
                          child: _SectionCard(
                            icon: Icons.attach_file_rounded,
                            title: 'Attachments',
                            child: Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: job.attachments
                                  .map(
                                    (attachment) => _AttachmentChip(
                                  label: attachment,
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],

                      // ======================================================
                      // ABOUT COMPANY
                      // ======================================================

                      const SizedBox(
                        height: 14,
                      ),

                      _animatedEntry(
                        index: 12,
                        child: _SectionCard(
                          icon: Icons.business_outlined,
                          title: 'About the Company',
                          child: _CompanyCard(
                            job: job,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // APPLY BAR
                // ============================================================

                _ApplyBar(
                  pay: job.pay,
                  onApply: () {
                    HapticFeedback.mediumImpact();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApplyForJobScreen(
                          job: job,
                        ),
                      ),
                    );
                  },
                ),
              ],
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
    required this.onBack,
    required this.onSave,
  });

  final bool saved;

  final VoidCallback onBack;

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        8,
      ),
      child: Row(
        children: [
          // ==================================================================
          // BACK
          // ==================================================================

          _TopIconButton(
            tooltip: 'Back',
            onTap: onBack,
            icon: Icons.arrow_back_ios_new_rounded,
          ),

          // ==================================================================
          // TITLE
          // ==================================================================

          const Expanded(
            child: Text(
              'Job Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,

                // المطلوب: العنوان العلوي 18
                fontSize: 18,

                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // ==================================================================
          // SAVE
          // ==================================================================

          _TopIconButton(
            tooltip:
            saved
                ? 'Remove saved job'
                : 'Save job',
            onTap: onSave,
            icon:
            saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            selected: saved,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP ICON BUTTON
// ============================================================================

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
          borderRadius: BorderRadius.circular(
            50,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 220,
            ),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
              selected
                  ? AppColors.blue.withOpacity(
                0.09,
              )
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                selected
                    ? AppColors.blue.withOpacity(
                  0.20,
                )
                    : AppColors.cardBorder,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(
                    0.035,
                  ),
                  blurRadius: 12,
                  offset: const Offset(
                    0,
                    4,
                  ),
                ),
              ],
            ),
            child: Icon(
              icon,
              color:
              selected
                  ? AppColors.blue
                  : AppColors.navy,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// JOB HERO
// ============================================================================

class _JobHero extends StatelessWidget {
  const _JobHero({
    required this.job,
  });

  final PilotJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 172,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFF122A3A,
            ),
            Color(
              0xFF0D3B4A,
            ),
            Color(
              0xFF087E8F,
            ),
          ],
          stops: [
            0,
            0.60,
            1,
          ],
        ),
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF0D3B4A,
            ).withOpacity(
              0.16,
            ),
            blurRadius: 26,
            offset: const Offset(
              0,
              11,
            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ==================================================================
          // DECORATION
          // ==================================================================

          Positioned(
            right: -18,
            top: -23,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(
                  0.035,
                ),
              ),
            ),
          ),

          Positioned(
            right: 15,
            top: 15,
            child: Icon(
              job.id == solarFarmJob.id
                  ? Icons.solar_power_rounded
                  : Icons.flight_takeoff_rounded,
              color: Colors.white.withOpacity(
                0.10,
              ),
              size: 80,
            ),
          ),

          // ==================================================================
          // CONTENT
          // ==================================================================

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              // ==============================================================
              // VERIFIED
              // ==============================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.09,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      0.07,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color:
                      AppColors.logoTurquoiseLight,
                      size: 14,
                    ),

                    SizedBox(
                      width: 5,
                    ),

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

              const SizedBox(
                height: 30,
              ),

              // ==============================================================
              // TITLE
              // ==============================================================

              Text(
                job.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.35,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color:
                      AppColors.logoTurquoiseLight,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Expanded(
                    child: Text(
                      job.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(
                          0.72,
                        ),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// JOB SUMMARY
// ============================================================================

class _JobSummary extends StatelessWidget {
  const _JobSummary({
    required this.job,
  });

  final PilotJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        15,
        16,
        15,
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(
              0.032,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================================
          // METRICS
          // ==================================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.payments_outlined,
                  label: 'Pay',
                  value: job.pay,
                  accent: AppColors.green,
                ),
              ),

              _MetricDivider(),

              Expanded(
                child: _Metric(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: job.date,
                ),
              ),

              _MetricDivider(),

              const Expanded(
                child: _Metric(
                  icon: Icons.schedule_outlined,
                  label: 'Time',
                  value: '9:00 AM',
                ),
              ),

              _MetricDivider(),

              const Expanded(
                child: _Metric(
                  icon: Icons.today_outlined,
                  label: 'Day',
                  value: 'Thursday',
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 15,
            ),
            child: Divider(
              height: 1,
              color: AppColors.cardBorder,
            ),
          ),

          // ==================================================================
          // LOCATION
          // ==================================================================

          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(
                    0.065,
                  ),
                  borderRadius: BorderRadius.circular(
                    9,
                  ),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.blue,
                  size: 15,
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  job.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              const Icon(
                Icons.star_rounded,
                color: AppColors.gold,
                size: 16,
              ),

              const SizedBox(
                width: 3,
              ),

              Flexible(
                child: Text(
                  '${job.companyRating} company rating',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // ==================================================================
          // INFO CHIPS
          // ==================================================================

          if (job.siteImagesProvided ||
              job.pidIncluded) ...[
            const SizedBox(
              height: 13,
            ),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (job.siteImagesProvided)
                  const _InfoChip(
                    icon: Icons.image_outlined,
                    label: 'Site images provided',
                  ),

                if (job.pidIncluded)
                  const _InfoChip(
                    icon: Icons.description_outlined,
                    label: 'P&ID included',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// METRIC
// ============================================================================

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
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: accent.withOpacity(
              0.78,
            ),
            size: 15,
          ),

          const SizedBox(
            height: 5,
          ),

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

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 11.5,
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
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      color: AppColors.cardBorder,
    );
  }
}

// ============================================================================
// INFO CHIP
// ============================================================================

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(
          0.055,
        ),
        borderRadius: BorderRadius.circular(
          9,
        ),
        border: Border.all(
          color: AppColors.blue.withOpacity(
            0.07,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.blue,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION CARD
// ============================================================================

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
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(
              0.027,
            ),
            blurRadius: 16,
            offset: const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ==================================================================
          // SECTION HEADER
          // ==================================================================

          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(
                    0.065,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.blue,
                  size: 16,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          child,
        ],
      ),
    );
  }
}

// ============================================================================
// LOCATION ROW
// ============================================================================

class _LocationRow extends StatelessWidget {
  const _LocationRow(
      this.label,
      this.value,
      );

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.grey.withOpacity(
                  0.86,
                ),
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12.5,
                height: 1.4,
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
// BUDGET ROW
// ============================================================================

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.label,
    required this.value,
  });

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 4,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.grey.withOpacity(
                  0.86,
                ),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(
                0.07,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHECKLIST
// ============================================================================

class _Checklist extends StatelessWidget {
  const _Checklist({
    required this.items,
    required this.icon,
  });

  final List<String> items;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        items.length,
            (index) {
          final item =
          items[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom:
              index == items.length - 1
                  ? 0
                  : 11,
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(
                      0.065,
                    ),
                    borderRadius: BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.green,
                    size: 14,
                  ),
                ),

                const SizedBox(
                  width: 9,
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 3,
                    ),
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
        },
      ),
    );
  }
}

// ============================================================================
// CAPABILITY CHIP
// ============================================================================

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
        color: AppColors.green.withOpacity(
          0.065,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: AppColors.green.withOpacity(
            0.09,
          ),
        ),
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

// ============================================================================
// ATTACHMENT CHIP
// ============================================================================

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
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
        color: AppColors.blue.withOpacity(
          0.055,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: AppColors.blue.withOpacity(
            0.08,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_file_rounded,
            color: AppColors.blue,
            size: 13,
          ),

          const SizedBox(
            width: 5,
          ),

          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPANY CARD
// ============================================================================

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.job,
  });

  final PilotJob job;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          15,
        ),
        onTap: () {
          HapticFeedback.selectionClick();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
              const CompanyPublicProfileScreen(),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(
            12,
          ),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.blue.withOpacity(
                        0.12,
                      ),
                      AppColors.blue.withOpacity(
                        0.055,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            job.company,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13.5,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        const Icon(
                          Icons.verified_rounded,
                          color:
                          AppColors.logoTurquoiseLight,
                          size: 15,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '${job.jobsPosted} jobs posted · ${job.pilotsHired} pilots hired',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.blue,
                  size: 18,
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
// APPLY BAR
// ============================================================================

class _ApplyBar extends StatelessWidget {
  const _ApplyBar({
    required this.pay,
    required this.onApply,
  });

  final String pay;

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        11,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: AppColors.cardBorder,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(
              0.045,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              -5,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Row(
          children: [
            // ==================================================================
            // RATE
            // ==================================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Daily rate',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    pay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            // ==================================================================
            // APPLY BUTTON
            // ==================================================================

            Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  15,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(
                      0xFF16BDB8,
                    ),
                    Color(
                      0xFF087F9D,
                    ),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(
                      0.20,
                    ),
                    blurRadius: 15,
                    offset: const Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 21,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Apply for Job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(
                      width: 7,
                    ),

                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
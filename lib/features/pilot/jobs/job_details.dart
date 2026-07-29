import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../applications/apply_for_job_screen.dart';
import '../shared/pilot_data.dart';
import '../../company/profile/company_public_profile_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, this.job = solarFarmJob});

  final PilotJob job;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              saved: _saved,
              onBack: () => Navigator.of(context).pop(),
              onSave: () => setState(() => _saved = !_saved),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                children: [
                  _JobHero(job: job),
                  const SizedBox(height: 14),
                  _JobSummary(job: job),
                  const SizedBox(height: 14),
                  if (job.serviceCategory.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Service Category',
                      child: Text(
                        job.serviceCategory,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _SectionCard(
                    title: 'Description',
                    child: Text(
                      job.description,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Location',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LocationRow('Country', job.country),
                        _LocationRow('City', job.city),
                        if (job.region.isNotEmpty) _LocationRow('Region', job.region),
                        if (job.address != null) _LocationRow('Address', job.address!),
                        if (job.indoorOutdoor != null) _LocationRow('Type', job.indoorOutdoor!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Schedule',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LocationRow('Date', job.date),
                        if (job.startTime != null) _LocationRow('Start Time', job.startTime!),
                        if (job.flexibleSchedule) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: AppColors.green, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Flexible schedule',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Budget',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LocationRow('Payment Type', job.paymentType),
                        _LocationRow('Budget', job.pay),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (job.requiredSkills.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Skills Required',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job.requiredSkills
                            .map(
                              (skill) => _CapabilityChip(label: skill),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _SectionCard(
                    title: 'Requirements',
                    child: _Checklist(
                      items: job.requirements,
                      icon: Icons.verified_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Required Drone Capabilities',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.capabilities
                          .map(
                            (capability) => _CapabilityChip(label: capability),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Safety Requirements',
                    child: _Checklist(
                      items: job.safetyRequirements,
                      icon: Icons.health_and_safety_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (job.attachments.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Attachments',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job.attachments
                            .map(
                              (attachment) => _CapabilityChip(label: attachment),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _SectionCard(
                    title: 'About the Company',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CompanyPublicProfileScreen(),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      job.company,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.logoTurquoiseLight,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${job.jobsPosted} jobs posted · ${job.pilotsHired} pilots hired',
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 88),
                ],
              ),
            ),
            _ApplyBar(
              pay: job.pay,
              onApply: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ApplyForJobScreen(job: job)),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const Expanded(
            child: Text(
              'Job Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: saved ? 'Remove saved job' : 'Save job',
            onPressed: onSave,
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
            color: saved ? AppColors.blue : AppColors.navy,
          ),
        ],
      ),
    );
  }
}

class _JobHero extends StatelessWidget {
  const _JobHero({required this.job});

  final PilotJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.solar_power_rounded,
              color: Colors.white.withValues(alpha: 0.16),
              size: 100,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.logoTurquoiseLight,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Verified company',
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                job.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.company,
                style: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobSummary extends StatelessWidget {
  const _JobSummary({required this.job});

  final PilotJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Pay',
                  value: job.pay,
                  accent: AppColors.green,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.cardBorder),
              Expanded(
                child: _Metric(label: 'Date', value: job.date),
              ),
              Container(width: 1, height: 38, color: AppColors.cardBorder),
              Expanded(
                child: _Metric(label: 'Time', value: '9:00 AM'),
              ),
              Container(width: 1, height: 38, color: AppColors.cardBorder),
              Expanded(
                child: _Metric(label: 'Day', value: 'Thursday'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.grey,
                size: 17,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  job.location,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 3),
              Text(
                '${job.companyRating} company rating',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.accent = AppColors.navy,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.items, required this.icon});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.green, size: 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Widget _LocationRow(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.grey, fontSize: 13),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
);

class _ApplyBar extends StatelessWidget {
  const _ApplyBar({required this.pay, required this.onApply});

  final String pay;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily rate',
                  style: TextStyle(color: AppColors.grey, fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Text(
                  pay,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text(
                'Apply for Job',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

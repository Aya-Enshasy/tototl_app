import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../pilot/screens/shared/pilot_data.dart';
import '../jobs/company_job_detail_screen.dart';
import '../jobs/company_jobs_screen.dart';
import '../jobs/post_job_screen.dart';

class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        CompanyJobsStore.instance,
        PilotApplicationsStore.instance,
      ]),
      builder: (context, _) {
        final jobs = CompanyJobsStore.instance.jobs;
        final applications = PilotApplicationsStore.instance.applications
            .where(
              (application) => application.job.company == 'SunTech Energy Ltd.',
            )
            .toList();

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                const _CompanyHeader(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${CompanyJobsStore.instance.activeCount}',
                        label: 'Active jobs',
                        icon: Icons.work_outline_rounded,
                        color: AppColors.blue,
                        background: AppColors.blueBg,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: _StatCard(
                        value: '23',
                        label: 'Pilots hired',
                        icon: Icons.people_outline_rounded,
                        color: AppColors.green,
                        background: AppColors.greenBg,
                      ),
                    ),
                    const SizedBox(width: 11),
                   
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PostJobScreen()),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text(
                      'Post a New Job',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _SectionHeader(
                  title: 'Recent Applications',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CompanyJobsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                if (applications.isEmpty)
                  const _EmptyInline(
                    message: 'New pilot applications will appear here.',
                  )
                else
                  ...applications
                      .take(2)
                      .map(
                        (application) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ApplicationPreview(application: application),
                        ),
                      ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Active Jobs',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CompanyJobsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                ...jobs
                    .where((job) => job.status == CompanyJobStatus.active)
                    .take(2)
                    .map(
                      (companyJob) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ActiveJobPreview(companyJob: companyJob),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.solar_power_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Account',
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'SunTech Energy Ltd.',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.green,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Verified company',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'View all',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ApplicationPreview extends StatelessWidget {
  const _ApplicationPreview({required this.application});

  final PilotApplication application;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.greenBg,
            child: Text(
              application.pilot.name.substring(0, 1),
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.pilot.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${application.pilot.location} · ${application.pilot.experience} exp',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orangeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveJobPreview extends StatelessWidget {
  const _ActiveJobPreview({required this.companyJob});

  final CompanyJob companyJob;

  @override
  Widget build(BuildContext context) {
    final applications = PilotApplicationsStore.instance.applications
        .where((application) => application.job.id == companyJob.job.id)
        .length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompanyJobDetailScreen(jobId: 0),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyJob.job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${companyJob.job.date} · $applications applicants',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.grey, fontSize: 13),
    ),
  );
}

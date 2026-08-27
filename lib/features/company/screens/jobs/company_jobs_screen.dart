import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../pilot/screens/shared/pilot_data.dart';
import 'company_job_detail_screen.dart';
import 'post_job_screen.dart';

class CompanyJobsScreen extends StatefulWidget {
  const CompanyJobsScreen({super.key});

  @override
  State<CompanyJobsScreen> createState() => _CompanyJobsScreenState();
}

class _CompanyJobsScreenState extends State<CompanyJobsScreen> {
  CompanyJobStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        CompanyJobsStore.instance,
        PilotApplicationsStore.instance,
      ]),
      builder: (context, _) {
        final jobs = CompanyJobsStore.instance.jobs
            .where(
              (job) => _selectedStatus == null || job.status == _selectedStatus,
            )
            .toList();

        return Scaffold(
          backgroundColor: AppColors.bg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PostJobScreen())),
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text(
              'Post Job',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 6),
                  child: Text(
                    'My Jobs',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${CompanyJobsStore.instance.activeCount} active job postings',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedStatus == null,
                        onTap: () => setState(() => _selectedStatus = null),
                      ),
                      const SizedBox(width: 8),
                      ...CompanyJobStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: status.label.toLowerCase(),
                            selected: _selectedStatus == status,
                            onTap: () =>
                                setState(() => _selectedStatus = status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _CompanyJobCard(companyJob: jobs[index]),
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

class _CompanyJobCard extends StatelessWidget {
  const _CompanyJobCard({required this.companyJob});

  final CompanyJob companyJob;

  @override
  Widget build(BuildContext context) {
    final job = companyJob.job;
    final applicationCount = PilotApplicationsStore.instance.applications
        .where((application) => application.job.id == job.id)
        .length;
    final statusColor = _statusColor(companyJob.status);
    final statusBackground = _statusBackground(companyJob.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompanyJobDetailScreen(companyJob: companyJob),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blueBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          companyJob.postedAt,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      companyJob.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    job.date,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    job.pay,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_outline_rounded,
                    size: 17,
                    color: applicationCount == 0
                        ? AppColors.lightGrey
                        : AppColors.blue,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$applicationCount applicants',
                    style: TextStyle(
                      color: applicationCount == 0
                          ? AppColors.grey
                          : AppColors.blue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.lightGrey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.blue,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppColors.navy,
      fontWeight: FontWeight.w700,
      fontSize: 12.5,
    ),
    backgroundColor: Colors.white,
    side: BorderSide(color: selected ? AppColors.blue : AppColors.cardBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
}

Color _statusColor(CompanyJobStatus status) {
  switch (status) {
    case CompanyJobStatus.active:
      return AppColors.green;
    case CompanyJobStatus.draft:
      return AppColors.orange;
    case CompanyJobStatus.archived:
      return AppColors.grey;
  }
}

Color _statusBackground(CompanyJobStatus status) {
  switch (status) {
    case CompanyJobStatus.active:
      return AppColors.greenBg;
    case CompanyJobStatus.draft:
      return AppColors.orangeBg;
    case CompanyJobStatus.archived:
      return AppColors.tagBg;
  }
}

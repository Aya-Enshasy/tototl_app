import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pilot/shared/pilot_data.dart';
import 'company_application_detail_screen.dart';

class CompanyJobDetailScreen extends StatelessWidget {
  const CompanyJobDetailScreen({super.key, required this.companyJob});

  final CompanyJob companyJob;

  @override
  Widget build(BuildContext context) {
    final job = companyJob.job;
    return AnimatedBuilder(
      animation: PilotApplicationsStore.instance,
      builder: (context, _) {
        final applicants = PilotApplicationsStore.instance.applications
            .where((application) => application.job.id == job.id)
            .toList();
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Job Detail',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Job editing is ready for the next release.',
                                ),
                              ),
                            ),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    companyJob.status.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (companyJob.urgent)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Text(
                                      'Urgent',
                                      style: TextStyle(
                                        color: Color(0xFFFFD28A),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              job.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${job.location} · ${job.date}',
                              style: const TextStyle(
                                color: Color(0xFFC8D5EC),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              job.pay,
                              style: const TextStyle(
                                color: Color(0xFF93E3B9),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        title: 'Description',
                        child: Text(
                          job.description,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        title: 'Requirements',
                        child: _LineList(
                          items: job.requirements,
                          icon: Icons.verified_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        title: 'Required Drone Capabilities',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.capabilities
                              .map((item) => _Capability(label: item))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Applications (${applicants.length})',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 11),
                      if (applicants.isEmpty)
                        const _EmptyApplications()
                      else
                        ...applicants.map(
                          (application) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ApplicantCard(application: application),
                          ),
                        ),
                    ],
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

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.application});
  final PilotApplication application;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CompanyApplicationDetailScreen(application: application),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.blueBg,
              child: Text(
                application.pilot.name.substring(0, 1),
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        application.pilot.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.green,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${application.pilot.location} · ${application.pilot.experience} exp',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${application.pilot.rating} rating · ${application.drone.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
          ],
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
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
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _LineList extends StatelessWidget {
  const _LineList({required this.items, required this.icon});
  final List<String> items;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    children: items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(icon, color: AppColors.green, size: 17),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13.5,
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

class _Capability extends StatelessWidget {
  const _Capability({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.greenBg,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.green,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: const Text(
      'Applications from pilots will appear here as soon as they apply.',
      style: TextStyle(color: AppColors.grey, fontSize: 13),
    ),
  );
}

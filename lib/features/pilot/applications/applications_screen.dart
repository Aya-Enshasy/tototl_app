import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../shared/pilot_data.dart';
import 'application_details_screen.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PilotApplicationsStore.instance,
      builder: (context, _) {
        final applications = PilotApplicationsStore.instance.applications;
        if (compact) {
          return Column(
            children: applications
                .take(2)
                .map(
                  (application) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ApplicationCard(
                      application: application,
                      compact: true,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                const Text(
                  'My Applications',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${PilotApplicationsStore.instance.activeCount} active applications',
                  style: const TextStyle(color: AppColors.grey, fontSize: 13.5),
                ),
                const SizedBox(height: 20),
                ...applications.map(
                  (application) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ApplicationCard(application: application),
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

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, this.compact = false});

  final PilotApplication application;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status);
    final statusBackground = _statusBackground(application.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ApplicationDetailsScreen(application: application),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 42 : 48,
                height: compact ? 42 : 48,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.job.title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      compact
                          ? application.job.company
                          : '${application.job.company} · ${application.submittedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      application.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 7),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightGrey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(PilotApplicationStatus status) {
  switch (status) {
    case PilotApplicationStatus.submitted:
      return AppColors.blue;
    case PilotApplicationStatus.underReview:
      return AppColors.orange;
    case PilotApplicationStatus.approved:
      return AppColors.green;
    case PilotApplicationStatus.declined:
      return AppColors.red;
  }
}

Color _statusBackground(PilotApplicationStatus status) {
  switch (status) {
    case PilotApplicationStatus.submitted:
      return AppColors.blueBg;
    case PilotApplicationStatus.underReview:
      return AppColors.orangeBg;
    case PilotApplicationStatus.approved:
      return AppColors.greenBg;
    case PilotApplicationStatus.declined:
      return AppColors.redBg;
  }
}

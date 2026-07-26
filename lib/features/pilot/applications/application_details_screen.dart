import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../shared/pilot_data.dart';
import '../../operations/conversation_screen.dart';
import '../../operations/mission_tracking_screen.dart';
import '../../operations/operation_store.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  const ApplicationDetailsScreen({super.key, required this.application});

  final PilotApplication application;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status);
    final statusBackground = _statusBackground(application.status);
    final mission = OperationStore.instance.missionFor(application.id);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
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
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            application.status.label,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          application.job.title,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${application.job.company} · ${application.job.location}',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: AppColors.cardBorder),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Mission date',
                          value: application.job.date,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Rate',
                          value:
                              application.proposedRate ?? application.job.pay,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.schedule_outlined,
                          label: 'Application',
                          value: application.submittedAt,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Drone selected',
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.greenBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flight_rounded,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application.drone.name,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                application.drone.isFullMatch
                                    ? 'Full capability match'
                                    : 'Partial capability match',
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
                  if (application.coverNote != null &&
                      application.coverNote!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Cover note',
                      child: Text(
                        application.coverNote!,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                            application: application,
                            isCompany: false,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Message Company'),
                    ),
                  ),
                  if (mission != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MissionTrackingScreen(
                              mission: mission,
                              isCompany: false,
                            ),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                        ),
                        child: Text(
                          mission.stage == MissionStage.offerSent
                              ? 'Review Offer'
                              : 'Open Mission',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(18),
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
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

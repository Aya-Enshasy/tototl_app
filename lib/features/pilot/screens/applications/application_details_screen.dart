import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../operations/conversation_screen.dart';
import '../../../operations/mission_tracking_screen.dart';
import '../../../operations/operation_store.dart';
import '../shared/pilot_data.dart';


class ApplicationDetailsScreen extends StatefulWidget {
  const ApplicationDetailsScreen({super.key, required this.application});

  final PilotApplication application;

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  late PilotApplication _application;

  @override
  void initState() {
    super.initState();
    _application = widget.application;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_application.status);
    final statusBackground = _statusBackground(_application.status);
    final mission = OperationStore.instance.missionFor(_application.id);
    final approved = _application.status == PilotApplicationStatus.approved;

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
                            _application.status.label,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _application.job.title,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${_application.job.company} · ${_application.job.location}',
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
                          value: _application.job.date,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.timer_outlined,
                          label: 'Completion time',
                          value:
                              _application.estimatedCompletionTime?.isNotEmpty == true
                                                            ? _application.estimatedCompletionTime!
                                                            : '-',
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.play_circle_outline,
                          label: 'Start date',
                          value:
                              _application.availableStartDate?.isNotEmpty == true
                                                            ? _application.availableStartDate!
                                                            : _application.job.startTime ?? '-',
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Rate',
                          value:
                              _application.proposedRate ?? _application.job.pay,
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.schedule_outlined,
                          label: 'Application',
                          value: _application.submittedAt,
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
                                _application.drone.name,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _application.drone.isFullMatch
                                    ? 'Full capability match'
                                    : 'Partial capability match',
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12.5,
                                ),
                              ),
                              if (_application.droneSize != null && _application.droneSize!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                                                'Size: ${_application.droneSize!}',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 12,
                                                                  fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                                                            if (_application.droneDimensions != null && _application.droneDimensions!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                                                'Dimensions: ${_application.droneDimensions!}',
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Requested skills shown for clarity in the application
                  if (_application.job.requiredSkills.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Requested Skills',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _application.job.requiredSkills
                                .map((skill) => _CapabilityChip(label: skill))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          if (_application.skillsConfirmed.isNotEmpty) ...[
                            const Text('Pilot confirmed skills:', style: TextStyle(color: AppColors.grey, fontSize: 12.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _application.skillsConfirmed
                                  .map((skill) => _CapabilityChip(label: skill))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  // Show equipment confirmed by the pilot if provided
                  if (_application.equipmentConfirmed.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _SectionCard(
                                        title: 'Equipment confirmed by pilot',
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _application.equipmentConfirmed
                                              .map((e) => _CapabilityChip(label: e))
                                              .toList(),
                                        ),
                                      ),
                  ],
                  if (_application.coverNote != null && _application.coverNote!.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _SectionCard(
                                        title: 'Cover note',
                                        child: Text(
                                          _application.coverNote!,
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 13.5,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                  if (_application.additionalNotes != null && _application.additionalNotes!.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _SectionCard(
                                        title: 'Additional information',
                                        child: Text(
                                          _application.additionalNotes!,
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 13.5,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                  const SizedBox(height: 16),
                                    // Company action buttons (visible to company users)
                                    if (_application.status == PilotApplicationStatus.submitted || _application.status == PilotApplicationStatus.underReview) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton(
                                              onPressed: () {
                                                PilotApplicationsStore.instance.updateStatusById(_application.id, PilotApplicationStatus.approved);
                                                setState(() => _application = _application.copyWith(status: PilotApplicationStatus.approved));
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application accepted')));
                                              },
                                              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                                              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w800)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                PilotApplicationsStore.instance.updateStatusById(_application.id, PilotApplicationStatus.declined);
                                                setState(() => _application = _application.copyWith(status: PilotApplicationStatus.declined));
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application rejected')));
                                              },
                                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
                                              child: const Text('Reject'),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ConversationScreen(
                                              application: _application,
                                              isCompany: false,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                                        label: const Text('Message Company'),
                                      ),
                                    ),

                                    // Contact as company (opens conversation as company)
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ConversationScreen(
                                              application: _application,
                                              isCompany: true,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.forum_outlined),
                                        label: const Text('Contact Pilot'),
                                      ),
                                    ),
                  if (approved) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MissionTrackingScreen(
                              mission:
                                  mission ??
                                  OperationStore.instance.ensureApprovedMission(
                                                                      _application,
                                  ),
                              isCompany: false,
                            ),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                        ),
                        child: const Text(
                          'Open Workflow',
                          style: TextStyle(fontWeight: FontWeight.w800),
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

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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

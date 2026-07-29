import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'conversation_screen.dart';
import 'mission_details_screen.dart';
import 'operation_store.dart';

class MissionTrackingScreen extends StatelessWidget {
  const MissionTrackingScreen({
    super.key,
    required this.mission,
    required this.isCompany,
  });

  final Mission mission;
  final bool isCompany;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: OperationStore.instance,
        builder: (_, _) => Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                Row(
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
                        'Application Workflow',
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
                const SizedBox(height: 18),
                _HeroSummary(mission: mission),
                const SizedBox(height: 16),
                _QuickActions(mission: mission, isCompany: isCompany),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Steps',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _RoleChip(label: isCompany ? 'Company' : 'Pilot'),
                  ],
                ),
                const SizedBox(height: 10),
                ..._workflowSteps(context).asMap().entries.map(
                      (entry) => _WorkflowStepCard(
                        step: entry.value,
                        isLast: entry.key == _workflowSteps(context).length - 1,
                      ),
                    ),
              ],
            ),
          ),
        ),
      );

  List<_WorkflowStep> _workflowSteps(BuildContext context) {
    final current = _stageIndex(mission.stage);
    final contractUploaded = mission.contractFileName != null;
    final terminationUploaded = mission.terminationFileName != null;

    if (isCompany) {
      return [
        _WorkflowStep(
          icon: Icons.upload_file_outlined,
          title: 'Upload service contract',
          description: contractUploaded
              ? mission.contractFileName!
              : 'Attach the contract file for the pilot to download and sign.',
          done: contractUploaded,
          current: current == 1 && !contractUploaded,
          actionLabel: !contractUploaded ? 'Upload Contract' : null,
          action: !contractUploaded
              ? () => OperationStore.instance.uploadContract(mission)
              : null,
        ),
        _WorkflowStep(
          icon: Icons.play_circle_outline_rounded,
          title: 'Confirm job start',
          description: mission.pilotStarted
              ? 'Pilot is ready. Confirm start from your side.'
              : 'Your confirmation is saved, then the pilot also confirms.',
          done: mission.companyStarted,
          current: current == 2 || current == 3,
          actionLabel: mission.companyStarted ? null : 'Start Job',
          action: mission.companyStarted
              ? null
              : () => OperationStore.instance.markStartReady(
                    mission,
                    byCompany: true,
                  ),
        ),
        _WorkflowStep(
          icon: Icons.stop_circle_outlined,
          title: 'End work',
          description: mission.pilotEnded
              ? 'Pilot confirmed the work is finished.'
              : 'Confirm when the job is finished from your side.',
          done: mission.companyEnded,
          current: current == 4,
          actionLabel: mission.companyEnded ? null : 'End Work',
          action: mission.companyEnded
              ? null
              : () => OperationStore.instance.markWorkEnded(
                    mission,
                    byCompany: true,
                  ),
        ),
        _WorkflowStep(
          icon: Icons.description_outlined,
          title: 'Upload termination file',
          description: terminationUploaded
              ? mission.terminationFileName!
              : 'After both sides end work, upload the termination file.',
          done: terminationUploaded,
          current: mission.bothEnded && !terminationUploaded,
          actionLabel: !terminationUploaded ? 'Upload File' : null,
          action: !terminationUploaded
              ? () => OperationStore.instance.uploadTermination(mission)
              : null,
        ),
        _WorkflowStep(
          icon: Icons.lock_outline_rounded,
          title: 'Pay pilot securely',
          description:
              'Open the secure payment flow, then attach the transfer proof.',
          done: current >= 7,
          current: current == 5 || current == 6,
          actionLabel: current < 6
              ? 'Open Secure Payment'
              : current < 7
                  ? 'Attach Payment'
                  : null,
          action: current < 6
              ? () => OperationStore.instance.openSecurePayment(mission)
              : current < 7
                  ? () => OperationStore.instance.sendPilotPayment(mission)
                  : null,
        ),
        _WorkflowStep(
          icon: Icons.star_outline_rounded,
          title: 'Rate pilot',
          description: mission.pilotRating == null
              ? 'Leave your final review.'
              : '${mission.pilotRating}/5 submitted.',
          done: mission.pilotRating != null,
          current: current == 8,
          actionLabel: mission.pilotRating == null ? 'Rate Pilot' : null,
          action: mission.pilotRating == null
              ? () => _rate(context)
              : null,
        ),
      ];
    }

    return [
      _WorkflowStep(
        icon: Icons.edit_document,
        title: 'Download and sign contract',
        description: contractUploaded
            ? mission.contractFileName!
            : 'Waiting for the company to upload the contract.',
        done: current >= 2,
        current: contractUploaded && current == 1,
        actionLabel:
            contractUploaded && current < 2 ? 'Download & Sign' : null,
        action: contractUploaded && current < 2
            ? () => OperationStore.instance.signContract(mission)
            : null,
      ),
      _WorkflowStep(
        icon: Icons.play_circle_outline_rounded,
        title: 'Start job',
        description: mission.companyStarted
            ? 'Company is ready. Confirm start from your side.'
            : 'Your confirmation is saved, then the company also confirms.',
        done: mission.pilotStarted,
        current: current == 2 || current == 3,
        actionLabel: mission.pilotStarted ? null : 'Start Job',
        action: mission.pilotStarted
            ? null
            : () => OperationStore.instance.markStartReady(
                  mission,
                  byCompany: false,
                ),
      ),
      _WorkflowStep(
        icon: Icons.stop_circle_outlined,
        title: 'End work',
        description: mission.companyEnded
            ? 'Company confirmed the work is finished.'
            : 'Confirm when your work is finished.',
        done: mission.pilotEnded,
        current: current == 4,
        actionLabel: mission.pilotEnded ? null : 'End Work',
        action: mission.pilotEnded
            ? null
            : () => OperationStore.instance.markWorkEnded(
                  mission,
                  byCompany: false,
                ),
      ),
      _WorkflowStep(
        icon: Icons.draw_outlined,
        title: 'Sign termination file',
        description: terminationUploaded
            ? mission.terminationFileName!
            : 'Waiting for the company termination file.',
        done: current >= 5,
        current: terminationUploaded && current == 4,
        actionLabel:
            terminationUploaded && current < 5 ? 'Download & Sign' : null,
        action: terminationUploaded && current < 5
            ? () => OperationStore.instance.signTermination(mission)
            : null,
      ),
      _WorkflowStep(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Confirm payment received',
        description:
            'Confirm only after the money arrives in your payment account.',
        done: current >= 8,
        current: current == 7,
        actionLabel: current < 8 ? 'Confirm Received' : null,
        action: current < 8
            ? () => OperationStore.instance.confirmPaymentReceived(mission)
            : null,
      ),
      _WorkflowStep(
        icon: Icons.star_outline_rounded,
        title: 'Rate company',
        description: mission.companyRating == null
            ? 'Leave your final review.'
            : '${mission.companyRating}/5 submitted.',
        done: mission.companyRating != null,
        current: current == 8,
        actionLabel: mission.companyRating == null ? 'Rate Company' : null,
        action: mission.companyRating == null
            ? () => _rate(context)
            : null,
      ),
    ];
  }

  int _stageIndex(MissionStage stage) => switch (stage) {
        MissionStage.offerSent => 0,
        MissionStage.contractPending => 1,
        MissionStage.contractSigned => 2,
        MissionStage.readyToStart => 3,
        MissionStage.inProgress => 4,
        MissionStage.terminationPending => 4,
        MissionStage.terminationSigned => 5,
        MissionStage.paymentPending => 6,
        MissionStage.paymentSent => 7,
        MissionStage.completed => 8,
        MissionStage.rejected => -1,
      };

  void _rate(BuildContext context) {
    var selected = 5;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompany ? 'Rate the Pilot' : 'Rate the Company',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setSheet(() => selected = index + 1),
                    icon: Icon(
                      index < selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    if (isCompany) {
                      OperationStore.instance.ratePilot(mission, selected);
                    } else {
                      OperationStore.instance.rateCompany(mission, selected);
                    }
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Submit Rating'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
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
                Expanded(
                  child: Text(
                    mission.application.job.title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                _Status(label: mission.stage.label),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                _MetricChip(
                  icon: Icons.place_outlined,
                  label: mission.application.job.location,
                ),
                _MetricChip(
                  icon: Icons.calendar_today_outlined,
                  label: mission.date,
                ),
                _MetricChip(
                  icon: Icons.payments_outlined,
                  label: '\$${mission.amount.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.mission, required this.isCompany});

  final Mission mission;
  final bool isCompany;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(
                    application: mission.application,
                    isCompany: isCompany,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(isCompany ? 'Message Pilot' : 'Message Company'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MissionDetailsScreen(
                    mission: mission,
                    isCompany: isCompany,
                  ),
                ),
              ),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Details'),
            ),
          ),
        ],
      );
}

class _WorkflowStep {
  const _WorkflowStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.done,
    required this.current,
    this.meta,
    this.actionLabel,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool done;
  final bool current;
  final String? meta;
  final String? actionLabel;
  final VoidCallback? action;
}

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({required this.step, required this.isLast});

  final _WorkflowStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.done
        ? AppColors.green
        : step.current
            ? AppColors.blue
            : AppColors.lightGrey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: step.current ? AppColors.blueBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step.current ? AppColors.blue : AppColors.cardBorder,
          width: step.current ? 1.3 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: step.done
                  ? AppColors.green
                  : step.current
                      ? Colors.white
                      : AppColors.blueBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.done ? Icons.check_rounded : step.icon,
              color: step.done ? Colors.white : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _StepStatus(
                  label: step.done
                      ? 'Completed'
                      : step.current
                          ? 'Now'
                          : 'Waiting',
                  color: color,
                ),
                const SizedBox(height: 5),
                Text(
                  step.description,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                if (step.meta != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    step.meta!,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (step.actionLabel != null && step.action != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      onPressed: step.action,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        step.actionLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
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
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.blueBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.blue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _StepStatus extends StatelessWidget {
  const _StepStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _Status extends StatelessWidget {
  const _Status({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.greenBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

// mission_tracking_pilot_screen.dart
//
// Pilot-facing mission workflow. Order of steps:
//  1) Download & sign the contract the company uploaded.
//  2) Start the job (confirmation - waits on the company too).
//  3) End the work (confirmation - waits on the company too).
//  4) Sign the termination file the company uploaded.
//  5) Confirm the payment was received (after the company sends proof).
//  6) Rate the company.

import 'package:flutter/material.dart' hide StepState;
import '../operations/conversation_screen.dart';
import '../operations/mission_details_screen.dart';
import '../operations/operation_store.dart';
import '../shared/mission_workflow_shared.dart';

import '../../core/theme/app_colors.dart';

class MissionTrackingPilotScreen extends StatefulWidget {
  const MissionTrackingPilotScreen({super.key, required this.mission});

  final Mission mission;

  @override
  State<MissionTrackingPilotScreen> createState() =>
      _MissionTrackingPilotScreenState();
}

class _MissionTrackingPilotScreenState
    extends State<MissionTrackingPilotScreen> {
  Mission get mission => widget.mission;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: OperationStore.instance,
    builder: (_, _) {
      final steps = _buildSteps(context);
      final completed =
          steps.where((s) => s.state == StepState.done).length;
      return Scaffold(
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
                      'Mission Progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 18),
              MissionHeroCard(
                title: mission.application.job.title,
                statusLabel: mission.stage.label,
                chips: [
                  MissionMetricChip(
                    icon: Icons.place_outlined,
                    label: mission.application.job.location,
                  ),
                  MissionMetricChip(
                    icon: Icons.calendar_today_outlined,
                    label: mission.date,
                  ),
                  MissionMetricChip(
                    icon: Icons.payments_outlined,
                    label: '\$${mission.amount.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                            application: mission.application,
                            isCompany: false,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Message Company',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MissionDetailsScreen(
                            mission: mission,
                            isCompany: false,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text(
                        'Details',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              WorkflowProgressHeader(
                completedCount: completed,
                totalCount: steps.length,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Steps',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...steps.asMap().entries.map(
                    (entry) => WorkflowStepTimelineTile(
                  step: entry.value,
                  isLast: entry.key == steps.length - 1,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

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

  List<WorkflowStep> _buildSteps(BuildContext context) {
    final current = _stageIndex(mission.stage);
    final contractUploaded = mission.contractFileName != null;
    final terminationUploaded = mission.terminationFileName != null;

    // Step 1: download & sign contract.
    final signStep = WorkflowStep(
      kind: StepKind.signature,
      icon: Icons.edit_document,
      title: 'Download & Sign Contract',
      description: contractUploaded
          ? 'The company uploaded the service contract. Download and sign it, then tap "Start Job" to attach it automatically.'
          : 'Waiting for the company to upload the service contract for this mission.',
      attachmentName: current >= 2 ? mission.contractFileName : null,
      state: current >= 2
          ? StepState.done
          : contractUploaded
          ? StepState.current
          : StepState.waitingOnOther,
      actionLabel: contractUploaded && current < 2 ? 'Download & Sign' : null,
      action: contractUploaded && current < 2
          ? () => OperationStore.instance.signContract(mission)
          : null,
      helper: current >= 2
          ? null
          : contractUploaded
          ? 'Your signature is attached automatically when the job starts.'
          : null,
    );

    // Step 2: start job (mutual confirmation).
    final startStep = WorkflowStep(
      kind: StepKind.confirm,
      icon: Icons.play_circle_outline_rounded,
      title: 'Start Job',
      description: mission.companyStarted
          ? 'The company is ready to start the job. Confirm on your end to kick off the mission.'
          : 'Your confirmation is saved first, then you wait on the company to confirm too.',
      state: mission.pilotStarted
          ? (current >= 4 ? StepState.done : StepState.waitingOnOther)
          : (current == 2 || current == 3)
          ? StepState.current
          : StepState.upcoming,
      actionLabel: mission.pilotStarted ? null : 'Start Job',
      action: mission.pilotStarted
          ? null
          : () => OperationStore.instance.markStartReady(
        mission,
        byCompany: false,
      ),
      helper: mission.pilotStarted && current < 4
          ? 'Waiting for the company to confirm the job has actually started.'
          : null,
    );

    // Step 3: end work (mutual confirmation).
    final endStep = WorkflowStep(
      kind: StepKind.confirm,
      icon: Icons.stop_circle_outlined,
      title: 'End Job',
      description: mission.companyEnded
          ? 'The company confirmed the work is finished on their end.'
          : 'Confirm once you have actually finished carrying out the mission.',
      state: mission.pilotEnded
          ? (terminationUploaded ? StepState.done : StepState.waitingOnOther)
          : current == 4
          ? StepState.current
          : StepState.upcoming,
      actionLabel: mission.pilotEnded ? null : 'End Job',
      action: mission.pilotEnded
          ? null
          : () => OperationStore.instance.markWorkEnded(
        mission,
        byCompany: false,
      ),
      helper: mission.pilotEnded && !terminationUploaded
          ? 'Waiting for the company to confirm and issue the termination file.'
          : null,
    );

    // Step 4: sign termination file.
    final terminationStep = WorkflowStep(
      kind: StepKind.signature,
      icon: Icons.draw_outlined,
      title: 'Sign Termination File',
      description: terminationUploaded
          ? 'The company uploaded the contract termination file. Review and sign it to officially close the mission.'
          : 'Waiting for the company to upload the contract termination file after both sides end the job.',
      attachmentName: current >= 5 ? mission.terminationFileName : null,
      state: current >= 5
          ? StepState.done
          : terminationUploaded
          ? StepState.current
          : StepState.waitingOnOther,
      actionLabel: terminationUploaded && current < 5 ? 'Download & Sign' : null,
      action: terminationUploaded && current < 5
          ? () => OperationStore.instance.signTermination(mission)
          : null,
    );

    // Step 5: confirm payment received.
    final paymentStep = WorkflowStep(
      kind: StepKind.confirm,
      icon: Icons.account_balance_wallet_outlined,
      title: 'Confirm Payment Received',
      description: current == 7
          ? 'The company sent the payment and attached transfer proof. Verify the amount arrived, then confirm receipt.'
          : 'Waiting for the company to complete payment and attach transfer proof.',
      state: current >= 8
          ? StepState.done
          : current == 7
          ? StepState.current
          : StepState.waitingOnOther,
      actionLabel: current == 7 ? 'Confirm Receipt' : null,
      action: current == 7
          ? () => OperationStore.instance.confirmPaymentReceived(mission)
          : null,
      helper: current == 7
          ? 'Only confirm after actually verifying the amount has reached your account.'
          : null,
    );

    // Step 6: rate the company.
    final ratingStep = WorkflowStep(
      kind: StepKind.rating,
      icon: Icons.star_outline_rounded,
      title: 'Rate Company',
      description: mission.companyRating == null
          ? 'Share your final rating of your experience with this company.'
          : 'Your rating was submitted: ${mission.companyRating}/5.',
      state: mission.companyRating != null
          ? StepState.done
          : current == 8
          ? StepState.current
          : StepState.upcoming,
      actionLabel: mission.companyRating == null ? 'Rate Company' : null,
      action: mission.companyRating == null ? () => _rate(context) : null,
    );

    return [
      signStep,
      startStep,
      endStep,
      terminationStep,
      paymentStep,
      ratingStep,
    ];
  }

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
              const Text(
                'Rate Company',
                style: TextStyle(
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
                    OperationStore.instance.rateCompany(mission, selected);
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
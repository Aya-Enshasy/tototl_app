// mission_tracking_company_screen.dart
//
// Company-facing mission workflow. Order of steps:
//  1) Upload the services contract (pilot then downloads & signs it).
//  2) Start the job (confirmation - waits on the pilot too).
//  3) End the work (confirmation - waits on the pilot too).
//  4) Upload the termination file (pilot then signs it).
//  5) Choose a payment method, open secure payment, then attach
//     a proof-of-transfer image (this is where the "how do you
//     want to pay" question lives).
//  6) Rate the pilot.

import 'package:flutter/material.dart' hide StepState;
import '../operations/conversation_screen.dart';
import '../operations/mission_details_screen.dart';
import '../operations/operation_store.dart';
import '../shared/mission_workflow_shared.dart';

import '../../core/theme/app_colors.dart';

class MissionTrackingCompanyScreen extends StatefulWidget {
  const MissionTrackingCompanyScreen({super.key, required this.mission});

  final Mission mission;
  @override
  State<MissionTrackingCompanyScreen> createState() =>
      _MissionTrackingCompanyScreenState();
}

class _MissionTrackingCompanyScreenState
    extends State<MissionTrackingCompanyScreen> {
  Mission get mission => widget.mission;

  /// Chosen before opening the secure payment flow. Purely a UI
  /// selection here — wire it into OperationStore.openSecurePayment
  /// once that call accepts a payment-method argument.
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: OperationStore.instance,
    builder: (_, _) {
      final steps = _buildSteps(context);
      final completed = steps.where((s) => s.state == StepState.done).length;
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
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
                            isCompany: true,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Message Pilot'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MissionDetailsScreen(
                            mission: mission,
                            isCompany: true,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_outlined),
                      label: const Text('Details'),
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
                  extra: entry.value.title == 'Secure Payment to Pilot'
                      ? PaymentMethodPicker(
                          selected: _selectedPaymentMethod,
                          onSelected: (value) =>
                              setState(() => _selectedPaymentMethod = value),
                        )
                      : null,
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
    final paymentMethodChosen = _selectedPaymentMethod != null;

    // Step 1: upload contract.
    final contractStep = WorkflowStep(
      kind: StepKind.document,
      icon: Icons.upload_file_outlined,
      title: 'Upload Service Contract',
      description: contractUploaded
          ? 'Contract uploaded. Pilot will download and sign it.'
          : 'Upload the contract file for the pilot to download and sign.',
      attachmentName: contractUploaded ? mission.contractFileName : null,
      state: contractUploaded ? StepState.done : StepState.current,
      actionLabel: !contractUploaded ? 'Upload Contract' : null,
      action: !contractUploaded
          ? () => OperationStore.instance.uploadContract(mission)
          : null,
    );

    // Step 2: start job.
    final startStep = WorkflowStep(
      kind: StepKind.confirm,
      icon: Icons.play_circle_outline_rounded,
      title: 'Confirm Start Work',
      description: mission.pilotStarted
          ? 'Pilot is ready to start. Confirm to launch the mission.'
          : 'Your confirmation is saved first, then waits for pilot confirmation too.',
      state: mission.companyStarted
          ? (current >= 4 ? StepState.done : StepState.waitingOnOther)
          : (current == 2 || current == 3)
          ? StepState.current
          : StepState.upcoming,
      actionLabel: mission.companyStarted ? null : 'Start Work',
      action: mission.companyStarted
          ? null
          : () => OperationStore.instance.markStartReady(
              mission,
              byCompany: true,
            ),
      helper: mission.companyStarted && current < 4
          ? 'Waiting for pilot confirmation to actually start work.'
          : null,
    );

    // Step 3: end work.
    final endStep = WorkflowStep(
      kind: StepKind.confirm,
      icon: Icons.stop_circle_outlined,
      title: 'End Work',
      description: mission.pilotEnded
          ? 'Pilot confirmed work completion from their side.'
          : 'Confirm when you actually finish executing the mission.',
      state: mission.companyEnded
          ? StepState.done
          : current == 4
          ? StepState.current
          : StepState.upcoming,
      actionLabel: mission.companyEnded ? null : 'End Work',
      action: mission.companyEnded
          ? null
          : () =>
                OperationStore.instance.markWorkEnded(mission, byCompany: true),
      helper: mission.companyEnded && !mission.pilotEnded
          ? 'Waiting for pilot confirmation to end work too.'
          : null,
    );

    // Step 4: upload termination file.
    final terminationStep = WorkflowStep(
      kind: StepKind.document,
      icon: Icons.description_outlined,
      title: 'Upload Termination File',
      description: terminationUploaded
          ? 'Termination file uploaded. Waiting for pilot signature.'
          : 'After both parties finish, upload the contract termination file.',
      attachmentName: terminationUploaded ? mission.terminationFileName : null,
      state: terminationUploaded
          ? StepState.done
          : mission.bothEnded
          ? StepState.current
          : StepState.upcoming,
      actionLabel: !terminationUploaded && mission.bothEnded
          ? 'Upload Termination File'
          : null,
      action: !terminationUploaded && mission.bothEnded
          ? () => OperationStore.instance.uploadTermination(mission)
          : null,
    );

    // Step 5a/5b: choose payment method + open secure payment, then
    // attach the transfer proof image.
    final proofAttached = current >= 7;
    final paymentStep = WorkflowStep(
      kind: proofAttached ? StepKind.proof : StepKind.choice,
      icon: Icons.lock_outline_rounded,
      title: 'Secure Payment to Pilot',
      description: proofAttached
          ? 'Amount sent. Attach transfer proof image for pilot to review.'
          : current < 6
          ? 'Choose payment method then open secure payment to send fees.'
          : 'Attach transfer proof image to complete this step.',
      attachmentName: proofAttached ? 'Payment Proof.jpg' : null,
      state: current >= 8
          ? StepState.done
          : (current == 5 || current == 6)
          ? StepState.current
          : StepState.upcoming,
      actionLabel: current < 6
          ? 'Open Secure Payment'
          : current < 7
          ? 'Attach Payment Proof'
          : null,
      action: current < 6
          ? (paymentMethodChosen
                ? () => OperationStore.instance.openSecurePayment(mission)
                : null)
          : current < 7
          ? () => OperationStore.instance.sendPilotPayment(mission)
          : null,
      helper: current < 6 && !paymentMethodChosen
          ? 'Choose payment method first to enable secure payment button.'
          : null,
    );

    // Step 6: rate the pilot.
    final ratingStep = WorkflowStep(
      kind: StepKind.rating,
      icon: Icons.star_outline_rounded,
      title: 'Rate Pilot',
      description: mission.pilotRating == null
          ? 'Share your final rating of the pilot\'s performance on this mission.'
          : 'Your rating sent: ${mission.pilotRating}/5.',
      state: mission.pilotRating != null
          ? StepState.done
          : current == 8
          ? StepState.current
          : StepState.upcoming,
      actionLabel: mission.pilotRating == null ? 'Rate Pilot' : null,
      action: mission.pilotRating == null ? () => _rate(context) : null,
    );

    return [
      contractStep,
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
                'Rate Pilot',
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
                    OperationStore.instance.ratePilot(mission, selected);
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Send Rating'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

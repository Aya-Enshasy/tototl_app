import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'operation_store.dart';
import 'deliverables_screen.dart';
import 'mission_details_screen.dart';

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
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                const Expanded(
                  child: Text(
                    'Mission Tracking',
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
            const SizedBox(height: 20),
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
                  Text(
                    mission.application.job.title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${mission.date} · ${mission.hours} hours',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '\$${mission.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      _Status(label: mission.stage.label),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Mission progress',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ..._steps().map(
              (step) => _StepRow(
                label: step.$1,
                done: _stageIndex(mission.stage) >= step.$2,
                current: _stageIndex(mission.stage) == step.$2,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
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
                label: const Text('Open Mission Details'),
              ),
            ),
            if (!isCompany && mission.stage == MissionStage.inProgress) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DeliverablesScreen(mission: mission),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Prepare Deliverables'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _action(context),
          ],
        ),
      ),
    ),
  );
  List<(String, int)> _steps() => const [
    ('Offer agreed', 1),
    ('Escrow funded', 2),
    ('Mission in progress', 3),
    ('Pilot submitted work', 4),
    ('Funds released', 5),
  ];
  int _stageIndex(MissionStage stage) => switch (stage) {
    MissionStage.offerSent => 0,
    MissionStage.awaitingFunding => 1,
    MissionStage.scheduled => 2,
    MissionStage.inProgress => 3,
    MissionStage.submitted => 4,
    MissionStage.completed => 5,
    MissionStage.rejected => -1,
  };
  Widget _action(BuildContext context) {
    String? label;
    VoidCallback? action;
    if (!isCompany && mission.stage == MissionStage.offerSent) {
      label = 'Accept Offer';
      action = () => OperationStore.instance.acceptOffer(mission);
    }
    if (isCompany && mission.stage == MissionStage.awaitingFunding) {
      label = 'Fund Escrow';
      action = () => OperationStore.instance.fundEscrow(mission);
    }
    if (!isCompany && mission.stage == MissionStage.scheduled) {
      label = 'Start Mission';
      action = () => OperationStore.instance.startMission(mission);
    }
    if (!isCompany && mission.stage == MissionStage.inProgress) {
      label = 'Submit Completed Work';
      action = () => OperationStore.instance.submitWork(mission);
    }
    if (isCompany && mission.stage == MissionStage.submitted) {
      label = 'Confirm & Release Funds';
      action = () => OperationStore.instance.confirmAndRelease(mission);
    }
    if (mission.stage == MissionStage.completed) {
      label = isCompany ? 'Rate Pilot' : 'Rate Company';
      action = () => _rate(context);
    }
    if (label == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _rate(BuildContext context) {
    var selected = 5;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
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

class _Status extends StatelessWidget {
  const _Status({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.blueBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.blue,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.current,
  });
  final String label;
  final bool done;
  final bool current;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: done
              ? AppColors.green
              : current
              ? AppColors.blue
              : AppColors.lightGrey,
          size: 21,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: done || current ? AppColors.navy : AppColors.grey,
            fontWeight: current ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

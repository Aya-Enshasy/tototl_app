import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../operations/mission_tracking_screen.dart';
import '../../../operations/operation_store.dart';

class CompanyOperationsScreen extends StatelessWidget {
  const CompanyOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OperationStore.instance,
      builder: (context, _) {
        final missions = OperationStore.instance.missions
            .where((m) => m.stage != MissionStage.rejected)
            .toList()
          ..sort((a, b) => b.stage.index.compareTo(a.stage.index));

        final activeCount = missions
            .where((m) => m.stage != MissionStage.completed)
            .length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                const Text(
                  'Operations',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$activeCount active mission${activeCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 20),
                if (missions.isEmpty)
                  const _EmptyOperations()
                else
                  ...missions.map(
                    (mission) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MissionCard(mission: mission),
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

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(mission.stage);
    final stageBg = _stageBackground(mission.stage);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MissionTrackingScreen(
              mission: mission,
              isCompany: true,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blueBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: AppColors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.application.job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          mission.application.pilot.name,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12.5,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: stageBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mission.stage.label,
                      style: TextStyle(
                        color: stageColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    mission.date,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$${mission.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stageColor(MissionStage stage) => switch (stage) {
    MissionStage.completed => AppColors.green,
    MissionStage.rejected => AppColors.red,
    MissionStage.inProgress => AppColors.blue,
    MissionStage.paymentPending || MissionStage.paymentSent => AppColors.orange,
    _ => AppColors.purple,
  };

  Color _stageBackground(MissionStage stage) => switch (stage) {
    MissionStage.completed => AppColors.greenBg,
    MissionStage.rejected => AppColors.redBg,
    MissionStage.inProgress => AppColors.blueBg,
    MissionStage.paymentPending || MissionStage.paymentSent => AppColors.orangeBg,
    _ => AppColors.purpleBg,
  };
}

class _EmptyOperations extends StatelessWidget {
  const _EmptyOperations();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.purpleBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: AppColors.purple,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No active operations yet',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'When you approve a pilot application, the mission workflow will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

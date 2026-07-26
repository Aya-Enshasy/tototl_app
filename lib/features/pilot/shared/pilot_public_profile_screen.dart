import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'pilot_data.dart';

class PilotPublicProfileScreen extends StatelessWidget {
  const PilotPublicProfileScreen({super.key, required this.pilot});

  final PilotProfile pilot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    'Pilot Profile',
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.blueBg,
                    child: Text(
                      pilot.name.substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pilot.name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pilot.location,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (pilot.verified) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: AppColors.green,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Verified Pilot',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Metric(
                        value: pilot.rating,
                        label: '${pilot.reviewCount} reviews',
                      ),
                      _Metric(value: pilot.experience, label: 'Experience'),
                      _Metric(value: pilot.successRate, label: 'Success'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'About',
              child: Text(
                pilot.about,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Capabilities',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pilot.skills
                    .map((skill) => _SkillChip(label: skill))
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Registered Drones',
              child: Column(
                children: pilot.drones
                    .map(
                      (drone) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DroneRow(drone: drone),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
      ),
    ],
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
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _DroneRow extends StatelessWidget {
  const _DroneRow({required this.drone});
  final PilotDrone drone;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(Icons.flight_rounded, color: AppColors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drone.name,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                drone.year,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          drone.isFullMatch ? 'Verified' : 'Active',
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

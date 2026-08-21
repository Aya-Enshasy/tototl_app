import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../jobs/job_details.dart';
import '../../shared/pilot_data.dart';
import 'app_card.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const JobDetailsScreen(job: solarFarmJob),
          ),
        ),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.orangeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.solar_power_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SunTech Energy Ltd.',
                          style: TextStyle(fontSize: 13, color: AppColors.grey),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thermal Inspection - Solar Farm Array',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
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
              const SizedBox(height: 13),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.grey,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Mojave Desert, CA · 12 km',
                      style: TextStyle(fontSize: 12.5, color: AppColors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '2026-08-14',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Text(
                    r'$850/day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Tag(label: 'Thermal'),
                  const SizedBox(width: 7),
                  _Tag(label: 'Imaging'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Full match',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
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
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

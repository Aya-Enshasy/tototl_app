import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
 import '../../../models/pilot_job_model.dart';
import '../../jobs/job_details.dart';
import 'app_card.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
  });

  final PilotJobModel job;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JobDetailsScreen(
                jobId: job.id,
              ),
            ),
          );
        },
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
                      color: AppColors.blueBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(job.serviceCategory),
                      color: AppColors.blue,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.categoryLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.grey,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          job.title.isEmpty
                              ? 'Untitled Job'
                              : job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.grey,
                  ),

                  const SizedBox(width: 4),

                  Expanded(
                    child: Text(
                      job.locationLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.grey,
                  ),

                  const SizedBox(width: 4),

                  Flexible(
                    child: Text(
                      job.dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Flexible(
                    child: Text(
                      job.payLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  if (job.requiredCapabilities.isNotEmpty)
                    _Tag(
                      label: job.requiredCapabilities.first,
                    ),

                  if (job.requiredCapabilities.length > 1) ...[
                    const SizedBox(width: 7),
                    _Tag(
                      label: job.requiredCapabilities[1],
                    ),
                  ],

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      job.status.isEmpty
                          ? 'Published'
                          : _pretty(job.status),
                      style: const TextStyle(
                        color: AppColors.blue,
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'inspection':
        return Icons.manage_search_rounded;

      case 'mapping':
        return Icons.map_outlined;

      case 'photography':
        return Icons.photo_camera_outlined;

      case 'construction':
        return Icons.construction_outlined;

      case 'surveying':
        return Icons.straighten_rounded;

      default:
        return Icons.flight_takeoff_rounded;
    }
  }

  String _pretty(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return '';

    return clean
        .split(RegExp(r'[_\s-]+'))
        .where((item) => item.isNotEmpty)
        .map(
          (item) =>
      '${item[0].toUpperCase()}${item.substring(1).toLowerCase()}',
    )
        .join(' ');
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 92,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.5,
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
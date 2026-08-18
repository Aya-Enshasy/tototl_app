import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  // =========================================================
  // GREETING BASED ON DEVICE TIME
  // =========================================================
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // =========================================================
        // USER IMAGE + VERIFIED BADGE
        // =========================================================
        Stack(
          clipBehavior: Clip.none,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.blueBg,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?img=47',
              ),
            ),

            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 17,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 13),

        // =========================================================
        // USER INFO
        // =========================================================
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 3),

              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Aya Inshasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),

                  const SizedBox(width: 4),

                  const Text(
                    '4.9',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // =========================================================
        // AVAILABILITY STATUS
        // =========================================================
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.greenBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Available',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';


class DroneHero extends StatelessWidget {
  const DroneHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/d.png', // صورة الخلفية الحاوية على الدرون والجبال
              fit: BoxFit.contain,
              width: double.infinity,
              height: 150,
              alignment: Alignment.topCenter,
              // أداة حماية في حال عدم العثور على الصورة
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  width: double.infinity,
                  color: AppColors.blueBg,
                  child: const Center(
                    child: Icon(
                      Icons.flight,
                      size: 60,
                      color: AppColors.logoTurquoiseDark,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
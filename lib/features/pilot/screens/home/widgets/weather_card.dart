import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'app_card.dart';

 class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weather in Dubai',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.wb_sunny, color: AppColors.gold, size: 34),
              SizedBox(width: 8),
              Text(
                '22°C',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const Text('Sunny', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.air, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text('Wind 12 km/h', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text('Visibility 10 km', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
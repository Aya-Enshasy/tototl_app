import 'package:flutter/material.dart';

import 'app_card.dart';

class MyDroneCard extends StatelessWidget {
  const MyDroneCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Drone',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                const Text(
                  'DJI Mavic 3 Pro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.check_circle, size: 16, color: Color(0xFF1FBE6B)),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(color: Color(0xFF1FBE6B), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/drone.png',
            height: 60,
            width: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.flight, size: 50, color: Color(0xFF3B6BF5)),
          ),
        ],
      ),
    );

   }
}


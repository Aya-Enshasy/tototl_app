import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tototl_app/features/pilot/home/widgets/app_card.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                  color: const Color(0xFFEFF3FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub_outlined, color: Color(0xFF3B6BF5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'GeoVision Solutions',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      'Precision Mapping Project',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.favorite_border, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
              SizedBox(width: 4),
              Text('Dubai, UAE', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 14),
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text('May 28 – Jun 2, 2025',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '\$850 / day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1FBE6B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tag('DJI Mavic 3E'),
              const SizedBox(width: 8),
              _tag('LiDAR'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '96% Match',
                  style: TextStyle(
                    color: Color(0xFF1FBE6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6BF5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
Widget _tag(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F6FC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, color: Color(0xFF1A1F36)),
    ),
  );
}

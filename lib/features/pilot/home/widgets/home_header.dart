import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(
            'https://i.pravatar.cc/150?img=47',
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const Text(
                'Aya Inshasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1FBE6B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    'Verified Pilot',
                    style: TextStyle(
                      color: Color(0xFF1FBE6B),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _NotificationBell(count: 3),
      ],
    );
  }
}
class _NotificationBell extends StatelessWidget {
  final int count;
  final bool small;
  const _NotificationBell({required this.count, this.small = false});

  @override
  Widget build(BuildContext context) {
    final bell = Container(
      height: small ? 24 : 46,
      width: small ? 24 : 46,
      decoration: small
          ? null
          : BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.notifications_none, size: small ? 22 : 22, color: const Color(0xFF1A1F36)),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        bell,
        Positioned(
          right: small ? -4 : 4,
          top: small ? -4 : 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
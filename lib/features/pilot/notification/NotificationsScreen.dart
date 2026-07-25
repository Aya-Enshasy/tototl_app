import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _today = [
    _NotificationData(
      icon: Icons.check_rounded,
      iconBg: AppColors.greenBg,
      iconColor: AppColors.green,
      title: 'Job Accepted',
      description: 'Your application for Precision Mapping has been accepted',
      time: '9:41 AM',
    ),
    _NotificationData(
      icon: Icons.work_outline_rounded,
      iconBg: AppColors.blueBg,
      iconColor: AppColors.blue,
      title: 'New Job Posted',
      description: 'A new Powerline Inspection job matches your profile',
      time: '8:30 AM',
    ),
    _NotificationData(
      icon: Icons.chat_bubble_outline_rounded,
      iconBg: AppColors.purpleBg,
      iconColor: AppColors.purple,
      title: 'Message from Client',
      description: 'GeoVision Solutions sent you a new message',
      time: '7:15 AM',
    ),
  ];

  static const _yesterday = [
    _NotificationData(
      icon: Icons.account_balance_wallet_outlined,
      iconBg: AppColors.greenBg,
      iconColor: AppColors.green,
      title: 'Payment Received',
      description:
      'You received a payment of \$680 for Solar Farm Inspection',
      time: 'Yesterday',
    ),
    _NotificationData(
      icon: Icons.warning_amber_rounded,
      iconBg: AppColors.orangeBg,
      iconColor: AppColors.orange,
      title: 'Safety Alert',
      description: 'High winds expected in your area tomorrow',
      time: 'Yesterday',
    ),
  ];

  static const _earlier = [
    _NotificationData(
      icon: Icons.remove_red_eye_outlined,
      iconBg: AppColors.redBg,
      iconColor: AppColors.red,
      title: 'Profile Viewed',
      description: 'BuildCore viewed your profile',
      time: 'May 23',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Notifications',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(Icons.settings_outlined, color: AppColors.navy, size: 22),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Today'),
          const SizedBox(height: 10),
          _NotificationGroupCard(items: _today),
          const SizedBox(height: 18),
          const _SectionLabel('Yesterday'),
          const SizedBox(height: 10),
          _NotificationGroupCard(items: _yesterday),
          const SizedBox(height: 18),
          const _SectionLabel('Earlier'),
          const SizedBox(height: 10),
          _NotificationGroupCard(items: _earlier),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _NotificationData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String time;

  const _NotificationData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
  });
}

/// كرت أبيض واحد يحتوي عدة صفوف إشعارات مفصولة بخط رفيع (Divider).
class _NotificationGroupCard extends StatelessWidget {
  final List<_NotificationData> items;
  const _NotificationGroupCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                bottom: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.time,
                  style: const TextStyle(color: AppColors.grey, fontSize: 11),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

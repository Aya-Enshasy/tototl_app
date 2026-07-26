import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
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
                  'Notifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('Mark all read')),
            ],
          ),
          const SizedBox(height: 12),
          const _Notice(
            icon: Icons.work_outline_rounded,
            color: AppColors.blue,
            title: 'New application received',
            detail: 'Marcus applied for Thermal Inspection - Solar Farm Array',
            time: '2h',
          ),
          const _Notice(
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.green,
            title: 'New mission message',
            detail: 'Aisha sent you a message about the site schedule',
            time: 'Yesterday',
          ),
          const _Notice(
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.orange,
            title: 'Escrow funding required',
            detail: 'Fund the mission after the pilot accepts your offer.',
            time: 'Yesterday',
          ),
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.time,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String time;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Text(time, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
      ],
    ),
  );
}

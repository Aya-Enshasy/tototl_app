import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CompanyMessagesScreen extends StatelessWidget {
  const CompanyMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          const Text(
            'Messages',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Conversation tools will be enabled with the operations workflow.',
            style: TextStyle(color: AppColors.grey, fontSize: 13.5),
          ),
          const SizedBox(height: 20),
          ...const [
            _MessagePreview(
              initial: 'M',
              name: 'Marcus Johansson',
              text: 'Thank you for reviewing my application.',
              time: '9:41 AM',
            ),
            _MessagePreview(
              initial: 'A',
              name: 'Aisha Okonkwo',
              text: 'I am available for the Aug 14 mission.',
              time: 'Yesterday',
            ),
          ],
        ],
      ),
    ),
  );
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({
    required this.initial,
    required this.name,
    required this.text,
    required this.time,
  });
  final String initial;
  final String name;
  final String text;
  final String time;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.blueBg,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
              ),
            ],
          ),
        ),
        Text(time, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../../../../core/theme/app_colors.dart';

class CompanyPublicProfileScreen extends StatelessWidget {
  const CompanyPublicProfileScreen({super.key});

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
              Expanded(
                child: Text(AppLanguage.text('Company Profile'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.solar_power_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'SunTech Energy Ltd.',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(AppLanguage.text('Renewable Energy · Mojave Desert, CA'),
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                    SizedBox(width: 4),
                    Text(AppLanguage.text('4.8 company rating'),
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(value: '47', label: AppLanguage.text('Jobs posted')),
                    _Metric(value: '4', label: AppLanguage.text('Pilots hired')),
                    _Metric(value: '4 hr', label: AppLanguage.text('Response time')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: AppLanguage.text('About'),
            child: const Text(
              'SunTech Energy delivers large-scale solar operations, inspections, and field intelligence across California. Every field mission is planned with safety and deliverable quality in mind.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: AppLanguage.text('Company Verification'),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: AppColors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(AppLanguage.text('Identity and business records verified'),
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

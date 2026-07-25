import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
// TODO: بدّل هاد الاستيراد بمسار شاشة الإعدادات الفعلي عندك
// import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                const _ProfileNameSection(),
                const SizedBox(height: 18),
                const _ProfileInfoList(),
                const SizedBox(height: 18),
                const _ProfileStatsRow(),
                const SizedBox(height: 22),
                _sectionTitleWithAdd('My Drones'),
                const SizedBox(height: 12),
                const _DroneCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitleWithAdd(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: AppColors.blueBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: AppColors.blue, size: 18),
        ),
      ],
    );
  }
}

/// غلاف الصورة العلوي (صورة درون فوق جبال) + سهم رجوع + زر الإعدادات +
/// صورة البروفايل الدائرية اللي "تطفو" فوق حافة الصورة السفلية + أيقونة تعديل عليها.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          child: Image.network(
            'https://images.unsplash.com/photo-1508444845599-5c89863b1c44?auto=format&fit=crop&w=900&q=80',
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 190,
              color: AppColors.tagBg,
              alignment: Alignment.center,
              child: const Icon(Icons.terrain, color: AppColors.grey, size: 40),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 12,
          child: _circleIconButton(Icons.arrow_back, () {}),
        ),
        Positioned(
          top: 10,
          right: 12,
          child: _circleIconButton(Icons.settings_outlined, () {
            // ينتقل على شاشة الإعدادات
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => const SettingsScreen()),
            // );
          }),
        ),
        Positioned(
          left: 20,
          bottom: -50,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.tagBg,
                      child: const Icon(Icons.person,
                          color: AppColors.grey, size: 40),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: _circleIconButton(Icons.edit_outlined, () {}, size: 30),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap, {double size = 38}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, size: size * 0.47, color: AppColors.navy),
      ),
    );
  }
}

/// اسم الطيار + شارة "Verified Pilot" الخضراء + صف التقييم بالنجوم.
class _ProfileNameSection extends StatelessWidget {
  const _ProfileNameSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Aya Inshasi',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.blueBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.autorenew_rounded,
                  color: AppColors.blue, size: 17),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: AppColors.green, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Verified Pilot',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(
              4,
                  (i) => const Icon(Icons.star_rounded,
                  color: AppColors.gold, size: 18),
            ),
            const Icon(Icons.star_rounded, color: AppColors.lightGrey, size: 18),
            const SizedBox(width: 6),
            const Text(
              '4.9',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '(128 reviews)',
              style: TextStyle(color: AppColors.grey, fontSize: 12.5),
            ),
          ],
        ),
      ],
    );
  }
}

/// قائمة المعلومات الشخصية: أيقونة + تسمية على اليسار، والقيمة على اليمين.
class _ProfileInfoList extends StatelessWidget {
  const _ProfileInfoList();

  static const _rows = [
    _InfoRowData(Icons.cake_outlined, 'DOB', 'May 12, 1992'),
    _InfoRowData(Icons.flag_outlined, 'Nationality', 'Palestinian'),
    _InfoRowData(Icons.language_outlined, 'Languages', 'Arabic, English'),
    _InfoRowData(Icons.phone_outlined, 'Phone', '+970 59 125 4567'),
    _InfoRowData(Icons.location_on_outlined, 'Local Region', 'Gaza, Palestine'),
    _InfoRowData(Icons.public_outlined, 'Willing to Work', 'UAE, KSA, Qatar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows
          .map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(r.icon, size: 17, color: AppColors.grey),
            const SizedBox(width: 10),
            Text(
              r.label,
              style: const TextStyle(
                  color: AppColors.grey, fontSize: 13.5),
            ),
            const Spacer(),
            Text(
              r.value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRowData(this.icon, this.label, this.value);
}

/// صف الإحصائيات الثلاث: سنوات الخبرة، عدد المهام، نسبة النجاح.
class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCard(value: '6+', label: 'Years Exp')),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: '248', label: 'Missions')),
        SizedBox(width: 10),
        Expanded(child: _StatCard(value: '98%', label: 'Success Rate')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// كرت الدرون المسجّل (DJI Mavic 3 Pro) مع التاجات وصورة الدرون.
class _DroneCard extends StatelessWidget {
  const _DroneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.tagBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.airplanemode_active_rounded,
                color: AppColors.navy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DJI Mavic 3 Pro',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '2023',
                  style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                ),
                const Text(
                  'SN: 3M3PK12345',
                  style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: const [
                    _MiniTag('LiDAR'),
                    _MiniTag('4K Camera'),
                    _MiniTag('RTK'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              'https://images.unsplash.com/photo-1579829366248-204fe8413f31?auto=format&fit=crop&w=200&q=80',
              width: 74,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 74,
                height: 56,
                color: AppColors.tagBg,
                child: const Icon(Icons.flight, color: AppColors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  const _MiniTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greenBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
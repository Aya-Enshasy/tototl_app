import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBannerImage(),
                    const SizedBox(height: 16),
                    _buildCompanyCard(),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(),
                    const SizedBox(height: 16),
                    _buildRequirementsCard(),
                    const SizedBox(height: 16),
                    _buildApplyCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _iconButton(Icons.arrow_back, () {}),
          Expanded(
            child: Text(
              'Job Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _iconButton(Icons.bookmark_border_rounded, () {}),
          const SizedBox(width: 8),
          _iconButton(Icons.ios_share_rounded, () {}),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 21, color: AppColors.navy),
      ),
    );
  }

  Widget _buildBannerImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        'https://images.unsplash.com/photo-1473968512647-3e447244af8f?auto=format&fit=crop&w=900&q=80',
        height: 210,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.tagBg,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF203A5A), Color(0xFFE7A76B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.flight, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  Widget _cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCompanyCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SkyVision Drones',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Verified Company',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Aerial Inspection Specialist',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: AppColors.grey),
              const SizedBox(width: 4),
              Text('Dubai, UAE',
                  style: TextStyle(color: AppColors.grey, fontSize: 13)),
              const SizedBox(width: 10),
              Text('·', style: TextStyle(color: AppColors.grey, fontSize: 13)),
              const SizedBox(width: 10),
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text('May 28, 2025',
                  style: TextStyle(color: AppColors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                '\$450 / day',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule_rounded, size: 16, color: AppColors.grey),
              const SizedBox(width: 5),
              Text('Full Day',
                  style: TextStyle(color: AppColors.grey, fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Tag('DJI Mavic 3'),
              _Tag('Inspection'),
              _Tag('Infrastructure'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Description',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We are looking for an experienced pilot to conduct '
                'infrastructure inspection using drone...',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Read more',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard() {
    const requirements = [
      'Drone License (UAV)',
      'Insurance',
      '2+ Years Experience',
      'Good Communication',
    ];

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requirements',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...requirements.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 17, color: AppColors.lightGrey),
                  const SizedBox(width: 10),
                  Text(
                    r,
                    style: TextStyle(color: AppColors.grey, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyCard() {
    return _cardWrapper(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      '96%',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI Match',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Amazing match for your profile',
                  style: TextStyle(color: AppColors.grey, fontSize: 11.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Apply Now',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

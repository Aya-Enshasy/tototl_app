import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import '../../models/pilot_job_model.dart';

/// Read-only company profile shown to pilots from a mission.
///
/// All data is passed from GET /jobs/{id} through [PilotJobCompanySummary].
/// This screen intentionally performs no additional network request.
class PilotCompanyProfileScreen extends StatelessWidget {
  const PilotCompanyProfileScreen({
    super.key,
    required this.company,
  });

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _ProfileBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  onBack: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _CompanyHero(company: company),
                      const SizedBox(height: 14),
                      _AboutCard(company: company),
                      const SizedBox(height: 14),
                      _CompanyDetailsCard(company: company),
                      const SizedBox(height: 14),
                      _ServiceRegionsCard(company: company),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -130,
          right: -120,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.logoTurquoise.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 460,
          left: -160,
          child: IgnorePointer(
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withOpacity(0.055),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 7),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.navy,
                  size: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company Profile',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.45,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Company information for this mission',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHero extends StatelessWidget {
  const _CompanyHero({required this.company});

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    final name = company.displayName;
    final industry = company.industryType.trim();
    final location = company.locationLabel.trim();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071D39),
            Color(0xFF0A4055),
            Color(0xFF087E91),
          ],
          stops: [0.0, 0.56, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087E91).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -55,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.055),
                  width: 26,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CompanyAvatar(company: company),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.45,
                                    ),
                                  ),
                                ),
                                if (company.verified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.logoTurquoiseLight,
                                    size: 19,
                                  ),
                                ],
                              ],
                            ),
                            if (industry.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                industry,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 11.7,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroPill(
                      icon: company.verified
                          ? Icons.verified_user_outlined
                          : Icons.business_outlined,
                      label: company.verified ? 'Verified company' : 'Company',
                    ),
                    if (location.isNotEmpty &&
                        location.toLowerCase() != 'location not specified')
                      _HeroPill(
                        icon: Icons.location_on_outlined,
                        label: location,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({required this.company});

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    final name = company.displayName;

    return Container(
      width: 78,
      height: 78,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: company.hasProfilePhoto
          ? Image.network(
        company.profilePhoto,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Initials(value: name),
      )
          : _Initials(value: name),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8FBFB), Color(0xFFD9F1F6)],
        ),
      ),
      child: Text(
        _initials(value),
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.logoTurquoiseLight, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.company});

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    final description = company.description.trim();

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.apartment_rounded,
            eyebrow: 'ABOUT',
            title: 'About the company',
          ),
          const SizedBox(height: 14),
          Text(
            description.isEmpty
                ? 'No company description was provided.'
                : description,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.7,
              height: 1.62,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyDetailsCard extends StatelessWidget {
  const _CompanyDetailsCard({required this.company});

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailData>[
      if (company.industryType.trim().isNotEmpty)
        _DetailData(
          icon: Icons.work_outline_rounded,
          label: 'Industry',
          value: company.industryType.trim(),
        ),
      if (company.locationLabel.trim().isNotEmpty &&
          company.locationLabel.trim().toLowerCase() !=
              'location not specified')
        _DetailData(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: company.locationLabel.trim(),
        ),
      if (company.address.trim().isNotEmpty)
        _DetailData(
          icon: Icons.signpost_outlined,
          label: 'Address',
          value: company.address.trim(),
        ),
      if (company.website.trim().isNotEmpty)
        _DetailData(
          icon: Icons.language_rounded,
          label: 'Website',
          value: company.website.trim(),
        ),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.info_outline_rounded,
            eyebrow: 'COMPANY DETAILS',
            title: 'Company information',
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const Text(
              'No additional company information was provided.',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
                height: 1.5,
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              _DetailRow(data: rows[i]),
              if (i != rows.length - 1) const _Divider(),
            ],
        ],
      ),
    );
  }
}

class _DetailData {
  const _DetailData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.data});

  final _DetailData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.055),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(data.icon, color: AppColors.blue, size: 17),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 9.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  data.value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.2,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceRegionsCard extends StatelessWidget {
  const _ServiceRegionsCard({required this.company});

  final PilotJobCompanySummary company;

  @override
  Widget build(BuildContext context) {
    final regions = company.workRegions;

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.public_rounded,
            eyebrow: 'SERVICE AREA',
            title: 'Work regions',
            trailing: regions.isEmpty ? null : '${regions.length}',
          ),
          const SizedBox(height: 14),
          if (regions.isEmpty)
            const Text(
              'No work regions were listed by this company.',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 11.5,
                height: 1.5,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: regions
                  .map(
                    (region) => _RegionChip(
                  label: _regionLabel(region),
                ),
              )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_outlined,
            color: AppColors.green,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 10.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.82)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 41,
          height: 41,
          decoration: BoxDecoration(
            color: AppColors.logoTurquoise.withOpacity(0.075),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.logoTurquoise, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.logoTurquoise,
                  fontSize: 7.8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.75,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.055),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: AppColors.cardBorder),
    );
  }
}

String _regionLabel(PilotCompanyWorkRegion region) {
  final parts = <String>[
    region.city,
    region.state,
    region.country,
  ].where((value) => value.trim().isNotEmpty).toList();

  return parts.isEmpty ? 'Region' : parts.join(', ');
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'C';

  return parts.map((part) => part[0].toUpperCase()).join();
}

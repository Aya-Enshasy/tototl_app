import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import '../../models/pilot_job_model.dart';
import 'package:tototl_app/core/localization/app_language.dart';

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
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
                    children: [
                      _CompanyHero(company: company),
                      const SizedBox(height: 10),
                      _AboutCard(company: company),
                      const SizedBox(height: 10),
                      _CompanyDetailsCard(company: company),
                      const SizedBox(height: 10),
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
    return Container(
      color: const Color(0xFFF7FAFB),
      child: Stack(
        children: [
          Positioned(
            top: -145,
            right: -125,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF11AEB8).withOpacity(.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 500,
            left: -180,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0A2D46).withOpacity(.045),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFDDE6EA),
                    width: .8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A2D46).withOpacity(.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0A2D46),
                  size: 16.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('Company Profile'),
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 15.4,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLanguage.text('Company behind this mission'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D8E9B),
                    fontSize: 9.5,
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
    final hasWebsite = company.website.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFDDE6EA),
          width: .8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2D46).withOpacity(.055),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 102,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF092C41),
                        Color(0xFF0A4558),
                        Color(0xFF0A8C96),
                      ],
                      stops: [0, .58, 1],
                    ),
                  ),
                ),
                Positioned(
                  right: -35,
                  top: -55,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(.06),
                        width: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 12,
                  child: Icon(
                    Icons.apartment_rounded,
                    color: Colors.white.withOpacity(.075),
                    size: 72,
                  ),
                ),
                const Positioned(
                  left: 15,
                  top: 15,
                  child: Text(
                    'COMPANY PROFILE',
                    style: TextStyle(
                      color: Color(0xFF77E0D8),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .95,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _CompanyAvatar(company: company),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0A2D46),
                                    fontSize: 15.2,
                                    height: 1.12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.25,
                                  ),
                                ),
                              ),
                              if (company.verified) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF0A9AAA),
                                  size: 15,
                                ),
                              ],
                            ],
                          ),
                          if (industry.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              industry,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF768A98),
                                fontSize: 9.2,
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
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -17),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _CompanyQuickStat(
                      icon: company.verified
                          ? Icons.verified_user_outlined
                          : Icons.business_outlined,
                      label: 'STATUS',
                      value: company.verified ? 'Verified' : 'Company',
                      accent: const Color(0xFF0A9AAA),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _CompanyQuickStat(
                      icon: Icons.public_rounded,
                      label: 'REGIONS',
                      value: company.workRegions.isEmpty
                          ? 'Not listed'
                          : '${company.workRegions.length} areas',
                      accent: const Color(0xFF16795F),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _CompanyQuickStat(
                      icon: Icons.language_rounded,
                      label: 'WEBSITE',
                      value: hasWebsite ? 'Available' : 'Not listed',
                      accent: const Color(0xFF6B63B5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (location.isNotEmpty &&
              !location.toLowerCase().contains('not specified'))
            Transform.translate(
              offset: const Offset(0, -7),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF7D8E9B),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF677B88),
                          fontSize: 9.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanyQuickStat extends StatelessWidget {
  const _CompanyQuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 61,
      padding: const EdgeInsets.fromLTRB(9, 8, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE3EAED),
          width: .7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 14),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8A99A4),
              fontSize: 6.8,
              fontWeight: FontWeight.w900,
              letterSpacing: .55,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0A2D46),
              fontSize: 8.8,
              fontWeight: FontWeight.w800,
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
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2D46).withOpacity(.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: company.hasProfilePhoto
            ? Image.network(
          company.profilePhoto,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(value: name),
        )
            : _Initials(value: name),
      ),
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
          colors: [
            Color(0xFFE7FBF9),
            Color(0xFFDCEFF3),
          ],
        ),
      ),
      child: Text(
        _initials(value),
        style: const TextStyle(
          color: Color(0xFF0A2D46),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}


class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0A9AAA), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0A2D46),
              fontSize: 8.7,
              fontWeight: FontWeight.w700,
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
          _SectionHeader(
            icon: Icons.apartment_rounded,
            eyebrow: 'ABOUT',
            title: AppLanguage.text('About the company'),
          ),
          const SizedBox(height: 12),
          Text(
            description.isEmpty
                ? 'No company description was provided.'
                : description,
            style: const TextStyle(
              color: Color(0xFF425665),
              fontSize: 11.2,
              height: 1.55,
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
          label: AppLanguage.text('Industry'),
          value: company.industryType.trim(),
        ),
      if (company.locationLabel.trim().isNotEmpty &&
          !company.locationLabel.trim().toLowerCase().contains(
            'location not specified',
          ))
        _DetailData(
          icon: Icons.location_on_outlined,
          label: AppLanguage.text('Location'),
          value: company.locationLabel.trim(),
        ),
      if (company.address.trim().isNotEmpty)
        _DetailData(
          icon: Icons.signpost_outlined,
          label: AppLanguage.text('Address'),
          value: company.address.trim(),
        ),
      if (company.website.trim().isNotEmpty)
        _DetailData(
          icon: Icons.language_rounded,
          label: AppLanguage.text('Website'),
          value: company.website.trim(),
        ),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.info_outline_rounded,
            eyebrow: 'DETAILS',
            title: AppLanguage.text('Company information'),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'No additional company information was provided.',
              style: TextStyle(
                color: Color(0xFF8796A2),
                fontSize: 10.3,
                height: 1.45,
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            data.icon,
            color: const Color(0xFF0A9AAA),
            size: 15,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: Color(0xFF8998A3),
                    fontSize: 8.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  data.value,
                  style: const TextStyle(
                    color: Color(0xFF0A2D46),
                    fontSize: 10.6,
                    height: 1.3,
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
            title: AppLanguage.text('Work regions'),
            trailing: regions.isEmpty ? null : '${regions.length}',
          ),
          const SizedBox(height: 12),
          if (regions.isEmpty)
            const Text(
              'No work regions were listed by this company.',
              style: TextStyle(
                color: Color(0xFF8796A2),
                fontSize: 10.3,
                height: 1.45,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF159B7A).withOpacity(.11),
          width: .7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_outlined,
            color: Color(0xFF159B7A),
            size: 11.5,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF14795F),
              fontSize: 8.8,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFDDE6EA),
          width: .75,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2D46).withOpacity(.028),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0A9AAA),
            size: 15.5,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: Color(0xFF0A9AAA),
                  fontSize: 6.9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0A2D46),
                  fontSize: 11.8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.1,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: Color(0xFF0A9AAA),
                fontSize: 8.3,
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
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Divider(
        height: 1,
        color: Color(0xFFE7ECEF),
      ),
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

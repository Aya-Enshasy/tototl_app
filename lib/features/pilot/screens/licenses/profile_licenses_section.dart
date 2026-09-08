import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../controllers/pilot_license_controller.dart';
import '../../models/pilot_license_model.dart';
import '../../services/pilot_license_service.dart';
import 'pilot_license_form_screen.dart';
import 'pilot_license_details_screen.dart';
import 'pilot_licenses_screen.dart';

const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF52657D);
const Color _muted2 = Color(0xFF8CA0B8);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE7ECF1);
const Color _danger = Color(0xFFE45252);
const Color _warning = Color(0xFFE99A23);

class ProfileLicensesSection extends StatefulWidget {
  const ProfileLicensesSection({super.key});

  @override
  State<ProfileLicensesSection> createState() =>
      _ProfileLicensesSectionState();
}

class _ProfileLicensesSectionState
    extends State<ProfileLicensesSection> {
  late final PilotLicenseController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PilotLicenseController(
      PilotLicenseService(ApiClient()),
    );

    _controller.loadLicenses();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAll() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PilotLicensesScreen(),
      ),
    );

    if (!mounted) return;
    await _controller.loadLicenses();
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PilotLicenseFormScreen(),
      ),
    );

    if (changed == true) {
      await _controller.loadLicenses();
    }
  }

  Future<void> _openDetails(PilotLicenseModel license) async {
    if (license.id <= 0) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PilotLicenseDetailsScreen(
          licenseId: license.id,
          initialLicense: license,
        ),
      ),
    );

    if (changed == true) {
      await _controller.loadLicenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.045),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                count: _controller.licenses.length,
                onViewAll: _openAll,
                onAdd: _openAdd,
              ),
              const SizedBox(height: 12),
              if (_controller.isLoading && _controller.licenses.isEmpty)
                const _LicensesSkeleton()
              else if (_controller.errorMessage != null &&
                  _controller.licenses.isEmpty)
                _SectionError(
                  message: _controller.errorMessage!,
                  onRetry: _controller.loadLicenses,
                )
              else if (_controller.licenses.isEmpty)
                _EmptyLicenses(onAdd: _openAdd)
              else
                ..._controller.licenses
                    .take(2)
                    .map(
                      (license) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CompactLicenseCard(
                          license: license,
                          onTap: () => _openDetails(license),
                        ),
                      ),
                    ),
              if (_controller.licenses.length > 2) ...[
                const SizedBox(height: 2),
                Material(
                  color: _tealSoft,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _openAll,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_outlined,
                            size: 18,
                            color: _tealDark,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              '${_controller.licenses.length - 2} more credentials',
                              style: const TextStyle(
                                color: _tealDark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: _tealDark,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.count,
    required this.onViewAll,
    required this.onAdd,
  });

  final int count;
  final VoidCallback onViewAll;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF1FFFF),
                Color(0xFFDDF7F8),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _teal.withOpacity(0.14),
            ),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: _tealDark,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Licenses & Certifications',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Professional pilot credentials',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Add license',
          onPressed: onAdd,
          style: IconButton.styleFrom(
            backgroundColor: _tealSoft,
            foregroundColor: _tealDark,
          ),
          icon: const Icon(Icons.add_rounded),
        ),
        const SizedBox(width: 2),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: _tealDark,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: Text(
            count > 0 ? 'View all ($count)' : 'View all',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactLicenseCard extends StatelessWidget {
  const _CompactLicenseCard({
    required this.license,
    required this.onTap,
  });

  final PilotLicenseModel license;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _licenseStatus(license);

    return Material(
      color: const Color(0xFFFBFDFE),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 58,
                decoration: BoxDecoration(
                  color: _tealSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: _tealDark,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            license.licenseType.isEmpty
                                ? 'Pilot credential'
                                : license.licenseType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _MiniStatus(
                          label: status.label,
                          color: status.color,
                          background: status.background,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      license.issuingAuthority.isEmpty
                          ? 'Issuing authority not specified'
                          : license.issuingAuthority,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.numbers_rounded,
                          color: _muted2,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            license.licenseNumber.isEmpty
                                ? 'No number'
                                : license.licenseNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.event_outlined,
                          color: _muted2,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(license.expiresAt),
                          style: TextStyle(
                            color: status.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted2,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyLicenses extends StatelessWidget {
  const _EmptyLicenses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _tealSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: _tealDark,
              size: 23,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No licenses added yet',
            style: TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add your license or certification to strengthen your professional profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: _tealDark,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Add License',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _danger.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _danger,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 10.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LicensesSkeleton extends StatelessWidget {
  const _LicensesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          height: 84,
          margin: EdgeInsets.only(bottom: index == 0 ? 10 : 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F9),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _LicenseStatusData {
  const _LicenseStatusData({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;
}

_LicenseStatusData _licenseStatus(PilotLicenseModel license) {
  if (license.isExpired) {
    return const _LicenseStatusData(
      label: 'Expired',
      color: _danger,
      background: Color(0xFFFFEEEE),
    );
  }

  if (license.isExpiringSoon) {
    return const _LicenseStatusData(
      label: 'Expiring',
      color: _warning,
      background: Color(0xFFFFF5E6),
    );
  }

  return const _LicenseStatusData(
    label: 'Valid',
    color: _tealDark,
    background: _tealSoft,
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return 'No expiry';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

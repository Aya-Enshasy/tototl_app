import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../controllers/pilot_license_controller.dart';
import '../../models/pilot_license_model.dart';
import '../../services/pilot_license_service.dart';
import 'pilot_license_details_screen.dart';
import 'pilot_license_form_screen.dart';
import 'pilot_licenses_screen.dart';

const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF63748A);
const Color _muted2 = Color(0xFF98A6B4);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE5EAF0);
const Color _danger = Color(0xFFE45252);
const Color _warning = Color(0xFFE99A23);

class ProfileLicensesSection extends StatefulWidget {
  const ProfileLicensesSection({super.key});

  @override
  State<ProfileLicensesSection> createState() =>
      _ProfileLicensesSectionState();
}

class _ProfileLicensesSectionState extends State<ProfileLicensesSection>
    with SingleTickerProviderStateMixin {
  late final PilotLicenseController _controller;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _controller = PilotLicenseController(
      PilotLicenseService(ApiClient()),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();

    _controller.loadLicenses();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _openAll() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PilotLicensesScreen(),
      ),
    );

    if (!mounted) return;
    await _controller.loadLicenses();
  }

  Future<void> _openAdd() async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PilotLicenseFormScreen(),
      ),
    );

    if (changed == true && mounted) {
      await _controller.loadLicenses();
    }
  }

  Future<void> _openDetails(PilotLicenseModel license) async {
    if (license.id <= 0) return;

    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PilotLicenseDetailsScreen(
          licenseId: license.id,
          initialLicense: license,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _controller.loadLicenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final licenses = _controller.licenses;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Same header sizing pattern used by ProfileDronesSection:
              // Expanded title + compact actions on the right.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Pilot Licenses',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  _AddButton(onTap: _openAdd),

                  const SizedBox(width: 8),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openAll,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              licenses.isNotEmpty
                                  ? 'View all (${licenses.length})'
                                  : 'View all',
                              style: const TextStyle(
                                color: _tealDark,
                                fontSize: 11.5,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _tealDark,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (_controller.isLoading && licenses.isEmpty)
                _LicensesSkeleton(controller: _shimmerController)
              else if (_controller.errorMessage != null && licenses.isEmpty)
                _SectionError(
                  message: _controller.errorMessage!,
                  onRetry: _controller.loadLicenses,
                )
              else if (licenses.isEmpty)
                  _EmptyLicenses(onAdd: _openAdd)
                else
                  _LicensesGrid(
                    licenses: licenses.take(3).toList(),
                    onTap: _openDetails,
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tealSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _teal.withOpacity(0.10),
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: _tealDark,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _LicensesGrid extends StatelessWidget {
  const _LicensesGrid({
    required this.licenses,
    required this.onTap,
  });

  final List<PilotLicenseModel> licenses;
  final ValueChanged<PilotLicenseModel> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = licenses.length.clamp(1, 3);
        const gap = 8.0;

        // One license = full width.
        // Two licenses = 50/50.
        // Three licenses = three equal cards.
        // This is the key fix for the tiny card + huge empty space problem.
        final cardWidth =
            (constraints.maxWidth - (gap * (count - 1))) / count;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            count,
                (index) {
              final license = licenses[index];

              return Padding(
                padding: EdgeInsets.only(
                  right: index == count - 1 ? 0 : gap,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: _LicenseCard(
                    license: license,
                    onTap: () => onTap(license),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({
    required this.license,
    required this.onTap,
  });

  final PilotLicenseModel license;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _licenseStatus(license);
    final type = _displayType(license.licenseType);
    final authority = _displayAuthority(license.issuingAuthority);
    final number = license.licenseNumber.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 135;
        final veryCompact = constraints.maxWidth < 112;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: compact ? 126 : 118,
              padding: EdgeInsets.fromLTRB(
                compact ? 8 : 10,
                9,
                compact ? 7 : 9,
                8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CredentialPreview(
                        license: license,
                        compact: compact,
                      ),
                      SizedBox(width: veryCompact ? 6 : 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _ink,
                                fontSize: veryCompact
                                    ? 10.0
                                    : compact
                                    ? 10.8
                                    : 12.8,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              authority,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _muted,
                                fontSize: veryCompact ? 8.2 : 9.2,
                                height: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!compact && number.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                number,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted2,
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _StatusPill(
                            status: status,
                            compact: compact,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: compact ? 27 : 29,
                        height: compact ? 27 : 29,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FBFD),
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: _tealDark,
                          size: compact ? 17 : 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CredentialPreview extends StatelessWidget {
  const _CredentialPreview({
    required this.license,
    required this.compact,
  });

  final PilotLicenseModel license;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final authority = _shortAuthority(license.issuingAuthority);
    final width = compact ? 39.0 : 44.0;
    final height = compact ? 49.0 : 54.0;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE9FAFB),
            Color(0xFFD8F3F5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withOpacity(0.13)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.62),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: 3,
            right: 3,
            top: 5,
            child: Text(
              authority,
              maxLines: 1,
              overflow: TextOverflow.fade,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _tealDark,
                fontSize: compact ? 5.8 : 6.4,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.15,
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            top: compact ? 18 : 20,
            child: const Column(
              children: [
                _DocumentLine(widthFactor: 1),
                SizedBox(height: 3),
                _DocumentLine(widthFactor: 0.75),
                SizedBox(height: 3),
                _DocumentLine(widthFactor: 0.90),
              ],
            ),
          ),
          Positioned(
            right: 3,
            bottom: 3,
            child: Icon(
              Icons.verified_user_outlined,
              size: compact ? 9 : 10,
              color: _tealDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentLine extends StatelessWidget {
  const _DocumentLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 1.7,
          decoration: BoxDecoration(
            color: _tealDark.withOpacity(0.34),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.compact,
  });

  final _LicenseStatusData status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 25 : 27,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            color: status.color,
            size: compact ? 10 : 11,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.color,
                fontSize: compact ? 7.6 : 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _tealSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: _tealDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No licenses added yet',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add your professional pilot credentials.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _tealDark,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onAdd,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _danger.withOpacity(0.14)),
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
  const _LicensesSkeleton({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const count = 3;
            const gap = 8.0;
            final cardWidth = (constraints.maxWidth - gap * 2) / 3;

            return Row(
              children: List.generate(
                count,
                    (index) => Padding(
                  padding: EdgeInsets.only(
                    right: index == count - 1 ? 0 : gap,
                  ),
                  child: SizedBox(
                    width: cardWidth,
                    child: _SkeletonCard(controller: controller),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    Widget glow({required double height, double? width, double radius = 8}) {
      final t = controller.value;

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment(-1.8 + (3.6 * t), 0),
            end: Alignment(-0.8 + (3.6 * t), 0),
            colors: const [
              Color(0xFFEEF3F6),
              Color(0xFFF9FBFC),
              Color(0xFFE8EFF3),
              Color(0xFFF9FBFC),
              Color(0xFFEEF3F6),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 126,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              glow(height: 49, width: 39, radius: 12),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    glow(height: 9, radius: 5),
                    const SizedBox(height: 6),
                    glow(height: 7, width: 44, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: glow(height: 25, radius: 15)),
              const SizedBox(width: 5),
              glow(height: 27, width: 27, radius: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _LicenseStatusData {
  const _LicenseStatusData({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;
}

_LicenseStatusData _licenseStatus(PilotLicenseModel license) {
  if (license.isExpired) {
    return const _LicenseStatusData(
      label: 'Expired',
      color: _danger,
      background: Color(0xFFFFEEEE),
      icon: Icons.error_outline_rounded,
    );
  }

  if (license.isExpiringSoon) {
    return const _LicenseStatusData(
      label: 'Expiring',
      color: _warning,
      background: Color(0xFFFFF5E6),
      icon: Icons.schedule_rounded,
    );
  }

  return const _LicenseStatusData(
    label: 'Valid',
    color: Color(0xFF12966F),
    background: Color(0xFFEAF8F3),
    icon: Icons.check_circle_rounded,
  );
}

String _displayType(String raw) {
  final value = _pretty(raw);
  return value.isEmpty ? 'Pilot License' : value;
}

String _displayAuthority(String raw) {
  final value = _pretty(raw);
  return value.isEmpty ? 'Authority not specified' : value;
}

String _shortAuthority(String raw) {
  final clean = raw.trim();
  if (clean.isEmpty) return 'LIC';

  final normalized = clean.replaceAll('_', ' ').trim();
  final words = normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.length == 1) {
    final word = words.first.toUpperCase();
    return word.length <= 5 ? word : word.substring(0, 5);
  }

  final initials = words.map((word) => word[0].toUpperCase()).join();
  return initials.length <= 5 ? initials : initials.substring(0, 5);
}

String _pretty(String value) {
  final clean = value.trim().replaceAll('_', ' ');
  if (clean.isEmpty) return '';

  return clean
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
    if (part.length <= 3 && part == part.toUpperCase()) {
      return part;
    }
    return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
  })
      .join(' ');
}

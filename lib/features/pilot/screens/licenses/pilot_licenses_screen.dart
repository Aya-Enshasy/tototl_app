import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../controllers/pilot_license_controller.dart';
import '../../models/pilot_license_model.dart';
import '../../services/pilot_license_service.dart';
import 'pilot_license_details_screen.dart';
import 'pilot_license_form_screen.dart';

const Color _page = Color(0xFFF7F9FB);
const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF52657D);
const Color _muted2 = Color(0xFF8CA0B8);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE7ECF1);
const Color _danger = Color(0xFFE45252);
const Color _warning = Color(0xFFE99A23);

class PilotLicensesScreen extends StatefulWidget {
  const PilotLicensesScreen({super.key});

  @override
  State<PilotLicensesScreen> createState() => _PilotLicensesScreenState();
}

class _PilotLicensesScreenState extends State<PilotLicensesScreen> {
  late final PilotLicenseController _controller;
  bool _changed = false;

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

  Future<void> _add() async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PilotLicenseFormScreen(),
      ),
    );

    if (changed == true) {
      _changed = true;
      await _controller.loadLicenses();
    }
  }

  Future<void> _details(PilotLicenseModel license) async {
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
      _changed = true;
      await _controller.loadLicenses();
    }
  }

  Future<void> _edit(PilotLicenseModel license) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PilotLicenseFormScreen(
          existingLicense: license,
        ),
      ),
    );

    if (changed == true) {
      _changed = true;
      await _controller.loadLicenses();
    }
  }

  Future<void> _delete(PilotLicenseModel license) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: _danger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Delete this license?',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'This will permanently remove ${license.licenseType.isEmpty ? 'this credential' : license.licenseType} from your profile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: const BorderSide(color: _border),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || license.id <= 0) return;

    final deleted = await _controller.deleteLicense(license.id);

    if (!mounted) return;

    if (deleted) {
      _changed = true;
      HapticFeedback.mediumImpact();
      _showSnack('License deleted.');
    } else {
      _showSnack(
        _controller.errorMessage ?? 'Unable to delete the license.',
        error: true,
      );
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? _danger : _ink,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Text(message),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_changed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _page,
        appBar: AppBar(
          backgroundColor: _page,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_changed),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _ink,
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilot Licenses',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Manage your professional credentials',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: _tealDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final licenses = _controller.licenses;

            return RefreshIndicator(
              color: _teal,
              onRefresh: _controller.loadLicenses,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                    sliver: SliverToBoxAdapter(
                      child: _OverviewCard(licenses: licenses),
                    ),
                  ),
                  if (_controller.isLoading && licenses.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      sliver: SliverList.builder(
                        itemCount: 4,
                        itemBuilder: (_, __) => Container(
                          height: 176,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    )
                  else if (_controller.errorMessage != null && licenses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StateMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load licenses',
                        message: _controller.errorMessage!,
                        buttonLabel: 'Try Again',
                        onPressed: _controller.loadLicenses,
                      ),
                    )
                  else if (licenses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StateMessage(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Build your credentials',
                        message:
                            'Add your first pilot license or certification and keep your profile ready for opportunities.',
                        buttonLabel: 'Add License',
                        onPressed: _add,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                      sliver: SliverList.builder(
                        itemCount: licenses.length,
                        itemBuilder: (context, index) {
                          final license = licenses[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LicenseCard(
                              license: license,
                              onView: () => _details(license),
                              onEdit: () => _edit(license),
                              onDelete: () => _delete(license),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.licenses});

  final List<PilotLicenseModel> licenses;

  @override
  Widget build(BuildContext context) {
    final valid = licenses.where((item) => !item.isExpired).length;
    final expiring = licenses.where((item) => item.isExpiringSoon).length;
    final expired = licenses.where((item) => item.isExpired).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF08223F),
            Color(0xFF0A5C70),
            Color(0xFF0FA6B4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _tealDark.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Credential Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'TOTOTL',
                style: TextStyle(
                  color: Color(0xFFBCEEF2),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Keep every license current and ready for company review.',
            style: TextStyle(
              color: Color(0xFFD8F3F5),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OverviewStat(label: 'Total', value: '${licenses.length}'),
              _OverviewDivider(),
              _OverviewStat(label: 'Valid', value: '$valid'),
              _OverviewDivider(),
              _OverviewStat(label: 'Expiring', value: '$expiring'),
              _OverviewDivider(),
              _OverviewStat(label: 'Expired', value: '$expired'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCFECEF),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 31,
      color: Colors.white.withOpacity(0.18),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({
    required this.license,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final PilotLicenseModel license;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = _status(license);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onView,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF1FFFF),
                          Color(0xFFDDF6F8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: _teal.withOpacity(0.12),
                      ),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: _tealDark,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 13),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.25,
                                ),
                              ),
                            ),
                            _StatusPill(data: status),
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniInfo(
                                label: 'License No.',
                                value: license.licenseNumber.isEmpty
                                    ? '—'
                                    : license.licenseNumber,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: _border,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: _MiniInfo(
                                  label: 'Expires',
                                  value: _formatDate(license.expiresAt),
                                  valueColor: status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _muted2,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    onTap: onView,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    onTap: onDelete,
                    danger: true,
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

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
    this.valueColor = _ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted2,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? _danger : _tealDark;
    final background = danger
        ? const Color(0xFFFFF4F4)
        : const Color(0xFFF5FBFC);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _tealSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _tealDark, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: _tealDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(150, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusData {
  const _StatusData({
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.data});

  final _StatusData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: data.color, size: 12),
          const SizedBox(width: 4),
          Text(
            data.label,
            style: TextStyle(
              color: data.color,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

_StatusData _status(PilotLicenseModel license) {
  if (license.isExpired) {
    return const _StatusData(
      label: 'Expired',
      color: _danger,
      background: Color(0xFFFFEEEE),
      icon: Icons.error_outline_rounded,
    );
  }

  if (license.isExpiringSoon) {
    return const _StatusData(
      label: 'Expiring Soon',
      color: _warning,
      background: Color(0xFFFFF5E6),
      icon: Icons.schedule_rounded,
    );
  }

  return const _StatusData(
    label: 'Valid',
    color: _tealDark,
    background: _tealSoft,
    icon: Icons.check_circle_outline_rounded,
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not specified';

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

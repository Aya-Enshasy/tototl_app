import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../controllers/pilot_license_controller.dart';
import '../../models/pilot_license_model.dart';
import '../../services/pilot_license_service.dart';
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

class PilotLicenseDetailsScreen extends StatefulWidget {
  const PilotLicenseDetailsScreen({
    super.key,
    required this.licenseId,
    this.initialLicense,
  });

  final int licenseId;
  final PilotLicenseModel? initialLicense;

  @override
  State<PilotLicenseDetailsScreen> createState() =>
      _PilotLicenseDetailsScreenState();
}

class _PilotLicenseDetailsScreenState
    extends State<PilotLicenseDetailsScreen> {
  late final PilotLicenseController _controller;
  PilotLicenseModel? _license;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();

    _controller = PilotLicenseController(
      PilotLicenseService(ApiClient()),
    );

    _license = widget.initialLicense;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _license == null;
    });

    final fresh = await _controller.loadLicense(widget.licenseId);

    if (!mounted) return;

    setState(() {
      if (fresh != null) {
        _license = fresh;
      }
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final license = _license;
    if (license == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PilotLicenseFormScreen(
          existingLicense: license,
        ),
      ),
    );

    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _delete() async {
    final license = _license;
    if (license == null) return;

    HapticFeedback.selectionClick();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete license?',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'This will permanently remove ${license.licenseType.isEmpty ? 'this credential' : license.licenseType} from your profile.',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final deleted = await _controller.deleteLicense(widget.licenseId);

    if (!mounted) return;

    if (deleted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text(
          'License Details',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _license == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 11, 18, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: _border),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _controller.isDeleting ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _danger,
                          side: BorderSide(
                            color: _danger.withOpacity(0.25),
                          ),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _controller.isDeleting ? null : _edit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _tealDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        label: const Text(
                          'Edit License',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading && _license == null) {
      return const _DetailsSkeleton();
    }

    final license = _license;

    if (license == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: _tealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: _tealDark,
                  size: 30,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'License unavailable',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _controller.errorMessage ??
                    'We could not load this license.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _load,
                style: FilledButton.styleFrom(
                  backgroundColor: _tealDark,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _status(license);

    return RefreshIndicator(
      color: _teal,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _HeroCredentialCard(
            license: license,
            status: status,
          ),
          const SizedBox(height: 14),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'License Type',
                value: _value(license.licenseType),
              ),
              const _InfoDivider(),
              _InfoRow(
                icon: Icons.numbers_rounded,
                label: 'License Number',
                value: _value(license.licenseNumber),
              ),
              const _InfoDivider(),
              _InfoRow(
                icon: Icons.account_balance_outlined,
                label: 'Issuing Authority',
                value: _value(license.issuingAuthority),
              ),
              const _InfoDivider(),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Expiration Date',
                value: _formatDate(license.expiresAt),
                valueColor: status.color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Documents',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          _DocumentCard(
            title: 'License Document',
            document: license.licenseDocument,
            requiredDocument: true,
          ),
          const SizedBox(height: 9),
          _DocumentCard(
            title: 'Permit / Insurance Document',
            document: license.permitOrInsuranceDocument,
            requiredDocument: false,
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              minHeight: 2,
              color: _teal,
              backgroundColor: _tealSoft,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCredentialCard extends StatelessWidget {
  const _HeroCredentialCard({
    required this.license,
    required this.status,
  });

  final PilotLicenseModel license;
  final _StatusData status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF08223F),
            Color(0xFF0A6172),
            Color(0xFF0FA6B4),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _tealDark.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
              ),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, color: status.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  license.licenseType.isEmpty
                      ? 'Pilot Credential'
                      : license.licenseType,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  license.issuingAuthority.isEmpty
                      ? 'Issuing authority not specified'
                      : license.issuingAuthority,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD2EDF0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = _ink,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: _tealSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _tealDark, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: _border,
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.document,
    required this.requiredDocument,
  });

  final String title;
  final PilotLicenseDocument? document;
  final bool requiredDocument;

  @override
  Widget build(BuildContext context) {
    final available = document?.hasValue == true;
    final name = document?.name?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: available ? _tealSoft : const Color(0xFFF3F6F8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              available
                  ? Icons.description_outlined
                  : Icons.insert_drive_file_outlined,
              color: available ? _tealDark : _muted2,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  available
                      ? (name?.isNotEmpty == true ? name! : 'Document attached')
                      : (requiredDocument
                          ? 'Document data not returned by the API.'
                          : 'No optional document attached.'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: available ? _tealSoft : const Color(0xFFF3F6F8),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              available ? 'Attached' : 'Not available',
              style: TextStyle(
                color: available ? _tealDark : _muted2,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Container(
          height: 145,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0F3),
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 245,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
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

String _value(String value) {
  final clean = value.trim();
  return clean.isEmpty ? 'Not specified' : clean;
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

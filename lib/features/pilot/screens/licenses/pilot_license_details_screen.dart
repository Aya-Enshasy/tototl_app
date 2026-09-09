import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/network/api_client.dart';
import '../../controllers/pilot_license_controller.dart';
import '../../models/pilot_license_model.dart';
import '../../services/pilot_license_service.dart';
import 'pilot_license_form_screen.dart';

const Color _page = Color(0xFFF6F9FC);
const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF5A6E86);
const Color _muted2 = Color(0xFF90A2B8);
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
  String? _openingDocumentKey;

  @override
  void initState() {
    super.initState();
    _controller = PilotLicenseController(PilotLicenseService(ApiClient()));
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
        builder: (_) => PilotLicenseFormScreen(existingLicense: license),
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete license?',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'This will permanently remove ${license.licenseType.isEmpty ? 'this credential' : license.licenseType} from your profile.',
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
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

  Future<void> _openDocument(PilotLicenseDocument? document) async {
    if (document == null || !document.hasValue) {
      _showSnack('This document is not available yet.', error: true);
      return;
    }

    if (_openingDocumentKey != null) return;

    final mediaId = document.id ?? 0;
    final downloadUrl = document.bestDownloadUrl;
    final fileName = document.name?.trim().isNotEmpty == true
        ? document.name!.trim()
        : (mediaId > 0 ? 'document_$mediaId' : 'document');

    if (downloadUrl.isEmpty && mediaId <= 0) {
      _showSnack('Document download link is missing.', error: true);
      return;
    }

    final key = mediaId > 0
        ? 'media:$mediaId'
        : 'url:${downloadUrl.hashCode}';

    HapticFeedback.selectionClick();

    setState(() {
      _openingDocumentKey = key;
    });

    final localPath = await _controller.downloadDocument(
      documentKey: key,
      mediaId: mediaId,
      downloadUrl: downloadUrl,
      fileName: fileName,
      mimeType: document.mimeType,
    );

    if (!mounted) return;

    setState(() {
      _openingDocumentKey = null;
    });

    if (localPath == null || localPath.trim().isEmpty) {
      _showSnack(
        _controller.errorMessage ?? 'Unable to open this document.',
        error: true,
      );
      return;
    }

    try {
      await OpenFilex.open(localPath);
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        'The file was downloaded, but no app could open it.',
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
          borderRadius: BorderRadius.circular(13),
        ),
        content: Text(message),
      ),
    );
  }

  bool _isOpening(PilotLicenseDocument? document) {
    if (document == null) return false;

    final mediaId = document.id ?? 0;
    final key = mediaId > 0
        ? 'media:$mediaId'
        : 'url:${document.bestDownloadUrl.hashCode}';

    return _openingDocumentKey == key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => Navigator.of(context).pop(_changed),
              onEdit: _license == null || _controller.isDeleting ? null : _edit,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _license == null
          ? null
          : SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: _border)),
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
                    side: BorderSide(color: _danger.withOpacity(0.20)),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
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
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 17),
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
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: _tealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: _tealDark,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'License unavailable',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _controller.errorMessage ?? 'We could not load this license.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11.5),
              ),
              const SizedBox(height: 11),
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
        children: [
          _HeroCredentialCard(license: license, status: status),
          const SizedBox(height: 11),
          _SummaryGrid(license: license, status: status),
          const SizedBox(height: 11),
          _SectionTitle(
            icon: Icons.info_outline_rounded,
            title: 'Credential Information',
            subtitle: 'Core licensing identity and issuing data',
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 11),
          const _SectionTitle(
            icon: Icons.folder_copy_outlined,
            title: 'Documents',
            subtitle: 'Attached files related to this pilot license',
          ),
          const SizedBox(height: 8),
          _DocumentCard(
            title: 'License Document',
            document: license.licenseDocument,
            requiredDocument: true,
            opening: _isOpening(license.licenseDocument),
            onTap: () => _openDocument(license.licenseDocument),
          ),
          const SizedBox(height: 8),
          _DocumentCard(
            title: 'Permit / Insurance Document',
            document: license.permitOrInsuranceDocument,
            requiredDocument: false,
            opening: _isOpening(license.permitOrInsuranceDocument),
            onTap: () => _openDocument(license.permitOrInsuranceDocument),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onEdit});

  final VoidCallback onBack;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 7),
      child: Row(
        children: [
          _RoundActionButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'License Details',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'View and manage your pilot credential',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RoundActionButton(
            icon: Icons.edit_outlined,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: _ink.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 19, color: _ink),
        ),
      ),
    );
  }
}

class _HeroCredentialCard extends StatelessWidget {
  const _HeroCredentialCard({required this.license, required this.status});

  final PilotLicenseModel license;
  final _StatusData status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071D3A),
            Color(0xFF0B4E67),
            Color(0xFF12A2B3),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _tealDark.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, color: status.color, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 8.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  license.licenseType.isEmpty ? 'Pilot Credential' : license.licenseType,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
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
                    color: Color(0xFFD6EFF2),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.numbers_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _value(license.licenseNumber),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.license, required this.status});

  final PilotLicenseModel license;
  final _StatusData status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.workspace_premium_rounded,
            label: 'Credential',
            value: license.licenseType.isEmpty ? 'Pilot License' : license.licenseType,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.account_balance_outlined,
            label: 'Authority',
            value: _value(license.issuingAuthority),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: status.icon,
            label: 'Expires',
            value: _formatDate(license.expiresAt),
            valueColor: status.color,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: _tealSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _tealDark, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _tealSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _tealDark, size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _tealSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _tealDark, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 10.8,
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
                fontSize: 11.8,
                fontWeight: FontWeight.w800,
                height: 1.15,
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
    required this.opening,
    required this.onTap,
  });

  final String title;
  final PilotLicenseDocument? document;
  final bool requiredDocument;
  final bool opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = document?.hasValue == true;
    final name = document?.name?.trim();
    final mimeType = document?.mimeType.trim().toLowerCase() ?? '';
    final isPdf = mimeType == 'application/pdf' ||
        (name?.toLowerCase().endsWith('.pdf') == true);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: available && !opening ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: opening ? _teal.withOpacity(0.35) : _border,
            ),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.02),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: available ? _tealSoft : const Color(0xFFF3F6F8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  available
                      ? (isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined)
                      : Icons.insert_drive_file_outlined,
                  color: available ? _tealDark : _muted2,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      available
                          ? (name?.isNotEmpty == true
                          ? name!
                          : 'Document attached')
                          : (requiredDocument
                          ? 'Document data not returned by the API.'
                          : 'No optional document attached.'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9.8,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: !available
                    ? Container(
                  key: const ValueKey('missing'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Not available',
                    style: TextStyle(
                      color: _muted2,
                      fontSize: 8.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
                    : Container(
                  key: ValueKey(opening),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _tealSoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        opening
                            ? Icons.hourglass_top_rounded
                            : Icons.open_in_new_rounded,
                        color: _tealDark,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opening ? 'Opening' : 'Open',
                        style: const TextStyle(
                          color: _tealDark,
                          fontSize: 8.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block({required double height, double? width, double radius = 20}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F4),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: [
        block(height: 140, radius: 22),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(child: block(height: 92, radius: 17)),
            const SizedBox(width: 10),
            Expanded(child: block(height: 92, radius: 17)),
            const SizedBox(width: 10),
            Expanded(child: block(height: 92, radius: 17)),
          ],
        ),
        const SizedBox(height: 11),
        block(height: 34, width: 190, radius: 12),
        const SizedBox(height: 8),
        block(height: 200, radius: 20),
        const SizedBox(height: 11),
        block(height: 34, width: 140, radius: 12),
        const SizedBox(height: 8),
        block(height: 76, radius: 18),
        const SizedBox(height: 8),
        block(height: 76, radius: 18),
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}


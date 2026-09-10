import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../controllers/pilot_license_controller.dart';
import '../../models/pilot_license_form_request.dart';
import '../../models/pilot_license_model.dart';
import '../../services/pilot_license_service.dart';
import 'pilot_license_document_viewer_screen.dart';

const Color _page = Color(0xFFF7F9FB);
const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF52657D);
const Color _muted2 = Color(0xFF8CA0B8);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE7ECF1);
const Color _danger = Color(0xFFE45252);

class PilotLicenseFormScreen extends StatefulWidget {
  const PilotLicenseFormScreen({
    super.key,
    this.existingLicense,
  });

  final PilotLicenseModel? existingLicense;

  bool get isEditing => existingLicense != null;

  @override
  State<PilotLicenseFormScreen> createState() =>
      _PilotLicenseFormScreenState();
}

class _PilotLicenseFormScreenState extends State<PilotLicenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _typeController;
  late final TextEditingController _numberController;
  late final TextEditingController _authorityController;
  late final PilotLicenseController _controller;

  DateTime? _expiresAt;
  PlatformFile? _licenseDocument;
  PlatformFile? _permitDocument;
  String? _openingDocumentKey;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingLicense;

    _typeController = TextEditingController(
      text: existing?.licenseType ?? '',
    );
    _numberController = TextEditingController(
      text: existing?.licenseNumber ?? '',
    );
    _authorityController = TextEditingController(
      text: existing?.issuingAuthority ?? '',
    );
    _expiresAt = existing?.expiresAt;

    _controller = PilotLicenseController(
      PilotLicenseService(ApiClient()),
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _numberController.dispose();
    _authorityController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    HapticFeedback.selectionClick();

    final now = DateTime.now();
    final initial = _expiresAt ?? DateTime(now.year + 1, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 30),
      helpText: 'Select expiration date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _expiresAt = picked;
    });
  }

  Future<void> _pickDocument({required bool primary}) async {
    HapticFeedback.selectionClick();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.single;
    final path = file.path?.trim() ?? '';

    if (path.isEmpty) {
      _showSnack('Unable to access the selected file.', error: true);
      return;
    }

    final localFile = File(path);
    if (!await localFile.exists()) {
      if (!mounted) return;
      _showSnack('Selected file could not be found.', error: true);
      return;
    }

    final bytes = await localFile.length();
    const maxBytes = 10 * 1024 * 1024;

    if (bytes > maxBytes) {
      if (!mounted) return;
      _showSnack('Document must be 10 MB or smaller.', error: true);
      return;
    }

    setState(() {
      if (primary) {
        _licenseDocument = file;
      } else {
        _permitDocument = file;
      }
    });
  }

  Future<void> _openDocument({
    required String key,
    required PlatformFile? selectedFile,
    required PilotLicenseDocument? existingDocument,
  }) async {
    if (_openingDocumentKey != null) return;

    HapticFeedback.selectionClick();

    setState(() {
      _openingDocumentKey = key;
    });

    try {
      final selectedPath = selectedFile?.path?.trim() ?? '';

      if (selectedPath.isNotEmpty) {
        final file = File(selectedPath);

        if (!await file.exists()) {
          if (!mounted) return;
          _showSnack('Selected file could not be found.', error: true);
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PilotLicenseDocumentViewerScreen(
              filePath: selectedPath,
              fileName: selectedFile?.name ?? file.uri.pathSegments.last,
              mimeType: _mimeFromFileName(
                selectedFile?.name ?? selectedPath,
              ),
            ),
          ),
        );
        return;
      }

      final document = existingDocument;

      if (document == null || !document.hasValue) {
        if (!mounted) return;
        _showSnack('This document is not available yet.', error: true);
        return;
      }

      final mediaId = document.id ?? 0;
      final downloadUrl = document.bestDownloadUrl;
      final fileName = document.name?.trim().isNotEmpty == true
          ? document.name!.trim()
          : (mediaId > 0 ? 'document_$mediaId' : 'document');

      final localPath = await _controller.downloadDocument(
        documentKey: key,
        mediaId: mediaId,
        downloadUrl: downloadUrl,
        fileName: fileName,
        mimeType: document.mimeType,
      );

      if (!mounted) return;

      if (localPath == null || localPath.trim().isEmpty) {
        _showSnack(
          _controller.errorMessage ?? 'Unable to open this document.',
          error: true,
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PilotLicenseDocumentViewerScreen(
            filePath: localPath,
            fileName: fileName,
            mimeType: document.mimeType,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Unable to open this document.', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _openingDocumentKey = null;
        });
      }
    }
  }

  String _mimeFromFileName(String value) {
    final lower = value.trim().toLowerCase();

    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';

    return '';
  }

  Future<void> _submit() async {
    if (_controller.isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_expiresAt == null) {
      _showSnack('Please select an expiration date.', error: true);
      return;
    }

    if (!widget.isEditing && _licenseDocument == null) {
      _showSnack('Please upload the license document.', error: true);
      return;
    }

    final request = PilotLicenseFormRequest(
      licenseType: _typeController.text,
      licenseNumber: _numberController.text,
      issuingAuthority: _authorityController.text,
      expiresAt: _expiresAt!,
      licenseDocumentPath: _licenseDocument?.path,
      permitOrInsuranceDocumentPath: _permitDocument?.path,
    );

    final success = widget.isEditing
        ? await _controller.updateLicense(
      widget.existingLicense!.id,
      request,
    )
        : await _controller.createLicense(request);

    if (!mounted) return;

    if (!success) {
      _showSnack(
        _controller.errorMessage ??
            (widget.isEditing
                ? 'Unable to update the license.'
                : 'Unable to add the license.'),
        error: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
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
    final existing = widget.existingLicense;

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
          color: _ink,
        ),
        title: Text(
          widget.isEditing ? 'Edit License' : 'Add License',
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IntroCard(isEditing: widget.isEditing),
                          const SizedBox(height: 16),
                          const _SectionTitle(
                            icon: Icons.badge_outlined,
                            title: 'License Information',
                            subtitle:
                            'Use the exact details printed on the credential.',
                          ),
                          const SizedBox(height: 10),
                          _FormCard(
                            children: [
                              _PremiumTextField(
                                controller: _typeController,
                                label: 'License Type',
                                hint: 'e.g. FAA Part 107',
                                icon: Icons.workspace_premium_outlined,
                                maxLength: 60,
                                validator: (value) => _required(
                                  value,
                                  'License type is required.',
                                ),
                              ),
                              const SizedBox(height: 14),
                              _PremiumTextField(
                                controller: _numberController,
                                label: 'License Number',
                                hint: 'Enter license number',
                                icon: Icons.numbers_rounded,
                                maxLength: 255,
                                validator: (value) => _required(
                                  value,
                                  'License number is required.',
                                ),
                              ),
                              const SizedBox(height: 14),
                              _PremiumTextField(
                                controller: _authorityController,
                                label: 'Issuing Authority',
                                hint: 'e.g. Federal Aviation Administration',
                                icon: Icons.account_balance_outlined,
                                maxLength: 60,
                                validator: (value) => _required(
                                  value,
                                  'Issuing authority is required.',
                                ),
                              ),
                              const SizedBox(height: 14),
                              _DateField(
                                value: _expiresAt,
                                onTap: _pickExpiry,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _SectionTitle(
                            icon: Icons.attach_file_rounded,
                            title: 'Documents',
                            subtitle:
                            'PDF or image files. Maximum 10 MB per document.',
                          ),
                          const SizedBox(height: 10),
                          _DocumentPickerCard(
                            title: 'License Document',
                            subtitle: widget.isEditing &&
                                existing?.licenseDocument != null
                                ? 'Current document stays unless you replace it.'
                                : 'Required',
                            selectedFile: _licenseDocument,
                            existingName: existing?.licenseDocument?.name,
                            requiredDocument: true,
                            opening: _openingDocumentKey == 'license_document',
                            onOpen: (_licenseDocument != null ||
                                existing?.licenseDocument?.hasValue == true)
                                ? () => _openDocument(
                              key: 'license_document',
                              selectedFile: _licenseDocument,
                              existingDocument: existing?.licenseDocument,
                            )
                                : null,
                            onPick: () => _pickDocument(primary: true),
                            onClear: _licenseDocument == null
                                ? null
                                : () {
                              setState(() {
                                _licenseDocument = null;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _DocumentPickerCard(
                            title: 'Permit / Insurance Document',
                            subtitle: 'Optional supporting document',
                            selectedFile: _permitDocument,
                            existingName:
                            existing?.permitOrInsuranceDocument?.name,
                            requiredDocument: false,
                            opening: _openingDocumentKey ==
                                'permit_or_insurance_document',
                            onOpen: (_permitDocument != null ||
                                existing?.permitOrInsuranceDocument?.hasValue ==
                                    true)
                                ? () => _openDocument(
                              key: 'permit_or_insurance_document',
                              selectedFile: _permitDocument,
                              existingDocument:
                              existing?.permitOrInsuranceDocument,
                            )
                                : null,
                            onPick: () => _pickDocument(primary: false),
                            onClear: _permitDocument == null
                                ? null
                                : () {
                              setState(() {
                                _permitDocument = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _PreviewCard(
                            type: _typeController.text,
                            number: _numberController.text,
                            authority: _authorityController.text,
                            expiresAt: _expiresAt,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
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
                  child: FilledButton(
                    onPressed: _controller.isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _tealDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _tealDark.withOpacity(0.5),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: _controller.isSaving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isEditing
                              ? Icons.save_outlined
                              : Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEditing
                              ? 'Save Changes'
                              : 'Add License',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF08223F),
            Color(0xFF0A6374),
            Color(0xFF12A8B6),
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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Keep it current' : 'Build trust with credentials',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Update the official details or replace the attached documents.'
                      : 'Add a professional license that companies can review on your pilot profile.',
                  style: const TextStyle(
                    color: Color(0xFFD7F1F3),
                    fontSize: 10.5,
                    height: 1.35,
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
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: _tealSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _tealDark, size: 19),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 9.8,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.maxLength,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLength;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(
        color: _ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          color: _muted2,
          fontSize: 11.5,
        ),
        labelStyle: const TextStyle(
          color: _muted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: _tealDark, size: 20),
        filled: true,
        fillColor: const Color(0xFFFBFDFE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _teal, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _danger),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onTap,
  });

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Expiration Date',
          labelStyle: const TextStyle(
            color: _muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(
            Icons.calendar_month_outlined,
            color: _tealDark,
            size: 20,
          ),
          suffixIcon: const Icon(
            Icons.expand_more_rounded,
            color: _muted2,
          ),
          filled: true,
          fillColor: const Color(0xFFFBFDFE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _border),
          ),
        ),
        child: Text(
          value == null ? 'Select date' : _formatDate(value!),
          style: TextStyle(
            color: value == null ? _muted2 : _ink,
            fontSize: 13,
            fontWeight: value == null ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DocumentPickerCard extends StatelessWidget {
  const _DocumentPickerCard({
    required this.title,
    required this.subtitle,
    required this.selectedFile,
    required this.existingName,
    required this.requiredDocument,
    required this.opening,
    required this.onOpen,
    required this.onPick,
    required this.onClear,
  });

  final String title;
  final String subtitle;
  final PlatformFile? selectedFile;
  final String? existingName;
  final bool requiredDocument;
  final bool opening;
  final VoidCallback? onOpen;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final name = selectedFile?.name.trim().isNotEmpty == true
        ? selectedFile!.name
        : (existingName?.trim().isNotEmpty == true
        ? existingName!.trim()
        : null);

    final hasFile = name != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _tealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: _tealDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (requiredDocument)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(
                                color: _danger,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasFile)
            Container(
              padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _teal.withOpacity(0.12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _tealDark,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onOpen != null)
                    TextButton.icon(
                      onPressed: opening ? null : onOpen,
                      style: TextButton.styleFrom(
                        foregroundColor: _tealDark,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        opening
                            ? Icons.hourglass_top_rounded
                            : Icons.open_in_new_rounded,
                        size: 14,
                      ),
                      label: Text(
                        opening ? 'Opening' : 'Open',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (onClear != null)
                    IconButton(
                      onPressed: opening ? null : onClear,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _muted,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          if (hasFile) const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              foregroundColor: _tealDark,
              side: const BorderSide(color: _border),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(
              hasFile ? Icons.swap_horiz_rounded : Icons.upload_file_rounded,
              size: 18,
            ),
            label: Text(
              hasFile ? 'Replace Document' : 'Choose Document',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.type,
    required this.number,
    required this.authority,
    required this.expiresAt,
  });

  final String type;
  final String number;
  final String authority;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
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
            width: 54,
            height: 64,
            decoration: BoxDecoration(
              color: _tealSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: _tealDark,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROFILE PREVIEW',
                  style: TextStyle(
                    color: _tealDark,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type.trim().isEmpty ? 'License Type' : type.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  authority.trim().isEmpty
                      ? 'Issuing authority'
                      : authority.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${number.trim().isEmpty ? 'No number' : number.trim()}  •  ${expiresAt == null ? 'No expiry' : _formatDate(expiresAt!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
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

String? _required(String? value, String message) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

String _formatDate(DateTime date) {
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


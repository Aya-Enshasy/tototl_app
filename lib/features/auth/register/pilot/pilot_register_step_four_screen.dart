import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

enum _PilotDocumentType { license, permit }

class PilotRegisterStepFourScreen extends StatefulWidget {
  const PilotRegisterStepFourScreen({super.key});

  @override
  State<PilotRegisterStepFourScreen> createState() =>
      _PilotRegisterStepFourScreenState();
}

class _PilotRegisterStepFourScreenState
    extends State<PilotRegisterStepFourScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _licenseNumberController =
  TextEditingController();
  final TextEditingController _authorityController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  String? _selectedLicenseType;
  DateTime? _selectedExpiryDate;
  File? _licenseImage;
  File? _permitImage;
  _PilotDocumentType? _pickingDocument;
  bool _isSubmitting = false;
  bool _showLicenseUploadError = false;

  // Upload progress state per document
  final Map<_PilotDocumentType, double> _uploadProgress = {
    _PilotDocumentType.license: 0,
    _PilotDocumentType.permit: 0,
  };
  final Map<_PilotDocumentType, bool> _isUploading = {
    _PilotDocumentType.license: false,
    _PilotDocumentType.permit: false,
  };

  final ImagePicker _picker = ImagePicker();

  final List<String> _licenseTypes = const [
    'Commercial UAS Pilot',
    'Recreational Drone Pilot',
    'Inspection Pilot',
    'Aerial Photography Pilot',
  ];

  static const Color kPrimary = Color(0xFF1E56F0);
  static const Color kPrimarySoft = Color(0xFFEFF3FE);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);
  static const Color kHint = Color(0xFF94A3B8);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kSurfaceSoft = Color(0xFFF8FAFC);
  static const Color kDanger = Color(0xFFEF4444);
  static const Color kSuccess = Color(0xFF16A34A);

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _authorityController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  File? _documentFile(_PilotDocumentType document) {
    switch (document) {
      case _PilotDocumentType.license:
        return _licenseImage;
      case _PilotDocumentType.permit:
        return _permitImage;
    }
  }

  String _documentTitle(_PilotDocumentType document) {
    switch (document) {
      case _PilotDocumentType.license:
        return 'Pilot License Document';
      case _PilotDocumentType.permit:
        return 'Permit / Insurance Document';
    }
  }

  void _setDocumentFile(_PilotDocumentType document, File? file) {
    switch (document) {
      case _PilotDocumentType.license:
        _licenseImage = file;
        _showLicenseUploadError = false;
        break;
      case _PilotDocumentType.permit:
        _permitImage = file;
        break;
    }
  }

  // Simulates an upload progress bar (replace later with real upload call)
  Future<void> _simulateUpload(_PilotDocumentType document) async {
    setState(() {
      _isUploading[document] = true;
      _uploadProgress[document] = 0;
    });
    const steps = 12;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _uploadProgress[document] = i / steps);
    }
    if (!mounted) return;
    setState(() => _isUploading[document] = false);
  }

  Future<void> _pickDocumentImage(
      _PilotDocumentType document,
      ImageSource source,
      ) async {
    if (_pickingDocument != null) return;
    setState(() => _pickingDocument = document);

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (await file.exists() && mounted) {
        setState(() => _setDocumentFile(document, file));
        await _simulateUpload(document);
      }
    } on PlatformException catch (_) {
      if (mounted) {
        _showSnack('Unable to open the image picker. Check app permissions.');
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Unable to upload this image. Please try another photo.');
      }
    } finally {
      if (mounted) setState(() => _pickingDocument = null);
    }
  }

  // Allows picking a PDF (or image) file from device storage
  Future<void> _pickDocumentFile(_PilotDocumentType document) async {
    if (_pickingDocument != null) return;
    setState(() => _pickingDocument = document);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      if (await file.exists() && mounted) {
        setState(() => _setDocumentFile(document, file));
        await _simulateUpload(document);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Unable to upload this file. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _pickingDocument = null);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kTextDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showImageSourceActionSheet(_PilotDocumentType document) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final currentFile = _documentFile(document);
        return Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _documentTitle(document),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSheetOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocumentImage(document, ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose from Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocumentImage(document, ImageSource.gallery);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'Choose File (PDF)',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocumentFile(document);
                    },
                  ),
                  if (currentFile != null) ...[
                    const SizedBox(height: 10),
                    _buildSheetOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove Document',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _setDocumentFile(document, null));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? kDanger : kPrimary;
    return Material(
      color: kSurfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? color : kTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 15),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedExpiryDate = pickedDate;
        _expiryController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _openSelectSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...items.map((item) {
                    final isSelected = item == selected;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected ? kPrimarySoft : kSurfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSelected(item);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? kPrimary
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected ? kPrimary : kTextDark,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: kPrimary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    bool isFormValid = _formKey.currentState!.validate();

    if (_licenseImage == null) {
      setState(() => _showLicenseUploadError = true);
      isFormValid = false;
    }

    if (!isFormValid) {
      HapticFeedback.heavyImpact();
      if (_licenseImage == null) {
        _showSnack('Please upload your official pilot license photo.');
      }
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Display Registration Completed Dialog
    _showCompletionSuccessDialog();
  }

  void _showCompletionSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: kPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 48,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Registration Submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your pilot profile and certifications are under review. We will notify you once verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: kTextMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                Row(
                  children: [
                    _buildBackButton(),
                    const Spacer(),
                    _buildAnimatedStepIndicator(currentStep: 4),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 28),

                // Title & Subtitle
                const Text(
                  'Certifications &\nDocuments',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload your drone license and official permits for verification.',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // License Type Dropdown
                _buildSectionLabel('License Type'),
                const SizedBox(height: 8),
                _buildSelectField(
                  hintText: 'Select License Type',
                  icon: Icons.card_membership_rounded,
                  value: _selectedLicenseType,
                  items: _licenseTypes,
                  onChanged: (val) => setState(() => _selectedLicenseType = val),
                ),
                const SizedBox(height: 16),

                // License Number
                _buildSectionLabel('License / Certification Number'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _licenseNumberController,
                  hintText: 'e.g. C-129384910',
                  suffixIcon: const Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'License number is required' : null,
                ),
                const SizedBox(height: 16),

                // Issuing Authority
                _buildSectionLabel('Issuing Authority'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _authorityController,
                  hintText: 'e.g. GACA / FAA',
                  suffixIcon: const Icon(
                    Icons.account_balance_outlined,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Authority name is required' : null,
                ),
                const SizedBox(height: 16),

                // Expiration Date Picker
                _buildSectionLabel('License Expiration Date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectExpiryDate,
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: _expiryController,
                      hintText: 'Select Date (YYYY-MM-DD)',
                      suffixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: kHint,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Expiration date is required'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // License Document Upload Card (Required)
                _buildSectionLabel('Upload Pilot License (Required)'),
                const SizedBox(height: 8),
                _buildDocumentUploadCard(
                  documentType: _PilotDocumentType.license,
                  showError: _showLicenseUploadError,
                ),
                const SizedBox(height: 20),

                // Permit / Insurance Upload Card (Optional)
                _buildSectionLabel('Upload Permit or Insurance (Optional)'),
                const SizedBox(height: 8),
                _buildDocumentUploadCard(
                  documentType: _PilotDocumentType.permit,
                  showError: false,
                ),
                const SizedBox(height: 32),

                // Submit Button
                _buildPrimaryButton(
                  text: 'Complete Registration',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleSubmit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Custom Reusable UI Components
  // ---------------------------------------------------------------------

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: kTextDark,
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 13,
          color: kTextDark,
        ),
      ),
    );
  }

  Widget _buildAnimatedStepIndicator({required int currentStep}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == currentStep;
        final isPassed = stepNumber < currentStep;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              width: isActive ? 22 : 18,
              height: isActive ? 22 : 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isPassed ? kPrimary : Colors.white,
                border: Border.all(
                  color: isActive || isPassed ? kPrimary : kBorder,
                  width: isActive ? 0 : 1.2,
                ),
              ),
              child: Center(
                child: isPassed
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : kHint,
                  ),
                ),
              ),
            ),
            if (index < 3)
              Container(
                width: 26,
                height: 1.5,
                color: stepNumber < currentStep ? kPrimary : kBorder,
              ),
          ],
        );
      }),
    );
  }

  // ---------------------------------------------------------------------
  // NEW: Compact document upload card with thumbnail + progress bar
  // ---------------------------------------------------------------------
  Widget _buildDocumentUploadCard({
    required _PilotDocumentType documentType,
    required bool showError,
  }) {
    final file = _documentFile(documentType);
    final isPicking = _pickingDocument == documentType;
    final isUploading = _isUploading[documentType] ?? false;
    final progress = _uploadProgress[documentType] ?? 0;
    final isImage = file != null &&
        ['.jpg', '.jpeg', '.png']
            .any((ext) => file.path.toLowerCase().endsWith(ext));

    return GestureDetector(
      onTap: isUploading ? null : () => _showImageSourceActionSheet(documentType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: file != null ? kPrimarySoft.withOpacity(0.25) : kSurfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: showError
                ? kDanger
                : (file != null ? kPrimary.withOpacity(0.4) : kBorder),
            width: showError ? 1.4 : 0.8,
          ),
        ),
        child: (file == null && !isPicking)
            ? Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: showError ? kDanger.withOpacity(0.1) : kPrimarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 22,
                color: showError ? kDanger : kPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to upload document',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: showError ? kDanger : kTextDark,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'JPG, PNG or PDF · Max 10MB',
              style: TextStyle(fontSize: 11, color: kHint),
            ),
          ],
        )
            : Row(
          children: [
            Container(
              width: 46,
              height: 46,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder, width: 0.8),
              ),
              child: isPicking
                  ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimary,
                  ),
                ),
              )
                  : (isImage
                  ? Image.file(file!, fit: BoxFit.cover)
                  : const Icon(
                Icons.picture_as_pdf_rounded,
                color: kPrimary,
                size: 22,
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPicking
                        ? 'Preparing file…'
                        : file!.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isUploading)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: kBorder,
                        valueColor:
                        const AlwaysStoppedAnimation(kPrimary),
                      ),
                    )
                  else if (!isPicking)
                    Row(
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: kSuccess,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Uploaded',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: kSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!isPicking && !isUploading)
              IconButton(
                onPressed: () =>
                    _showImageSourceActionSheet(documentType),
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: kTextMuted,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 13.5,
        color: kTextDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: kHint,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(fontSize: 11, color: kDanger),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDanger, width: 1),
        ),
      ),
    );
  }

  Widget _buildSelectField({
    required String hintText,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return FormField<String>(
      initialValue: value,
      validator: (v) => value == null ? 'Selection is required' : null,
      builder: (state) {
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openSelectSheet(
            title: hintText,
            items: items,
            selected: value,
            onSelected: (val) {
              onChanged(val);
              state.didChange(val);
            },
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: state.hasError ? kDanger : kBorder,
                width: state.hasError ? 1 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: kHint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        value ?? hintText,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: value == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: value == null ? kHint : kTextDark,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: kHint,
                    ),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 28),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(fontSize: 11, color: kDanger),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null && !isLoading ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), kPrimary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
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
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
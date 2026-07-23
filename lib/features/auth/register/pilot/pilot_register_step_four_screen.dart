import 'dart:io';

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
  File? _licenseImage;
  File? _permitImage;
  _PilotDocumentType? _pickingDocument;
  bool _isSubmitting = false;
  bool _showLicenseUploadError = false;

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
        return 'Pilot License';
      case _PilotDocumentType.permit:
        return 'Permit / Insurance';
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

  void _showDocumentActionSheet(_PilotDocumentType document) {
    HapticFeedback.lightImpact();
    final title = _documentTitle(document);
    final hasImage = _documentFile(document) != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                      title,
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
                    label: 'Take a Photo',
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
                  if (hasImage) ...[
                    const SizedBox(height: 10),
                    _buildSheetOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove Photo',
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

  Future<void> _pickExpiryDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 20, now.month, now.day),
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

    if (picked != null) {
      _expiryController.text = DateFormat('dd / MM / yyyy').format(picked);
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

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (_selectedLicenseType == null) {
      _showSnack('Please complete all fields');
      return;
    }
    if (_licenseImage == null) {
      setState(() => _showLicenseUploadError = true);
      _showSnack('Please upload your pilot license');
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSnack('Registration details saved');
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
                const Text(
                  'Pilot\nCredentials',
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
                  'Verify your license and supporting documents',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 30),
                _buildSelectField(
                  hintText: 'License Type',
                  icon: Icons.workspace_premium_outlined,
                  value: _selectedLicenseType,
                  items: _licenseTypes,
                  onChanged: (val) =>
                      setState(() => _selectedLicenseType = val),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _licenseNumberController,
                  hintText: 'License Number',
                  suffixIcon: const Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: kHint,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _authorityController,
                  hintText: 'Issuing Authority',
                  suffixIcon: const Icon(
                    Icons.account_balance_outlined,
                    size: 16,
                    color: kHint,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _expiryController,
                  hintText: 'Expiration Date',
                  readOnly: true,
                  onTap: _pickExpiryDate,
                  suffixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: kHint,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 18),
                _buildDocumentUploadTile(
                  document: _PilotDocumentType.license,
                  subtitle: 'Required',
                  hasError: _showLicenseUploadError,
                ),
                const SizedBox(height: 12),
                _buildDocumentUploadTile(
                  document: _PilotDocumentType.permit,
                  subtitle: 'Optional',
                ),
                const SizedBox(height: 32),
                _buildPrimaryButton(
                  text: 'Complete Registration',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleComplete,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
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
            color: Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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

  Widget _buildDocumentUploadTile({
    required _PilotDocumentType document,
    required String subtitle,
    bool hasError = false,
  }) {
    final file = _documentFile(document);
    final isPicking = _pickingDocument == document;
    final hasFile = file != null;
    final borderColor = hasError ? kDanger : (hasFile ? kPrimary : kBorder);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showDocumentActionSheet(document),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: hasFile ? 1.2 : 0.8),
          boxShadow: hasFile
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: hasFile ? kPrimarySoft : kSurfaceSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isPicking
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: kPrimary,
                          ),
                        ),
                      )
                    : hasFile
                    ? Image.file(
                        file,
                        key: ValueKey(file.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.description_outlined,
                            color: kPrimary,
                            size: 28,
                          );
                        },
                      )
                    : Icon(
                        document == _PilotDocumentType.license
                            ? Icons.badge_outlined
                            : Icons.verified_user_outlined,
                        color: hasError ? kDanger : kHint,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _documentTitle(document),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: kTextDark,
                          ),
                        ),
                      ),
                      if (hasFile)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: kSuccess,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile ? 'Uploaded' : subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: hasError ? kDanger : kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              hasFile ? Icons.edit_rounded : Icons.add_a_photo_rounded,
              color: hasError ? kDanger : kPrimary,
              size: 19,
            ),
          ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
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
          vertical: 13,
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
      validator: (v) => value == null ? 'Required' : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                    Icon(icon, size: 17, color: kHint),
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
                    padding: const EdgeInsets.only(top: 6, left: 27),
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
    IconData icon = Icons.arrow_forward_rounded,
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
              color: kPrimary.withValues(alpha: 0.28),
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
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(icon, color: Colors.white, size: 16),
                  ],
                ),
        ),
      ),
    );
  }
}

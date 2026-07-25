import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tototl_app/features/auth/register/pilot/pilot_register_step_tow_screen.dart';

// ===========================================================================
// SCREEN 1: Create Account + Basic Information
// ===========================================================================
class PilotRegisterStepOneScreen extends StatefulWidget {
  const PilotRegisterStepOneScreen({super.key});

  @override
  State<PilotRegisterStepOneScreen> createState() =>
      _PilotRegisterStepOneScreenState();
}

class _PilotRegisterStepOneScreenState
    extends State<PilotRegisterStepOneScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Selections & States
  String? _selectedNationality;
  String _selectedCountryCode = '+966';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _avatarImage;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  // Application Theme Colors
  static const Color kPrimary = Color(0xFF1E56F0);
  static const Color kPrimarySoft = Color(0xFFEFF3FE);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);
  static const Color kHint = Color(0xFF94A3B8);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kSurfaceSoft = Color(0xFFF8FAFC);
  static const Color kDanger = Color(0xFFEF4444);

  final List<String> _countryCodes = ['+966', '+971', '+965', '+962', '+20', '+1'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Profile Picture Picker
  // ---------------------------------------------------------------------
  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        final file = File(picked.path);
        if (await file.exists()) {
          setState(() => _avatarImage = file);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Could not open source. Please check app permissions.');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
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

  void _showImageSourceActionSheet() {
    HapticFeedback.lightImpact();
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profile Photo',
                      style: TextStyle(
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
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose from Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_avatarImage != null) ...[
                    const SizedBox(height: 10),
                    _buildSheetOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove Photo',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _avatarImage = null);
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

  // ---------------------------------------------------------------------
  // Date Picker
  // ---------------------------------------------------------------------
  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
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
      _dobController.text = DateFormat('dd / MM / yyyy').format(picked);
    }
  }

  // ---------------------------------------------------------------------
  // Bottom Sheet Selection Helper
  // ---------------------------------------------------------------------
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
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? kPrimary : Colors.transparent,
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
                                  const Icon(Icons.check_circle_rounded,
                                      size: 20, color: kPrimary),
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

  // ---------------------------------------------------------------------
  // Navigation & Validation
  // ---------------------------------------------------------------------
  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (_selectedNationality == null) {
      _showSnack('Please select your nationality');
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const PilotRegisterStepTwoScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.3, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    _buildBackButton(),
                    const Spacer(),
                    _buildAnimatedStepIndicator(currentStep: 1),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 28),

                // Title & Subtitle
                const Text(
                  'Create Pilot Account',
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
                  "Create your account and enter your basic personal details.",
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Profile Picture
                Center(child: _buildAvatarPicker()),
                const SizedBox(height: 28),

                // 2. Full Name
                _buildTextField(
                  controller: _fullNameController,
                  hintText: 'Full Name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                ),
                const SizedBox(height: 12),

                // 3. Email Address
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final emailRegex =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 4. Password
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: kHint,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 5. Confirm Password
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_reset_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: kHint,
                      size: 18,
                    ),
                    onPressed: () => setState(() =>
                    _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 6. Phone Number
                _buildPhoneField(),
                const SizedBox(height: 12),

                // 7. Date of Birth
                _buildTextField(
                  controller: _dobController,
                  hintText: 'Date of Birth',
                  readOnly: true,
                  onTap: _pickDate,
                  prefixIcon: Icons.calendar_today_rounded,
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: kHint),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Date of Birth is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // 8. Nationality
                _buildSelectField(
                  hintText: 'Nationality',
                  icon: Icons.flag_outlined,
                  value: _selectedNationality,
                  items: const [
                    'Saudi',
                    'Emirati',
                    'Kuwaiti',
                    'Qatari',
                    'Omani',
                    'Bahraini',
                    'Jordanian',
                    'Egyptian',
                    'Other'
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedNationality = val),
                ),

                const SizedBox(height: 32),

                // Next Button
                _buildPrimaryButton(
                  text: 'Next',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleNext,
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
  // UI Builder Widgets
  // ---------------------------------------------------------------------

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 13, color: kTextDark),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kSurfaceSoft,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: _isPickingImage
                  ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: kPrimary,
                  ),
                ),
              )
                  : (_avatarImage != null
                  ? Image.file(
                _avatarImage!,
                key: ValueKey(_avatarImage!.path),
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.person_pin_rounded,
                  size: 70, color: Color(0xFFCBD5E1))),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.photo_camera_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStepIndicator({required int currentStep}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        int stepNumber = index + 1;
        bool isActive = stepNumber == currentStep;
        bool isPassed = stepNumber < currentStep;

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
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
            color: kHint, fontSize: 13, fontWeight: FontWeight.w400),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: kHint)
            : null,
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(fontSize: 11, color: kDanger),
        fillColor: Colors.white,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder, width: 0.8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder, width: 0.8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimary, width: 1.2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kDanger, width: 1)),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Phone number is required';
        if (v.trim().length < 7) return 'Enter a valid phone number';
        return null;
      },
      style: const TextStyle(
        fontSize: 13.5,
        color: kTextDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Phone Number',
        hintStyle: const TextStyle(
            color: kHint, fontSize: 13, fontWeight: FontWeight.w400),
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  icon: const Icon(Icons.arrow_drop_down, color: kHint, size: 18),
                  items: _countryCodes.map((code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCountryCode = val);
                    }
                  },
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: kBorder,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          ),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: kDanger),
        fillColor: Colors.white,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder, width: 0.8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder, width: 0.8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimary, width: 1.2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kDanger, width: 1)),
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
      validator: (v) => value == null ? 'Nationality is required' : null,
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
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: kHint),
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
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: Colors.white),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
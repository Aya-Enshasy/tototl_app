import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
 import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tototl_app/features/auth/screens/register/pilot/pilot_register_step_tow_screen.dart';
import '../../../../../model/Country.dart';


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
  final TextEditingController _linkedinController = TextEditingController();

  // Selections & States
  String? _selectedNationality;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _avatarImage;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  List<Country> _countries = [];
  Country? _selectedCountry;


  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _linkedinController.dispose();
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
        backgroundColor: AppColors.kTextDark,
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
                      color: AppColors.kBorder,
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
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSheetOption(
                    icon: Icons.camera_alt,
                    label: 'Take a Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    icon: Icons.photo,
                    label: 'Choose from Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_avatarImage != null) ...[
                    const SizedBox(height: 10),
                    _buildSheetOption(
                      icon: Icons.delete_rounded,
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
    final color = isDestructive ? AppColors.kDanger : AppColors.kPrimary;
    return Material(
      color: AppColors.kSurfaceSoft,
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
                  color: isDestructive ? color : AppColors.kTextDark,
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
              primary: AppColors.kPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.kTextDark,
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
                      color: AppColors.kBorder,
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
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...items.map((item) {
                    final isSelected = item == selected;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected ? AppColors.kPrimarySoft : AppColors.kSurfaceSoft,
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
                                color: isSelected ? AppColors.kPrimary : Colors.transparent,
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
                                      color: isSelected ? AppColors.kPrimary : AppColors.kTextDark,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      size: 20, color: AppColors.kPrimary),
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
    // if (!_formKey.currentState!.validate()) {
    //   HapticFeedback.heavyImpact();
    //   return;
    // }

    // if (_selectedNationality == null) {
    //   _showSnack('Please select your nationality');
    //   return;
    // }

    // setState(() => _isSubmitting = true);
    // await Future.delayed(const Duration(milliseconds: 250));
    // if (!mounted) return;
    // setState(() => _isSubmitting = false);

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
                    color: AppColors.kTextDark,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create your account and enter your basic personal details.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.kTextMuted,
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
                      color: AppColors.kHint,
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
                      color: AppColors.kHint,
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
                      size: 20, color: AppColors.kHint),
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
                const SizedBox(height: 12),

                // 9. LinkedIn Profile (Optional)
                _buildTextField(
                  controller: _linkedinController,
                  hintText: 'LinkedIn Profile URL (optional)',
                  prefixIcon: Icons.link_rounded,
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
            size: 13, color: AppColors.kTextDark),
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
              color: AppColors.kSurfaceSoft,
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
                    color: AppColors.kPrimary,
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
                  : const Icon(Icons.person,
                  size: 70, color: Color(0xFFCBD5E1))),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.kPrimary,
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
                color: isActive || isPassed ? AppColors.kPrimary : Colors.white,
                border: Border.all(
                  color: isActive || isPassed ? AppColors.kPrimary : AppColors.kBorder,
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
                    color: isActive ? Colors.white : AppColors.kHint,
                  ),
                ),
              ),
            ),
            if (index < 3)
              Container(
                width: 26,
                height: 1.5,
                color: stepNumber < currentStep ? AppColors.kPrimary : AppColors.kBorder,
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
        color: AppColors.kTextDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
            color: AppColors.kHint, fontSize: 13, fontWeight: FontWeight.w400),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.kHint)
            : null,
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(fontSize: 11, color: AppColors.kDanger),
        fillColor: Colors.white,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kBorder, width: 0.8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kBorder, width: 0.8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kDanger, width: 1)),
      ),
    );
  }

  Widget _buildPhoneField() {
    debugPrint('Countries loaded: ${_countries.length}');

    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,

      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Phone number is required';
        }

        if (v.trim().length < 7) {
          return 'Enter a valid phone number';
        }

        return null;
      },

      style: const TextStyle(
        fontSize: 13.5,
        color: AppColors.kTextDark,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: 'Phone Number',

        hintStyle: const TextStyle(
          color: AppColors.kHint,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),

        // =========================
        // Country Code
        // =========================
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Country selector
              InkWell(
                onTap: _countries.isEmpty
                    ? null
                    : _showCountryPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry?.dialCode ?? '+970',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark,
                        ),
                      ),

                      const SizedBox(width: 2),

                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.kHint,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 20,
                color: AppColors.kBorder,
                margin: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
              ),
            ],
          ),
        ),

        errorStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.kDanger,
        ),

        fillColor: Colors.white,
        filled: true,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.kPrimary,
            width: 1.2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.kDanger,
            width: 1,
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
              MediaQuery.of(context).size.height * 0.75,
            ),

            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =========================
                // Handle
                // =========================
                const SizedBox(height: 10),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.kBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                // =========================
                // Header
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Country',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextDark,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.kHint,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  color: AppColors.kBorder,
                ),

                // =========================
                // Countries
                // =========================
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    itemCount: _countries.length,
                    separatorBuilder: (_, __) {
                      return const Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: AppColors.kBorder,
                      );
                    },
                    itemBuilder: (context, index) {
                      final country = _countries[index];

                      final isSelected =
                          _selectedCountry?.dialCode ==
                              country.dialCode &&
                              _selectedCountry?.name ==
                                  country.name;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                          });

                          Navigator.pop(context);
                        },

                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),

                          child: Row(
                            children: [
                              // Country name
                              Expanded(
                                child: Text(
                                  country.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppColors.kTextDark,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Dial code
                              Text(
                                country.dialCode,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.kPrimary
                                      : AppColors.kTextDark,
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Selected icon
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: AppColors.kPrimary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                color: state.hasError ? AppColors.kDanger : AppColors.kBorder,
                width: state.hasError ? 1 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.kHint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        value ?? hintText,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: value == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: value == null ? AppColors.kHint : AppColors.kTextDark,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: AppColors.kHint),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 28),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(fontSize: 11, color: AppColors.kDanger),
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
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D8AA5), AppColors.kPrimary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimary.withOpacity(0.28),
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

  Future<void> _loadCountries() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/countries.json',
      );

      final List<dynamic> jsonData = json.decode(jsonString);

      final countries = jsonData
          .map((item) => Country.fromJson(item))
          .toList();

      if (!mounted) return;

      setState(() {
        _countries = countries;

        if (_countries.isNotEmpty) {
          _selectedCountry = _countries.first;
        }
      });

      debugPrint('Countries loaded: ${_countries.length}');
    } catch (e) {
      debugPrint('ERROR loading countries: $e');
    }
  }
}
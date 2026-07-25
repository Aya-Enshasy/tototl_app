import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'company_register_step_tow_screen.dart';

class CompanyRegisterStepOneScreen extends StatefulWidget {
  const CompanyRegisterStepOneScreen({super.key});

  @override
  State<CompanyRegisterStepOneScreen> createState() =>
      _CompanyRegisterStepOneScreenState();
}

class _CompanyRegisterStepOneScreenState
    extends State<CompanyRegisterStepOneScreen> {
  final _formKey = GlobalKey<FormState>();

  // متحكمات النصوص (Controllers)
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // الحالة
  String? _selectedCompanyType;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // قائمة أنواع الشركات (Company Type Dropdown)
  final List<String> _companyTypes = [
    'Construction',
    'Energy',
    'Real Estate',
    'Inspection',
    'Agriculture',
    'Other',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _userIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCompanyType == null) {
      _showSnack('Please select a company type');
      return;
    }

    // الانتقال للخطوة الثانية
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyRegisterStepTwoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1. الشريط العلوي (زر الرجوع + مؤشر الـ 4 خطوات)
                // ==========================================
                Row(
                  children: [
                    _buildBackButton(),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(currentStep: 1),
                      ),
                    ),
                    const SizedBox(width: 38), // لموازنة زر الرجوع
                  ],
                ),
                const SizedBox(height: 30),

                // ==========================================
                // 2. العنوان الرئيسي والفرعي
                // ==========================================
                const Text(
                  'Create Company\nAccount',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Basic information required to setup your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8F93A3),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 3. اختيار شعار الشركة (Company Logo)
                // ==========================================
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 42,
                          color: Color(0xFFA0A5BA),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            // اختيار صوة اللوجو
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              size: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 4. حقول الإدخال (Fields)
                // ==========================================

                // Company Name
                _buildTextField(
                  controller: _companyNameController,
                  hintText: 'Company Name',
                  prefixIcon: const Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: Color(0xFFA0A5BA),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Company name is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // User ID
                _buildTextField(
                  controller: _userIdController,
                  hintText: 'User ID / Username',
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    size: 20,
                    color: Color(0xFFA0A5BA),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'User ID is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Email Address
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    size: 20,
                    color: Color(0xFFA0A5BA),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email address is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(val.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone Number
                _buildTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number (with Country Code)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    size: 20,
                    color: Color(0xFFA0A5BA),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Phone number is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Company Type Dropdown
                _buildDropdownField(
                  hintText: 'Company Type',
                  value: _selectedCompanyType,
                  items: _companyTypes,
                  onChanged: (val) => setState(() => _selectedCompanyType = val),
                ),
                const SizedBox(height: 14),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: Color(0xFFA0A5BA),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFA0A5BA),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm Password
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(
                    Icons.lock_reset_rounded,
                    size: 20,
                    color: Color(0xFFA0A5BA),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFA0A5BA),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Confirm password is required';
                    }
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 5. زر الانتقال للخطوة التالية (Next Button)
                // ==========================================
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3F6DFB),
                        Color(0xFF1E4CE7),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3F6DFB).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS المخصصة الموحدة مع قسم الدرون
  // ===========================================================================

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required int currentStep}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == currentStep;
        final isPassed = stepNumber < currentStep;

        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isPassed
                    ? const Color(0xFF3F6DFB)
                    : Colors.white,
                border: Border.all(
                  color: isActive || isPassed
                      ? const Color(0xFF3F6DFB)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Center(
                child: isPassed
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
            if (index < 3)
              Container(
                width: 26,
                height: 2,
                color: isPassed ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
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
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA0A5BA), fontSize: 14),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3F6DFB), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hintText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hintText,
            style: const TextStyle(
              color: Color(0xFFA0A5BA),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF9E9E9E),
          ),
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.category_outlined,
              size: 20,
              color: Color(0xFFA0A5BA),
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF3F6DFB), width: 1.5),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
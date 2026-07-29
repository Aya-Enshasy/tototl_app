import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/features/auth/register/company/company_register_step_four_screen.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'company_register_step_three_screen.dart';

class CompanyRegisterStepTwoScreen extends StatefulWidget {
  const CompanyRegisterStepTwoScreen({super.key});

  @override
  State<CompanyRegisterStepTwoScreen> createState() =>
      _CompanyRegisterStepTwoScreenState();
}

class _CompanyRegisterStepTwoScreenState
    extends State<CompanyRegisterStepTwoScreen> {
  final _formKey = GlobalKey<FormState>();

  // متحكمات النصوص
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // حالة الموافقة على الشروط
  bool _isAgreed = false;

  // مناطق العمل والمشروعات (Operating Regions)
  final List<String> _availableRegions = [
    'Saudi Arabia',
    'United Arab Emirates',
    'GCC Region',
    'Middle East',
    'North America',
    'Europe',
  ];
  final List<String> _selectedRegions = [];

  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRegions.isEmpty) {
      _showSnack('Please select at least one operating region');
      return;
    }
    if (!_isAgreed) {
      _showSnack('Please agree to the User Contract Agreement & Terms');
      return;
    }

    // الانتقال للخطوة الثالثة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyRegisterStepFourScreen(),
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
                // 1. شريط العلوي (زر الرجوع + مؤشر 4 خطوات)
                // ==========================================
                Row(
                  children: [
                    _buildBackButton(),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(currentStep: 2),
                      ),
                    ),
                    const SizedBox(width: 38), // لموازنة زر الرجوع
                  ],
                ),
                const SizedBox(height: 30),

                // ==========================================
                // 2. العناوين والنصوص (Header)
                // ==========================================
                const Text(
                  'Company\nProfile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Collect company information and operating areas',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 3. حقول الموقع الجغرافي (Location Fields)
                // ==========================================

                // Country
                _buildTextField(
                  controller: _countryController,
                  hintText: 'Country',
                  prefixIcon: const Icon(Icons.public_rounded, size: 20, color: AppColors.lightGrey),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Country is required' : null,
                ),
                const SizedBox(height: 14),

                // State / Province & City (في صف واحد)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        hintText: 'State / Province',
                        prefixIcon: const Icon(Icons.map_outlined, size: 20, color: AppColors.lightGrey),
                        validator: (val) => val == null || val.trim().isEmpty ? 'State is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        hintText: 'City',
                        prefixIcon: const Icon(Icons.location_city_rounded, size: 20, color: AppColors.lightGrey),
                        validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Company Address
                _buildTextField(
                  controller: _addressController,
                  hintText: 'Company Address',
                  prefixIcon: const Icon(Icons.home_work_outlined, size: 20, color: AppColors.lightGrey),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 4. مناطق التشغيل (Operating Regions)
                // ==========================================
                const Text(
                  'Operating Regions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select regions where your company operates',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8F93A3),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _availableRegions.map((region) {
                    final isSelected = _selectedRegions.contains(region);
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedRegions.remove(region);
                          } else {
                            _selectedRegions.add(region);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF16C6C7) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF16C6C7) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              region,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check, size: 14, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 5. وصف الشركة (Company Description)
                // ==========================================
                const Text(
                  'Company Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionController,
                  hintText: 'Company background, services provided, industry experience...',
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please describe your company' : null,
                ),
                const SizedBox(height: 20),

                // ==========================================
                // 6. الموافقة على الشروط (Agreement Checkbox)
                // ==========================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isAgreed,
                        activeColor: const Color(0xFF16C6C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) {
                          setState(() => _isAgreed = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'User Contract Agreement and Terms & Conditions',
                              style: const TextStyle(
                                color: Color(0xFF16C6C7),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showTermsAndConditionsSheet,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 7. زر الانتقال للخطوة التالية (Next Button)
                // ==========================================
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF16C6C7),
                        Color(0xFF0D8AA5),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16C6C7).withOpacity(0.35),
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
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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
  // WIDGETS المخصصة لتناسب أسلوب وتصميم قسم الدرون
  // ===========================================================================

  // زر الرجوع المخصص بالدائرة المتناسقة
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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

  // مؤشر الخطوات الـ 4 المخصص للشركة
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
                    ? const Color(0xFF16C6C7)
                    : Colors.white,
                border: Border.all(
                  color: isActive || isPassed
                      ? const Color(0xFF16C6C7)
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
                color: isPassed ? const Color(0xFF16C6C7) : const Color(0xFFE5E7EB),
              ),
          ],
        );
      }),
    );
  }

  // بناء حقول النصوص بأسلوب الخانات الموحد
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
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
        maxLines: maxLines,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            borderSide: const BorderSide(color: Color(0xFF16C6C7), width: 1.5),
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
  Future<void> _showTermsAndConditionsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 300),
        vsync: Navigator.of(context),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'User Contract Agreement & Terms',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: const Text(
                        // ضع نص الشروط والأحكام الفعلي هون
                        '1. Acceptance of Terms\n'
                            'By creating a company account on this platform, you agree to be bound by these Terms & Conditions and our User Contract Agreement.\n\n'
                            '2. Company Responsibilities\n'
                            'Your company agrees to provide accurate information, comply with local aviation regulations, and ensure all posted jobs meet safety standards.\n\n'
                            '3. Pilot Engagement\n'
                            'All engagements with pilots through the platform must follow the agreed scope of work, payment terms, and safety protocols outlined in each job listing.\n\n'
                            '4. Payments & Subscriptions\n'
                            'Subscription fees are billed according to the plan selected and are non-refundable except as required by law.\n\n'
                            '5. Data & Privacy\n'
                            'We collect and process data in accordance with our Privacy Policy to match companies with qualified drone pilots.\n\n'
                            '6. Limitation of Liability\n'
                            'The platform acts as an intermediary and is not liable for damages arising from services performed by independent pilots.\n\n'
                            '7. Termination\n'
                            'We reserve the right to suspend or terminate accounts that violate these terms or engage in fraudulent activity.\n\n'
                            '8. Governing Law\n'
                            'These terms are governed by the laws of the jurisdiction in which the platform operates.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF4B5563),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

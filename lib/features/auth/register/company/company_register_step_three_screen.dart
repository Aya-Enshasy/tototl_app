import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'company_register_step_four_screen.dart';

class CompanyRegisterStepThreeScreen extends StatefulWidget {
  const CompanyRegisterStepThreeScreen({super.key});

  @override
  State<CompanyRegisterStepThreeScreen> createState() =>
      _CompanyRegisterStepThreeScreenState();
}

class _CompanyRegisterStepThreeScreenState
    extends State<CompanyRegisterStepThreeScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Job Types (اختيار متعدد)
  final List<String> _jobTypes = [
    'Inspection',
    'Mapping',
    'Photography',
    'Construction Monitoring',
    'Surveying',
    'Other',
  ];
  final List<String> _selectedJobTypes = [];

  // 2. Drone Requirements (اختيار متعدد)
  final List<String> _droneRequirements = [
    'Thermal Camera',
    'Laser',
    'Night Vision',
    'LiDAR',
    'Radar',
    'Imaging',
  ];
  final List<String> _selectedDroneRequirements = [];

  // 3. Drone Size Requirement (اختيار واحد)
  String? _selectedDroneSize;
  final List<String> _droneSizes = ['Small', 'Medium', 'Large'];

  // 4. Safety Requirements (خيارات إضافية)
  bool _safetyTrainingRequired = false;
  bool _specialCertificationsRequired = false;

  // 5. Other Requirements Controller
  final TextEditingController _otherRequirementsController =
  TextEditingController();

  // 6. Job Site Options
  bool _includePIDs = false;
  bool _includeImages = false;

  @override
  void dispose() {
    _otherRequirementsController.dispose();
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
    if (_selectedJobTypes.isEmpty) {
      _showSnack('Please select at least one Job Type');
      return;
    }
    if (_selectedDroneSize == null) {
      _showSnack('Please select a Drone Size Requirement');
      return;
    }

    // الانتقال للخطوة الرابعة والأخيرة
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
                // 1. الشريط العلوي (زر الرجوع + مؤشر الـ 4 خطوات)
                // ==========================================
                Row(
                  children: [
                    _buildBackButton(),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(currentStep: 3),
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
                  'Job Requirements',
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
                  'Define your drone job specifications to match suitable pilots',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8F93A3),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 3. نوع المهمة (Job Types)
                // ==========================================
                const Text(
                  'Job Types',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select all services required for your projects',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF8F93A3)),
                ),
                const SizedBox(height: 12),
                _buildMultiSelectChips(
                  options: _jobTypes,
                  selectedList: _selectedJobTypes,
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 4. مواصفات ومعدات الدرون (Drone Requirements)
                // ==========================================
                const Text(
                  'Drone Equipment & Sensors',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select required sensors and cameras',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF8F93A3)),
                ),
                const SizedBox(height: 12),
                _buildMultiSelectChips(
                  options: _droneRequirements,
                  selectedList: _selectedDroneRequirements,
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 5. حجم الدرون (Drone Size Requirement)
                // ==========================================
                const Text(
                  'Drone Size Requirement',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _droneSizes.map((size) {
                    final isSelected = _selectedDroneSize == size;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _selectedDroneSize = size);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3F6DFB)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3F6DFB)
                                    : const Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                size,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 6. متطلبات السلامة (Safety Requirements)
                // ==========================================
                const Text(
                  'Safety Requirements',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildCheckboxRow(
                  title: 'Safety Training Required',
                  value: _safetyTrainingRequired,
                  onChanged: (val) {
                    setState(() => _safetyTrainingRequired = val ?? false);
                  },
                ),
                _buildCheckboxRow(
                  title: 'Special Certifications Required',
                  value: _specialCertificationsRequired,
                  onChanged: (val) {
                    setState(
                            () => _specialCertificationsRequired = val ?? false);
                  },
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 7. متطلبات إضافية (Other Requirements)
                // ==========================================
                const Text(
                  'Other Requirements',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _otherRequirementsController,
                  hintText: 'Any special permissions, insurance, or pilot experience...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 8. خيارات موقع العمل (Job Site Options)
                // ==========================================
                const Text(
                  'Job Site Options',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildCheckboxRow(
                  title: 'Include P&IDs of Job Site',
                  value: _includePIDs,
                  onChanged: (val) {
                    setState(() => _includePIDs = val ?? false);
                  },
                ),
                _buildCheckboxRow(
                  title: 'Include Images of Job Site',
                  value: _includeImages,
                  onChanged: (val) {
                    setState(() => _includeImages = val ?? false);
                  },
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 9. زر الانتقال للخطوة التالية (Next Button)
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

  Widget _buildMultiSelectChips({
    required List<String> options,
    required List<String> selectedList,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedList.remove(option);
              } else {
                selectedList.add(option);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option,
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
    );
  }

  Widget _buildCheckboxRow({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  activeColor: const Color(0xFF3F6DFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
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
        ),
      ),
    );
  }
}
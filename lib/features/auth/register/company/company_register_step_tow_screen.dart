import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/features/auth/register/company/company_register_step_three_screen.dart';

class CompanyRegisterStepTwoScreen extends StatefulWidget {
  const CompanyRegisterStepTwoScreen({super.key});

  @override
  State<CompanyRegisterStepTwoScreen> createState() => _CompanyRegisterStepTwoScreenState();
}

class _CompanyRegisterStepTwoScreenState extends State<CompanyRegisterStepTwoScreen> {
  final _formKey = GlobalKey<FormState>();

  // التحكم في النصوص
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedIndustry;

  // قائمة القطاعات للـ Dropdown
  final List<String> _industries = [
    'Photography & Videography',
    'Real Estate & Construction',
    'Agriculture & Farming',
    'Security & Surveillance',
    'Geographic Inspection',
    'Delivery & Logistics'
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

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
                // 1. مؤشر الخطوات (Step 1 Completed, Step 2 Active)
                // ==========================================
                const SizedBox(height: 10),
                _buildStepIndicator(),
                const SizedBox(height: 35),

                // ==========================================
                // 2. العناوين والنصوص (Header)
                // ==========================================
                const Text(
                  'Company Details',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Add more details about your business",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8F93A3),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 35),

                // ==========================================
                // 3. حقول الإدخال (Form Fields)
                // ==========================================

                // حقل عنوان الشركة (Business Address)
                _buildTextField(
                  controller: _addressController,
                  hintText: 'Business Address',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFFA0A5BA)),
                ),
                const SizedBox(height: 16),

                // حقل الموقع الإلكتروني (Website - Optional)
                _buildTextField(
                  controller: _websiteController,
                  hintText: 'Website (Optional)',
                  keyboardType: TextInputType.url,
                  prefixIcon: const Icon(Icons.language_rounded, size: 20, color: Color(0xFFA0A5BA)),
                ),
                const SizedBox(height: 16),

                // حقل قطاع العمل (Industry - Dropdown)
                _buildDropdownField(
                  hintText: 'Industry',
                  value: _selectedIndustry,
                  items: _industries,
                  onChanged: (val) => setState(() => _selectedIndustry = val),
                ),
                const SizedBox(height: 16),

                // حقل وصف الشركة الممتد (Company Description)
                _buildTextField(
                  controller: _descriptionController,
                  hintText: 'Company Description',
                  maxLines: 4, // يتيح كتابة نص متعدد الأسطر بشكل مريح للشركات
                ),
                const SizedBox(height: 40),

                // ==========================================
                // 4. زر الانتقال للخطوة التالية (Next Button)
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
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanyRegisterStepThreeScreen(),
                        ),
                      );
                      if (_formKey.currentState!.validate()) {
                        // الانتقال لـ Company Step 3 (Subscription Plan)
                      }
                    },
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
  // دالات بناء عناصر الواجهة المخصصة (Custom Widgets) الموحدة للمشروع
  // ===========================================================================

  // بناء مؤشر الخطوات (3 خطوات إجمالية، الخطوة 1 مكتملة بالصح ✅، و 2 نشطة)
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index == 1; // الخطوة الثانية نشطة
        bool isPassed = index < 1;  // الخطوة الأولى تم تجاوزها بنجاح

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
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
            if (index < 2)
              Container(
                width: 60,
                height: 2,
                color: index < 1 ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
              ),
          ],
        );
      }),
    );
  }

  // بناء حقول النصوص الفاخرة
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
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
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA0A5BA), fontSize: 14),
          prefixIcon: prefixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

  // بناء حقل الـ Dropdown للقطاعات
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
            style: const TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9E9E9E)),
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.work_outline_rounded, size: 20, color: Color(0xFFA0A5BA)),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
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
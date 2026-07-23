import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'company_register_step_tow_screen.dart';

class CompanyRegisterStepOneScreen extends StatefulWidget {
  const CompanyRegisterStepOneScreen({super.key});

  @override
  State<CompanyRegisterStepOneScreen> createState() => _CompanyRegisterStepOneScreenState();
}

class _CompanyRegisterStepOneScreenState extends State<CompanyRegisterStepOneScreen> {
  final _formKey = GlobalKey<FormState>();

  // التحكم في النصوص
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedCountry;

  // قائمة الدول للـ Dropdown
  final List<String> _countries = ['Saudi Arabia', 'United Arab Emirates', 'Kuwait', 'Qatar', 'Oman', 'Bahrain', 'Egypt'];

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
                // 1. مؤشر الخطوات المخصص للشركات (3 خطوات فقط)
                // ==========================================
                const SizedBox(height: 10),
                _buildStepIndicator(),
                const SizedBox(height: 35),

                // ==========================================
                // 2. العناوين والنصوص (Header)
                // ==========================================
                const Text(
                  'Company\nInformation',
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
                  "Tell us about your company",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8F93A3),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 30),

                // ==========================================
                // 3. رفع شعار الشركة (Company Logo Picker)
                // ==========================================
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.business_rounded, // أيقونة منشأة/شركة متناسقة مع المظهر
                          size: 44,
                          color: Color(0xFFA0A5BA),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // هنا يتم استدعاء ملفات الصور لاحقاً لتغيير اللوجو
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
                const SizedBox(height: 35),

                // ==========================================
                // 4. حقول الإدخال (Form Fields)
                // ==========================================

                // حقل اسم الشركة
                _buildTextField(
                  controller: _companyNameController,
                  hintText: 'Company Name',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20, color: Color(0xFFA0A5BA)),
                ),
                const SizedBox(height: 16),

                // حقل البريد الإلكتروني
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFFA0A5BA)),
                ),
                const SizedBox(height: 16),

                // حقل رقم الهاتف للشركة
                _buildTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFFA0A5BA)),
                ),
                const SizedBox(height: 16),

                // حقل الدولة (Dropdown)
                _buildDropdownField(
                  hintText: 'Country',
                  value: _selectedCountry,
                  items: _countries,
                  onChanged: (val) => setState(() => _selectedCountry = val),
                ),
                const SizedBox(height: 40),

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
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanyRegisterStepTwoScreen(),
                        ),
                      );
                      if (_formKey.currentState!.validate()) {
                        // الانتقال لـ Company Step 2 (Company Details)
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
  // دالات بناء عناصر الواجهة المخصصة (Custom Widgets) الموحدة
  // ===========================================================================

  // بناء مؤشر الخطوات المخصص (3 خطوات إجمالية للشركات، الخطوة 1 نشطة)
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index == 0; // الخطوة الأولى نشطة
        bool isPassed = index < 0;

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
            // خط الربط بين الدوائر الثلاثة
            if (index < 2)
              Container(
                width: 60, // تم زيادة الطول قليلاً لأن الخطوات 3 فقط لتبدو متناسقة في عرض الشاشة
                height: 2,
                color: isPassed ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
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

  // بناء حقل الـ Dropdown للدول
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
            prefixIcon: const Icon(Icons.public_rounded, size: 20, color: Color(0xFFA0A5BA)),
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
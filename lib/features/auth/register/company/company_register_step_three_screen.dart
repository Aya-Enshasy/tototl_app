import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompanyRegisterStepThreeScreen extends StatefulWidget {
  const CompanyRegisterStepThreeScreen({super.key});

  @override
  State<CompanyRegisterStepThreeScreen> createState() => _CompanyRegisterStepThreeScreenState();
}

class _CompanyRegisterStepThreeScreenState extends State<CompanyRegisterStepThreeScreen> {
  // تتبع الخطة المختارة (0 = Basic, 1 = Pro, 2 = Enterprise)
  int _selectedPlanIndex = 1; // افتراضياً نحدد الـ Pro لأنها الأكثر شعبية

  // بيانات خطط الاشتراك
  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Basic',
      'price': '\$49',
      'period': '/month',
      'desc': 'Perfect for small startups starting their drone operations.',
      'features': ['Up to 3 active pilots', 'Standard support', '5GB Cloud storage'],
      'isPopular': false,
    },
    {
      'title': 'Professional',
      'price': '\$149',
      'period': '/month',
      'desc': 'Best for growing businesses looking for advanced management.',
      'features': ['Unlimited pilots', '24/7 Priority support', '100GB Cloud storage', 'Advanced Analytics'],
      'isPopular': true,
    },
    {
      'title': 'Enterprise',
      'price': 'Custom',
      'period': '',
      'desc': 'Tailored solutions for large organizations and corporations.',
      'features': ['Custom integration', 'Dedicated account manager', 'Unlimited storage', 'On-site training'],
      'isPopular': false,
    },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. مؤشر الخطوات (Step 1 & 2 Completed, Step 3 Active)
              // ==========================================
              const SizedBox(height: 10),
              _buildStepIndicator(),
              const SizedBox(height: 35),

              // ==========================================
              // 2. العناوين والنصوص (Header)
              // ==========================================
              const Text(
                'Subscription Plan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose the best plan for your company size",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8F93A3),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),

              // ==========================================
              // 3. كروت خطط الأسعار التفاعلية
              // ==========================================
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  bool isSelected = _selectedPlanIndex == index;
                  return _buildPlanCard(
                    index: index,
                    title: plan['title'],
                    price: plan['price'],
                    period: plan['period'],
                    desc: plan['desc'],
                    features: plan['features'],
                    isPopular: plan['isPopular'],
                    isSelected: isSelected,
                  );
                },
              ),
              const SizedBox(height: 35),

              // ==========================================
              // 4. زر الإنهاء وإتمام التسجيل (Finish Button)
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
                    // إرسال البيانات كاملة وتوجيه الشركة للوحة التحكم الرئيسية الخاصة بها
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
                        'Complete Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // دالات بناء الواجهات المخصصة (Custom Widgets) الموحدة للمشروع
  // ===========================================================================

  // بناء مؤشر الخطوات الثلاثي الخاص بالشركات (الخطوة 1 و 2 مكتملتان ✅، و 3 نشطة حالياً)
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index == 2; // الخطوة الثالثة والأخيرة نشطة
        bool isPassed = index < 2;  // الخطوتان السابقتان مكتملتان

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
                color: index < 2 ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
              ),
          ],
        );
      }),
    );
  }

  // دالة بناء كرت الخطة السعرية الفاخر والتفاعلي بالكامل مع قائمة الميزات
  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required String desc,
    required List<String> features,
    required bool isPopular,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF3F6DFB).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر العلوي: اسم الخطة وشارة Popular إن وجدت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? const Color(0xFF1E4CE7) : const Color(0xFF1A1A1A),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F6DFB).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(
                        color: Color(0xFF1E4CE7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // وصف الخطة السريع
            Text(
              desc,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 16),

            // السعر والعملة والفترة الزمنية
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8F93A3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E7EB), thickness: 1),
            const SizedBox(height: 12),

            // قائمة الميزات الخاصة بالخطة المعروضة داخل الكرت
            Column(
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
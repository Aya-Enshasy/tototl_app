import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompanyRegisterStepFourScreen extends StatefulWidget {
  const CompanyRegisterStepFourScreen({super.key});

  @override
  State<CompanyRegisterStepFourScreen> createState() =>
      _CompanyRegisterStepFourScreenState();
}

class _CompanyRegisterStepFourScreenState
    extends State<CompanyRegisterStepFourScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. تفضيلات موقع العمل (Job Location Preference)
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // 2. جدول العمل المفضل (Work Schedule)
  String _selectedSchedule = 'Weekly Schedule';

  // 3. اختيار خطة الاشتراك (Subscription Plan)
  String _selectedPlan = 'free'; // 'free' or 'premium'

  // 4. إعدادات الإشعارات (Notifications Settings)
  bool _notifPilotRecs = true;
  bool _notifJobAcceptance = true;
  bool _notifJobAlerts = true;
  bool _notifPilotMessages = true;
  bool _notifCompanyMessages = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _regionController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
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

  void _handleCompleteRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (_selectedPlan == 'premium') {
      // إذا اختار خطة مدفوعة: توجيه للمتصفح الآمن
      _redirectToSecureWebPayment();
    } else {
      // إذا اختار الخطة المجانية: إتمام التسجيل فوراً
      _showSuccessDialog();
    }
  }

  // محاكاة التوجيه لصفحة دفع آمنة في المتصفح
  void _redirectToSecureWebPayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF1FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Color(0xFF3F6DFB),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Redirecting to Secure Browser',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'You will be securely redirected to our 256-bit encrypted checkout portal to finalize your Premium subscription.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF8F93A3),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // إغلاق النافذة
                  // هنا يتم وضع كود فتح المتصفح خارجي: launchUrl(Uri.parse('https://checkout.yourdomain.com'));
                  _showSuccessDialog();
                },
                icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
                label: const Text(
                  'Proceed to Secure Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F6DFB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel & Select Free Plan',
                style: TextStyle(color: Color(0xFF8F93A3), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF1FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF3F6DFB),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Registration Complete!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your company account is ready. Welcome to the platform!',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF8F93A3),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F6DFB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                // 1. الشريط العلوي (زر الرجوع + مؤشر 4 خطوات)
                // ==========================================
                Row(
                  children: [
                    _buildBackButton(),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(currentStep: 4),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
                const SizedBox(height: 30),

                // ==========================================
                // 2. العنوان الرئيسي والفرعي
                // ==========================================
                const Text(
                  'Job Preferences',
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
                  'Set your operating location, schedule, and subscription preference',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8F93A3),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 3. موقع العمل المفضل (Job Location Preference)
                // ==========================================
                const Text(
                  'Job Location Preference',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _regionController,
                  hintText: 'Region (e.g. Middle East)',
                  prefixIcon: const Icon(Icons.public_rounded, size: 20, color: Color(0xFFA0A5BA)),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Region is required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _countryController,
                  hintText: 'Country',
                  prefixIcon: const Icon(Icons.flag_outlined, size: 20, color: Color(0xFFA0A5BA)),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Country is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        hintText: 'State / Province',
                        prefixIcon: const Icon(Icons.map_outlined, size: 20, color: Color(0xFFA0A5BA)),
                        validator: (val) => val == null || val.trim().isEmpty ? 'State required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        hintText: 'City',
                        prefixIcon: const Icon(Icons.location_city_rounded, size: 20, color: Color(0xFFA0A5BA)),
                        validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 4. جدول العمل (Work Schedule Preference)
                // ==========================================
                const Text(
                  'Work Schedule Preference',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildScheduleCard(
                      title: 'Weekly Schedule',
                      icon: Icons.view_week_rounded,
                      value: 'Weekly Schedule',
                    ),
                    const SizedBox(width: 12),
                    _buildScheduleCard(
                      title: 'Monthly Calendar',
                      icon: Icons.calendar_month_rounded,
                      value: 'Monthly Calendar',
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 5. نظام الاشتراكات (Subscription Plan Selection)
                // ==========================================
                const Text(
                  'Subscription Plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose a plan for your company hiring needs',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF8F93A3)),
                ),
                const SizedBox(height: 16),

                // كارت الخطّة المجانية Free Plan
                _buildPlanCard(
                  planId: 'free',
                  title: 'Free Plan',
                  price: '\$0',
                  period: '/ forever',
                  badgeText: 'FREE ACCESS',
                  badgeColor: const Color(0xFF8F93A3),
                  features: [
                    'Standard pilot search & profiles',
                    'Post up to 2 active job offers',
                    'In-app messaging system',
                  ],
                ),
                const SizedBox(height: 14),

                // كارت الخطّة المتقدمة Premium Plan
                _buildPlanCard(
                  planId: 'premium',
                  title: 'Premium Plan',
                  price: '\$99',
                  period: '/ month',
                  badgeText: 'RECOMMENDED',
                  badgeColor: const Color(0xFF3F6DFB),
                  features: [
                    'AI-powered top pilot matching',
                    'Unlimited active job postings',
                    'Priority direct messaging & calling',
                    'Advanced job site P&ID analysis',
                  ],
                ),
                const SizedBox(height: 16),

                // شارة الخصوصية والدفع الآمن عبر المتصفح
                if (_selectedPlan == 'premium')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, color: Color(0xFF3F6DFB), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Payments are safely processed via encrypted external browser gateway.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),

                // ==========================================
                // 6. إعدادات الإشعارات (Notifications Settings)
                // ==========================================
                const Text(
                  'Notifications Settings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildNotificationToggle(
                  title: 'New Pilot Recommendations',
                  value: _notifPilotRecs,
                  onChanged: (val) => setState(() => _notifPilotRecs = val),
                ),
                _buildNotificationToggle(
                  title: 'Job Acceptance Notifications',
                  value: _notifJobAcceptance,
                  onChanged: (val) => setState(() => _notifJobAcceptance = val),
                ),
                _buildNotificationToggle(
                  title: 'New Job Alerts',
                  value: _notifJobAlerts,
                  onChanged: (val) => setState(() => _notifJobAlerts = val),
                ),
                _buildNotificationToggle(
                  title: 'Messages from Pilot',
                  value: _notifPilotMessages,
                  onChanged: (val) => setState(() => _notifPilotMessages = val),
                ),
                _buildNotificationToggle(
                  title: 'Messages from Company',
                  value: _notifCompanyMessages,
                  onChanged: (val) => setState(() => _notifCompanyMessages = val),
                ),
                const SizedBox(height: 36),

                // ==========================================
                // 7. زر إنهاء التسجيل (Dynamic CTA Button)
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
                    onPressed: _isLoading ? null : _handleCompleteRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedPlan == 'premium'
                              ? 'Proceed to Checkout'
                              : 'Complete Registration',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _selectedPlan == 'premium'
                              ? Icons.open_in_browser_rounded
                              : Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
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

  Widget _buildScheduleCard({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedSchedule == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedSchedule = value);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF3F6DFB).withOpacity(0.06)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFFA0A5BA),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planId,
    required String title,
    required String price,
    required String period,
    required String badgeText,
    required Color badgeColor,
    required List<String> features,
  }) {
    final isSelected = _selectedPlan == planId;

    return InkWell(
      onTap: () {
        setState(() => _selectedPlan = planId);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3F6DFB).withOpacity(0.03)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFFE5E7EB),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Radio<String>(
                  value: planId,
                  groupValue: _selectedPlan,
                  activeColor: const Color(0xFF3F6DFB),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPlan = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 4),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(color: Color(0xFFE5E7EB), height: 1),
            ),
            Column(
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: isSelected ? const Color(0xFF3F6DFB) : const Color(0xFFA0A5BA),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildNotificationToggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF3F6DFB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
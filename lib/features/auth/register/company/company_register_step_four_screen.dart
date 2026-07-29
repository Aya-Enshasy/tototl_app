import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/session/account_role_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../company/company_shell_screen.dart';

class CompanyRegisterStepFourScreen extends StatefulWidget {
  const CompanyRegisterStepFourScreen({super.key});

  @override
  State<CompanyRegisterStepFourScreen> createState() =>
      _CompanyRegisterStepFourScreenState();
}

class _CompanyRegisterStepFourScreenState
    extends State<CompanyRegisterStepFourScreen> {
  // 'free', 'monthly', 'yearly'
  String _selectedPlan = 'free';
  bool _isLoading = false;

  static const Color kPrimary = AppColors.primary;
  static const Color kTextDark = AppColors.text;
  static const Color kTextMuted = AppColors.grey;
  static const Color kBorder = AppColors.border;
  static const Color kSurfaceSoft = AppColors.bg;

  void _handleCompleteRegistration() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isLoading = false);

    await AccountRoleStore.instance.setRole(AccountRole.company);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CompanyShellScreen()),
      (route) => false,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation Bar
              Row(
                children: [
                  _buildBackButton(),
                  Expanded(
                    child: Center(child: _buildStepIndicator(currentStep: 4)),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
              const SizedBox(height: 30),

              // Title & Subtitle
              const Text(
                'Subscription Plan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: kTextDark,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a plan for your company hiring needs',
                style: TextStyle(
                  fontSize: 14,
                  color: kTextMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),

              // Free / Basic Plan
              _buildPlanCard(
                planId: 'free',
                title: 'Basic Plan',
                price: '\$0',
                period: '/ forever',
                badgeText: 'FREE ACCESS',
                badgeColor: kTextMuted,
                features: const [
                  'Standard pilot search & profiles',
                  'Post up to 2 active job offers',
                  'In-app messaging system',
                ],
              ),
              const SizedBox(height: 14),

              // Monthly Plan
              _buildPlanCard(
                planId: 'monthly',
                title: 'Monthly Plan',
                price: '\$99',
                period: '/ month',
                badgeText: 'MOST FLEXIBLE',
                badgeColor: kPrimary,
                features: const [
                  'AI-powered top pilot matching',
                  'Unlimited active job postings',
                  'Priority direct messaging & calling',
                  'Advanced job site P&ID analysis',
                ],
              ),
              const SizedBox(height: 14),

              // Yearly Plan
              _buildPlanCard(
                planId: 'yearly',
                title: 'Yearly Plan',
                price: '\$948',
                period: '/ year',
                badgeText: 'BEST VALUE · SAVE 20%',
                badgeColor: const Color(0xFF16A34A),
                features: const [
                  'Everything in Monthly Plan',
                  '2 months free (20% savings)',
                  'Dedicated account manager',
                  'Priority customer support',
                ],
              ),
              const SizedBox(height: 32),

              // Complete Registration Button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16C6C7), Color(0xFF0D8AA5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.35),
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Complete Registration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
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
          color: kSurfaceSoft,
          shape: BoxShape.circle,
          border: Border.all(color: kBorder, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
          color: kTextDark,
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
                color: isActive || isPassed ? kPrimary : Colors.white,
                border: Border.all(
                  color: isActive || isPassed ? kPrimary : kBorder,
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
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
              ),
            ),
            if (index < 3)
              Container(
                width: 26,
                height: 2,
                color: isPassed ? kPrimary : kBorder,
              ),
          ],
        );
      }),
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
          color: isSelected ? kPrimary.withOpacity(0.03) : kSurfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimary : kBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                ),
                Radio<String>(
                  value: planId,
                  groupValue: _selectedPlan,
                  activeColor: kPrimary,
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
                    color: kTextDark,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(color: kBorder, height: 1),
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
                        color: isSelected ? kPrimary : const Color(0xFFA0A5BA),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 13,
                            color: kTextDark,
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
}

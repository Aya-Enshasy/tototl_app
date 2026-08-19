import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/session/account_role_store.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../company/company_shell_screen.dart';

// ============================================================================
// COMPANY REGISTRATION - FINAL STEP
// SUBSCRIPTION PLAN
// ============================================================================

class CompanyRegisterStepFourScreen extends StatefulWidget {
  const CompanyRegisterStepFourScreen({
    super.key,
  });

  @override
  State<CompanyRegisterStepFourScreen> createState() =>
      _CompanyRegisterStepFourScreenState();
}

class _CompanyRegisterStepFourScreenState
    extends State<CompanyRegisterStepFourScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // STATE
  // ==========================================================================

  String _selectedPlan = 'free';

  bool _isLoading = false;
  bool _buttonPressed = false;

  // ==========================================================================
  // COLORS
  // ==========================================================================

  static const Color kPrimary =
      AppColors.primary;

  static const Color kTextDark =
      AppColors.text;

  static const Color kTextMuted =
      AppColors.grey;

  static const Color kBorder =
      AppColors.border;

  static const Color kSurfaceSoft =
      AppColors.bg;

  // ==========================================================================
  // ANIMATIONS
  // ==========================================================================

  late final AnimationController
  _pageAnimationController;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        Brightness.dark,
        statusBarBrightness:
        Brightness.light,
      ),
    );

    _pageAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: 1100,
          ),
        );

    _pageAnimationController.forward();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _pageAnimationController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // ENTRANCE ANIMATION
  // ==========================================================================

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start =
    (index * 0.075)
        .clamp(
      0.0,
      0.70,
    )
        .toDouble();

    final end =
    (start + 0.32)
        .clamp(
      0.0,
      1.0,
    )
        .toDouble();

    final animation =
    CurvedAnimation(
      parent: _pageAnimationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(
            0,
            0.055,
          ),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ==========================================================================
  // COMPLETE REGISTRATION
  // ==========================================================================

  Future<void> _handleCompleteRegistration() async {
    if (_isLoading) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    // ==========================================================
    // UI LOADING ONLY - NO API
    // ==========================================================

    await Future.delayed(
      const Duration(
        milliseconds: 700,
      ),
    );

    if (!mounted) return;

    await AccountRoleStore.instance.setRole(
      AccountRole.company,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    HapticFeedback.mediumImpact();

    _showSuccessDialog();
  }

  // ==========================================================================
  // SUCCESS DIALOG
  // ==========================================================================

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel:
      'Registration Complete',
      barrierColor:
      Colors.black.withOpacity(
        0.45,
      ),
      transitionDuration:
      const Duration(
        milliseconds: 420,
      ),
      pageBuilder: (
          context,
          animation,
          secondaryAnimation,
          ) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curved =
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.86,
              end: 1,
            ).animate(
              curved,
            ),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints:
                  const BoxConstraints(
                    maxWidth: 390,
                  ),
                  margin:
                  const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  padding:
                  const EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    22,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      28,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.15,
                        ),
                        blurRadius: 35,
                        offset:
                        const Offset(
                          0,
                          15,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // =========================================
                      // ICON
                      // =========================================

                      Stack(
                        alignment:
                        Alignment.center,
                        children: [
                          Container(
                            width: 94,
                            height: 94,
                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,
                              color: kPrimary
                                  .withOpacity(
                                0.06,
                              ),
                            ),
                          ),

                          Container(
                            width: 72,
                            height: 72,
                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,
                              gradient:
                              const LinearGradient(
                                begin:
                                Alignment.topLeft,
                                end:
                                Alignment.bottomRight,
                                colors: [
                                  Color(
                                    0xFF18B99F,
                                  ),
                                  kPrimary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary
                                      .withOpacity(
                                    0.25,
                                  ),
                                  blurRadius: 18,
                                  offset:
                                  const Offset(
                                    0,
                                    7,
                                  ),
                                ),
                              ],
                            ),
                            child:
                            const Icon(
                              Icons
                                  .business_rounded,
                              color:
                              Colors.white,
                              size: 34,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      const Text(
                        'Company Account Ready!',
                        textAlign:
                        TextAlign.center,
                        style:
                        TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          kTextDark,
                          letterSpacing:
                          -0.3,
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      Text(
                        _successDescription(),
                        textAlign:
                        TextAlign.center,
                        style:
                        const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color:
                          kTextMuted,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // =========================================
                      // SELECTED PLAN
                      // =========================================

                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration:
                        BoxDecoration(
                          color: kPrimary
                              .withOpacity(
                            0.06,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            15,
                          ),
                          border: Border.all(
                            color: kPrimary
                                .withOpacity(
                              0.10,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .workspace_premium_rounded,
                              size: 18,
                              color:
                              kPrimary,
                            ),

                            const SizedBox(
                              width: 9,
                            ),

                            Expanded(
                              child: Text(
                                'Selected Plan: ${_selectedPlanName()}',
                                style:
                                const TextStyle(
                                  color:
                                  kPrimary,
                                  fontSize:
                                  12.5,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // =========================================
                      // DONE
                      // =========================================

                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(
                            25,
                          ),
                          gradient:
                          const LinearGradient(
                            begin:
                            Alignment.centerLeft,
                            end:
                            Alignment.centerRight,
                            colors: [
                              Color(
                                0xFF0D8AA5,
                              ),
                              kPrimary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary
                                  .withOpacity(
                                0.22,
                              ),
                              blurRadius: 16,
                              offset:
                              const Offset(
                                0,
                                6,
                              ),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) =>
                                const CompanyShellScreen(),
                              ),
                                  (route) => false,
                            );
                          },
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.transparent,
                            shadowColor:
                            Colors.transparent,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                25,
                              ),
                            ),
                          ),
                          child:
                          const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                'Go to Dashboard',
                                style:
                                TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize:
                                  14.5,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),

                              SizedBox(
                                width: 7,
                              ),

                              Icon(
                                Icons
                                    .arrow_forward_rounded,
                                color:
                                Colors.white,
                                size: 17,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _selectedPlanName() {
    switch (_selectedPlan) {
      case 'monthly':
        return 'Monthly Plan';

      case 'yearly':
        return 'Yearly Plan';

      default:
        return 'Basic Plan';
    }
  }

  String _successDescription() {
    switch (_selectedPlan) {
      case 'monthly':
        return 'Your company profile is ready with the Monthly Plan selected.';

      case 'yearly':
        return 'Your company profile is ready with the Yearly Plan selected.';

      default:
        return 'Your company profile is ready with the Basic Plan selected.';
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF8FAFB,
      ),
      body: Stack(
        children: [
          // ==================================================================
          // BACKGROUND GLOW
          // ==================================================================

          Positioned(
            top: -125,
            right: -105,
            child: IgnorePointer(
              child: Container(
                width: 285,
                height: 285,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                  RadialGradient(
                    colors: [
                      kPrimary
                          .withOpacity(
                        0.12,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 580,
            left: -165,
            child: IgnorePointer(
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                  RadialGradient(
                    colors: [
                      const Color(
                        0xFF0D8AA5,
                      ).withOpacity(
                        0.045,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==================================================================
          // CONTENT
          // ==================================================================

          SafeArea(
            child: LayoutBuilder(
              builder: (
                  context,
                  constraints,
                  ) {
                return SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    34,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                      const BoxConstraints(
                        maxWidth: 560,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // ================================================
                          // HEADER
                          // ================================================

                          _animatedEntry(
                            index: 0,
                            child:
                            _buildHeader(),
                          ),

                          const SizedBox(
                            height: 26,
                          ),

                          // ================================================
                          // BADGE
                          // ================================================

                          _animatedEntry(
                            index: 1,
                            child:
                            _buildSubscriptionBadge(),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ================================================
                          // TITLE
                          // ================================================

                          _animatedEntry(
                            index: 2,
                            child:
                            const Text(
                              'Choose Your Plan',
                              style:
                              TextStyle(
                                fontSize: 27,
                                fontWeight:
                                FontWeight.w800,
                                color:
                                kTextDark,
                                letterSpacing:
                                -0.6,
                                height: 1.15,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          _animatedEntry(
                            index: 3,
                            child:
                            const Text(
                              'Select the plan that best fits your company hiring and drone service needs.',
                              style:
                              TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color:
                                kTextMuted,
                                fontWeight:
                                FontWeight.w400,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          // ================================================
                          // SECTION HEADER
                          // ================================================

                          _animatedEntry(
                            index: 4,
                            child:
                            _buildSectionHeader(),
                          ),

                          const SizedBox(
                            height: 17,
                          ),

                          // ================================================
                          // BASIC
                          // ================================================

                          _animatedEntry(
                            index: 5,
                            child:
                            _buildPlanCard(
                              planId:
                              'free',
                              icon:
                              Icons.rocket_launch_outlined,
                              title:
                              'Basic Plan',
                              price:
                              '\$0',
                              period:
                              '/ forever',
                              badgeText:
                              'FREE ACCESS',
                              badgeColor:
                              kTextMuted,
                              description:
                              'Start exploring the platform with essential hiring tools.',
                              features:
                              const [
                                'Standard pilot search & profiles',
                                'Post up to 2 active job offers',
                                'In-app messaging system',
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ================================================
                          // MONTHLY
                          // ================================================

                          _animatedEntry(
                            index: 6,
                            child:
                            _buildPlanCard(
                              planId:
                              'monthly',
                              icon:
                              Icons.flash_on_rounded,
                              title:
                              'Monthly Plan',
                              price:
                              '\$99',
                              period:
                              '/ month',
                              badgeText:
                              'MOST FLEXIBLE',
                              badgeColor:
                              kPrimary,
                              description:
                              'Powerful hiring tools with the flexibility of monthly billing.',
                              features:
                              const [
                                'AI-powered top pilot matching',
                                'Unlimited active job postings',
                                'Priority direct messaging & calling',
                                'Advanced job site P&ID analysis',
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ================================================
                          // YEARLY
                          // ================================================

                          _animatedEntry(
                            index: 7,
                            child:
                            _buildPlanCard(
                              planId:
                              'yearly',
                              icon:
                              Icons.workspace_premium_rounded,
                              title:
                              'Yearly Plan',
                              price:
                              '\$948',
                              period:
                              '/ year',
                              badgeText:
                              'BEST VALUE · SAVE 20%',
                              badgeColor:
                              const Color(
                                0xFF16A34A,
                              ),
                              description:
                              'Maximum value and priority support for growing companies.',
                              features:
                              const [
                                'Everything in Monthly Plan',
                                '2 months free (20% savings)',
                                'Dedicated account manager',
                                'Priority customer support',
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          // ================================================
                          // SELECTED SUMMARY
                          // ================================================

                          _animatedEntry(
                            index: 8,
                            child:
                            _buildSelectedPlanSummary(),
                          ),

                          const SizedBox(
                            height: 27,
                          ),

                          // ================================================
                          // BUTTON
                          // ================================================

                          _animatedEntry(
                            index: 9,
                            child:
                            _buildPrimaryButton(
                              text:
                              'Complete Registration',
                              isLoading:
                              _isLoading,
                              onPressed:
                              _isLoading
                                  ? null
                                  : _handleCompleteRegistration,
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          _animatedEntry(
                            index: 10,
                            child:
                            _buildBottomNote(),
                          ),

                          const SizedBox(
                            height: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            _buildBackButton(),

            const Spacer(),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: kBorder,
                ),
              ),
              child:
              const Text(
                'STEP 3 OF 3',
                style:
                TextStyle(
                  fontSize: 10,
                  letterSpacing:
                  0.5,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  kTextMuted,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        // All 3 steps completed/current
        Row(
          children: List.generate(
            3,
                (index) {
              return Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.only(
                    right:
                    index == 2
                        ? 0
                        : 6,
                  ),
                  child:
                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds: 450,
                    ),
                    curve:
                    Curves.easeOutCubic,
                    height: 4,
                    decoration:
                    BoxDecoration(
                      color: kPrimary,
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          kPrimary.withOpacity(
                            0.18,
                          ),
                          blurRadius: 7,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // BACK
  // ==========================================================================

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          50,
        ),
        onTap:
        _isLoading
            ? null
            : () {
          HapticFeedback.selectionClick();

          Navigator.pop(
            context,
          );
        },
        child: Container(
          width: 38,
          height: 38,
          decoration:
          BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black
                  .withOpacity(
                0.045,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(
                  0.035,
                ),
                blurRadius: 9,
                offset:
                const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),
          child:
          const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            size: 13,
            color:
            kTextDark,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BADGE
  // ==========================================================================

  Widget _buildSubscriptionBadge() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        kPrimary.withOpacity(
          0.085,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child:
      const Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons
                .workspace_premium_outlined,
            color:
            kPrimary,
            size: 14,
          ),

          SizedBox(
            width: 6,
          ),

          Text(
            'COMPANY SUBSCRIPTION',
            style:
            TextStyle(
              color: kPrimary,
              fontSize: 10,
              fontWeight:
              FontWeight.w700,
              letterSpacing:
              0.65,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION HEADER
  // ==========================================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
          BoxDecoration(
            color:
            kPrimary.withOpacity(
              0.09,
            ),
            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),
          child:
          const Icon(
            Icons.credit_card_rounded,
            size: 18,
            color:
            kPrimary,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Available Plans',
                style:
                TextStyle(
                  color:
                  kTextDark,
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                'You can change your subscription later',
                style:
                TextStyle(
                  color:
                  kTextMuted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // PLAN CARD
  // ==========================================================================

  Widget _buildPlanCard({
    required String planId,
    required IconData icon,
    required String title,
    required String price,
    required String period,
    required String badgeText,
    required Color badgeColor,
    required String description,
    required List<String> features,
  }) {
    final bool isSelected =
        _selectedPlan ==
            planId;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
        HapticFeedback.selectionClick();

        setState(() {
          _selectedPlan =
              planId;
        });
      },
      child: AnimatedScale(
        duration:
        const Duration(
          milliseconds: 220,
        ),
        curve:
        Curves.easeOutCubic,
        scale:
        isSelected
            ? 1
            : 0.995,
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 280,
          ),
          curve:
          Curves.easeOutCubic,
          width:
          double.infinity,
          padding:
          const EdgeInsets.all(
            18,
          ),
          decoration:
          BoxDecoration(
            color: isSelected
                ? kPrimary.withOpacity(
              0.045,
            )
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
              isSelected
                  ? kPrimary
                  : kBorder,
              width:
              isSelected
                  ? 1.5
                  : 0.8,
            ),
            boxShadow:
            isSelected
                ? [
              BoxShadow(
                color:
                kPrimary.withOpacity(
                  0.09,
                ),
                blurRadius:
                22,
                offset:
                const Offset(
                  0,
                  8,
                ),
              ),
            ]
                : [
              BoxShadow(
                color:
                Colors.black.withOpacity(
                  0.018,
                ),
                blurRadius:
                12,
                offset:
                const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ============================================
              // TOP
              // ============================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds: 250,
                    ),
                    width: 44,
                    height: 44,
                    decoration:
                    BoxDecoration(
                      color: isSelected
                          ? kPrimary.withOpacity(
                        0.11,
                      )
                          : kSurfaceSoft,
                      borderRadius:
                      BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                      isSelected
                          ? kPrimary
                          : kTextMuted,
                      size: 21,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                          TextStyle(
                            color:
                            isSelected
                                ? kPrimary
                                : kTextDark,
                            fontSize: 16.5,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            badgeColor.withOpacity(
                              0.10,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style:
                            TextStyle(
                              color:
                              badgeColor,
                              fontSize: 9.5,
                              fontWeight:
                              FontWeight.w800,
                              letterSpacing:
                              0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds: 220,
                    ),
                    width: 25,
                    height: 25,
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      color:
                      isSelected
                          ? kPrimary
                          : Colors.white,
                      border:
                      Border.all(
                        color:
                        isSelected
                            ? kPrimary
                            : kBorder,
                        width: 1.5,
                      ),
                    ),
                    child:
                    isSelected
                        ? const Icon(
                      Icons.check_rounded,
                      color:
                      Colors.white,
                      size: 15,
                    )
                        : null,
                  ),
                ],
              ),

              const SizedBox(
                height: 17,
              ),

              // ============================================
              // PRICE
              // ============================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style:
                    const TextStyle(
                      color:
                      kTextDark,
                      fontSize: 30,
                      fontWeight:
                      FontWeight.w900,
                      height: 1,
                      letterSpacing:
                      -0.8,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 3,
                    ),
                    child: Text(
                      period,
                      style:
                      const TextStyle(
                        color:
                        kTextMuted,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 9,
              ),

              Text(
                description,
                style:
                const TextStyle(
                  color:
                  kTextMuted,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),

              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 15,
                ),
                child: Divider(
                  height: 1,
                  color: kBorder,
                ),
              ),

              // ============================================
              // FEATURES
              // ============================================

              ...features.map(
                    (
                    feature,
                    ) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 9,
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 19,
                          height: 19,
                          margin:
                          const EdgeInsets.only(
                            top: 1,
                          ),
                          decoration:
                          BoxDecoration(
                            color: isSelected
                                ? kPrimary.withOpacity(
                              0.09,
                            )
                                : kSurfaceSoft,
                            shape:
                            BoxShape.circle,
                          ),
                          child: Icon(
                            Icons
                                .check_rounded,
                            size: 12,
                            color:
                            isSelected
                                ? kPrimary
                                : kTextMuted,
                          ),
                        ),

                        const SizedBox(
                          width: 9,
                        ),

                        Expanded(
                          child: Text(
                            feature,
                            style:
                            const TextStyle(
                              color:
                              kTextDark,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              if (isSelected) ...[
                const SizedBox(
                  height: 5,
                ),

                AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds: 250,
                  ),
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    kPrimary.withOpacity(
                      0.07,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                  const Row(
                    children: [
                      Icon(
                        Icons
                            .check_circle_rounded,
                        color:
                        kPrimary,
                        size: 16,
                      ),

                      SizedBox(
                        width: 7,
                      ),

                      Text(
                        'Selected plan',
                        style:
                        TextStyle(
                          color:
                          kPrimary,
                          fontSize:
                          11,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // SELECTED PLAN SUMMARY
  // ==========================================================================

  Widget _buildSelectedPlanSummary() {
    String price;
    String period;

    switch (_selectedPlan) {
      case 'monthly':
        price = '\$99';
        period = 'per month';
        break;

      case 'yearly':
        price = '\$948';
        period = 'per year';
        break;

      default:
        price = '\$0';
        period = 'forever';
    }

    return AnimatedContainer(
      duration:
      const Duration(
        milliseconds: 300,
      ),
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        kPrimary.withOpacity(
          0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          kPrimary.withOpacity(
            0.12,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
            BoxDecoration(
              color:
              kPrimary.withOpacity(
                0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child:
            const Icon(
              Icons
                  .shopping_bag_outlined,
              color:
              kPrimary,
              size: 18,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPlanName(),
                  style:
                  const TextStyle(
                    color:
                    kTextDark,
                    fontSize:
                    12.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  'Your current selection',
                  style:
                  const TextStyle(
                    color:
                    kTextMuted,
                    fontSize:
                    10.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style:
                const TextStyle(
                  color:
                  kPrimary,
                  fontSize:
                  16,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              Text(
                period,
                style:
                const TextStyle(
                  color:
                  kTextMuted,
                  fontSize:
                  9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BUTTON
  // ==========================================================================

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading =
    false,
  }) {
    return Listener(
      onPointerDown:
          (_) {
        if (onPressed != null &&
            !isLoading) {
          setState(() {
            _buttonPressed = true;
          });
        }
      },
      onPointerUp:
          (_) {
        if (mounted) {
          setState(() {
            _buttonPressed = false;
          });
        }
      },
      onPointerCancel:
          (_) {
        if (mounted) {
          setState(() {
            _buttonPressed = false;
          });
        }
      },
      child: AnimatedScale(
        duration:
        const Duration(
          milliseconds: 120,
        ),
        scale:
        _buttonPressed
            ? 0.975
            : 1,
        child: Container(
          width:
          double.infinity,
          height: 54,
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              28,
            ),
            gradient:
            const LinearGradient(
              begin:
              Alignment.centerLeft,
              end:
              Alignment.centerRight,
              colors: [
                Color(
                  0xFF0D8AA5,
                ),
                kPrimary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                kPrimary.withOpacity(
                  0.27,
                ),
                blurRadius: 20,
                offset:
                const Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed:
            onPressed,
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              Colors.transparent,
              disabledBackgroundColor:
              Colors.transparent,
              shadowColor:
              Colors.transparent,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  28,
                ),
              ),
            ),
            child:
            AnimatedSwitcher(
              duration:
              const Duration(
                milliseconds: 220,
              ),
              child:
              isLoading
                  ? const SizedBox(
                key:
                ValueKey(
                  'loading',
                ),
                width: 23,
                height: 23,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2.4,
                  color:
                  Colors.white,
                ),
              )
                  : Row(
                key:
                const ValueKey(
                  'normal',
                ),
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        14.5,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  const Icon(
                    Icons
                        .check_circle_outline_rounded,
                    color:
                    Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // NOTE
  // ==========================================================================

  Widget _buildBottomNote() {
    return const Center(
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons
                .lock_outline_rounded,
            color:
            kTextMuted,
            size: 12,
          ),

          SizedBox(
            width: 5,
          ),

          Flexible(
            child: Text(
              'You can upgrade or change your plan later.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                kTextMuted,
                fontSize:
                10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
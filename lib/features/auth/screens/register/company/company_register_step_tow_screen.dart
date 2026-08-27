import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/auth/controllers/auth_controller.dart';
import 'package:tototl_app/features/auth/models/CompanyRegisterRequestModel.dart';

import '../../../models/country_model.dart';
import '../../../services/location_service.dart';
import '../../../../../core/session/account_role_store.dart';
import 'company_register_step_four_screen.dart';
import 'company_register_step_three_screen.dart';

// ============================================================================
// COMPANY REGISTRATION - STEP 2
// ============================================================================

class CompanyRegisterStepTwoScreen extends StatefulWidget {
  const CompanyRegisterStepTwoScreen({
    super.key,
    required this.authController,
    required this.draft,
  });

  final AuthController authController;
  final CompanyRegisterRequestModel draft;

  @override
  State<CompanyRegisterStepTwoScreen> createState() =>
      _CompanyRegisterStepTwoScreenState();
}

class _CompanyRegisterStepTwoScreenState
    extends State<CompanyRegisterStepTwoScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // FORM
  // ==========================================================================

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _countryController =
  TextEditingController();

  final TextEditingController _stateController =
  TextEditingController();

  final TextEditingController _cityController =
  TextEditingController();

  final TextEditingController _addressController =
  TextEditingController();

  final TextEditingController _websiteController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  // ==========================================================================
  // LOCATION
  // ==========================================================================

  final LocationService _locationService =
  LocationService();

  List<CountryModel> _countries = [];

  CountryModel? _selectedCountry;

  final Set<String> _selectedWillingRegions = {};

  // ==========================================================================
  // STATE
  // ==========================================================================

  bool _isSubmitting = false;

  bool _isAgreed = false;

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

  static const Color kHint =
      AppColors.lightGrey;

  static const Color kBorder =
      AppColors.border;

  static const Color kSurfaceSoft =
      AppColors.bg;

  static const Color kDanger =
      AppColors.red;

  // ==========================================================================
  // ANIMATION
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

    _loadCountries();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();

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
    (index * 0.065)
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
        ).animate(
          animation,
        ),
        child: child,
      ),
    );
  }

  // ==========================================================================
  // NEXT
  // ==========================================================================

  Future<void> _handleNext() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    final valid =
        _formKey.currentState?.validate() ??
            false;

    if (!valid) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please complete all required fields.',
        isError: true,
      );

      return;
    }

    if (_selectedCountry == null ||
        _selectedWillingRegions.isEmpty) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select at least one operating region.',
        isError: true,
      );

      return;
    }

    if (!_isAgreed) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please agree to the User Contract Agreement & Terms.',
        isError: true,
      );

      return;
    }

    // ========================================================================
    // BUILD THE FINAL COMPANY REQUEST
    // Step 1 data already exists inside widget.draft.
    // Step 2 completes the company profile and operating regions.
    // ========================================================================

    final regions =
    _selectedWillingRegions
        .map(
          (city) =>
          CompanyWorkRegion(
            country:
            _selectedCountry!
                .name,
            state:
            null,
            city:
            city,
          ),
    )
        .toList();

    final updatedDraft =
    widget.draft.copyWith(
      description:
      _descriptionController
          .text
          .trim(),

      country:
      _countryController
          .text
          .trim(),

      state:
      _stateController
          .text
          .trim(),

      city:
      _cityController
          .text
          .trim(),

      address:
      _addressController
          .text
          .trim(),

      website:
      _websiteController
          .text
          .trim()
          .isEmpty
          ? null
          : _websiteController
          .text
          .trim(),

      workRegions:
      regions,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ======================================================================
      // IMPORTANT:
      // THE COMPANY REGISTRATION REQUEST IS SENT HERE IN STEP 2.
      // STEP 3 IS SUBSCRIPTION UI ONLY.
      // ======================================================================

      final response =
      await widget.authController
          .companyRegister(
        request:
        updatedDraft,
      );

      if (!mounted) return;

      if (response == null) {
        HapticFeedback.heavyImpact();

        _showSnack(
          widget.authController
              .errorMessage ??
              'Registration failed. Please try again.',
          isError: true,
        );

        return;
      }

      // The register response has already been processed by AuthController:
      // token + user + role + profile are stored there.
      await AccountRoleStore.instance
          .setRole(
        AccountRole.company,
      );

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      // ======================================================================
      // STEP 3:
      // Subscription is shown AFTER successful registration.
      // No registration API request is sent from the next screen.
      // ======================================================================

      Navigator.of(
        context,
      ).pushReplacement(
        PageRouteBuilder(
          transitionDuration:
          const Duration(
            milliseconds:
            450,
          ),
          reverseTransitionDuration:
          const Duration(
            milliseconds:
            300,
          ),
          pageBuilder: (
              context,
              animation,
              secondaryAnimation,
              ) {
            return const CompanyRegisterStepThreeScreen();
          },
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            final curved =
            CurvedAnimation(
              parent:
              animation,
              curve:
              Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity:
              curved,
              child:
              SlideTransition(
                position:
                Tween<Offset>(
                  begin:
                  const Offset(
                    0.08,
                    0,
                  ),
                  end:
                  Offset.zero,
                ).animate(
                  curved,
                ),
                child:
                child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      HapticFeedback.heavyImpact();

      _showSnack(
        widget.authController
            .errorMessage ??
            'Something went wrong. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting =
          false;
        });
      }
    }
  }

  // ==========================================================================
  // SNACKBAR
  // ==========================================================================

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          elevation: 8,
          margin: const EdgeInsets.all(
            18,
          ),
          backgroundColor:
          isError
              ? const Color(
            0xFFE95C67,
          )
              : const Color(
            0xFF168F8A,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError
                      ? Icons
                      .error_outline_rounded
                      : Icons
                      .check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight:
                    FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
          // BACKGROUND DECORATION
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
            top: 540,
            left: -160,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
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
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
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
                              _buildCompanyBadge(),
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
                                'Company Profile',
                                style:
                                TextStyle(
                                  fontSize: 27,
                                  fontWeight:
                                  FontWeight
                                      .w800,
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
                                'Tell us where your company operates and provide a short professional overview.',
                                style:
                                TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color:
                                  kTextMuted,
                                  fontWeight:
                                  FontWeight
                                      .w400,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ================================================
                            // LOCATION HEADER
                            // ================================================

                            _animatedEntry(
                              index: 4,
                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .location_on_outlined,
                                title:
                                'Company Location',
                                subtitle:
                                'Main business location and address',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            // ================================================
                            // LOCATION FIELDS
                            // ================================================

                            _animatedEntry(
                              index: 5,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller:
                                    _countryController,
                                    hintText:
                                    'Country',
                                    prefixIcon:
                                    Icons.public_rounded,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Country is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _stateController,
                                    hintText:
                                    'State / Province',
                                    prefixIcon:
                                    Icons
                                        .map_outlined,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'State / Province is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _cityController,
                                    hintText:
                                    'City',
                                    prefixIcon:
                                    Icons
                                        .location_city_rounded,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'City is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _addressController,
                                    hintText:
                                    'Company Address',
                                    prefixIcon:
                                    Icons
                                        .home_work_outlined,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Company address is required';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 13,
                            ),

                            _animatedEntry(
                              index: 6,
                              child:
                              _buildTextField(
                                controller:
                                _websiteController,
                                hintText:
                                'Website (optional)',
                                prefixIcon:
                                Icons.language_rounded,
                                keyboardType:
                                TextInputType.url,
                                textInputAction:
                                TextInputAction.next,
                                validator:
                                    (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return null;
                                  }

                                  final uri = Uri.tryParse(
                                    value.trim(),
                                  );

                                  if (uri == null ||
                                      !uri.hasScheme ||
                                      uri.host.isEmpty ||
                                      (uri.scheme != 'http' &&
                                          uri.scheme != 'https')) {
                                    return 'Enter a valid URL including https://';
                                  }

                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(
                              height: 32,
                            ),

                            // ================================================
                            // OPERATING REGIONS
                            // ================================================

                            _animatedEntry(
                              index: 6,
                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .travel_explore_rounded,
                                title:
                                'Operating Regions',
                                subtitle:
                                'Select where your company provides services',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 7,
                              child:
                              _buildRegionSelector(),
                            ),

                            const SizedBox(
                              height: 32,
                            ),

                            // ================================================
                            // COMPANY DESCRIPTION
                            // ================================================

                            _animatedEntry(
                              index: 8,
                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .business_center_outlined,
                                title:
                                'Company Description',
                                subtitle:
                                'Introduce your company to pilots',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 9,
                              child:
                              _buildTextField(
                                controller:
                                _descriptionController,
                                hintText:
                                'Company background, services provided, industry experience...',
                                prefixIcon:
                                Icons
                                    .notes_rounded,
                                keyboardType:
                                TextInputType.multiline,
                                maxLines: 5,
                                textInputAction:
                                TextInputAction
                                    .newline,
                                validator:
                                    (value) {
                                  if (value ==
                                      null ||
                                      value
                                          .trim()
                                          .isEmpty) {
                                    return 'Please describe your company';
                                  }

                                  if (value
                                      .trim()
                                      .length <
                                      20) {
                                    return 'Please add a little more detail';
                                  }

                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(
                              height: 28,
                            ),

                            // ================================================
                            // TERMS
                            // ================================================

                            _animatedEntry(
                              index: 10,
                              child:
                              _buildAgreementSection(),
                            ),

                            const SizedBox(
                              height: 29,
                            ),

                            // ================================================
                            // BUTTON
                            // ================================================

                            _animatedEntry(
                              index: 11,
                              child:
                              _buildPrimaryButton(
                                text: 'Create Account',
                                isLoading:
                                _isSubmitting,
                                onPressed:
                                _isSubmitting
                                    ? null
                                    : _handleNext,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _animatedEntry(
                              index: 12,
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
              const EdgeInsets
                  .symmetric(
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
                'STEP 2 OF 3',
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

        Row(
          children: List.generate(
            3,
                (index) {
              final active =
                  index <= 1;

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
                      milliseconds:
                      450,
                    ),
                    curve:
                    Curves.easeOutCubic,
                    height: 4,
                    decoration:
                    BoxDecoration(
                      color: active
                          ? kPrimary
                          : kBorder,
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                      boxShadow:
                      active
                          ? [
                        BoxShadow(
                          color:
                          kPrimary.withOpacity(
                            0.18,
                          ),
                          blurRadius:
                          7,
                        ),
                      ]
                          : [],
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
  // BADGE
  // ==========================================================================

  Widget _buildCompanyBadge() {
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
            Icons.apartment_rounded,
            size: 14,
            color: kPrimary,
          ),

          SizedBox(
            width: 6,
          ),

          Text(
            'COMPANY ONBOARDING',
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
          child: Icon(
            icon,
            size: 18,
            color: kPrimary,
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
                title,
                style:
                const TextStyle(
                  color: kTextDark,
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                subtitle,
                maxLines: 2,
                style:
                const TextStyle(
                  color: kTextMuted,
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
  // BACK BUTTON
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
        _isSubmitting
            ? null
            : () {
          HapticFeedback
              .selectionClick();

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
            color: kTextDark,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TEXT FIELD
  // ==========================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType keyboardType =
        TextInputType.text,
    TextInputAction? textInputAction,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled:
      !_isSubmitting ||
          readOnly,
      readOnly: readOnly,
      obscureText:
      obscureText,
      // Flutter requires multiline keyboard when using
      // TextInputAction.newline on a multiline field.
      keyboardType:
      maxLines > 1
          ? TextInputType.multiline
          : keyboardType,
      textInputAction:
      textInputAction,
      onTap: onTap,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode:
      AutovalidateMode
          .onUserInteraction,
      style:
      const TextStyle(
        fontSize: 13.5,
        color: kTextDark,
        fontWeight:
        FontWeight.w500,
      ),
      decoration:
      InputDecoration(
        hintText: hintText,

        hintMaxLines:
        maxLines > 1
            ? 3
            : 1,

        hintStyle:
        const TextStyle(
          color: kHint,
          fontSize: 13,
          height: 1.35,
          fontWeight:
          FontWeight.w400,
        ),

        prefixIcon:
        prefixIcon == null
            ? null
            : Padding(
          padding:
          EdgeInsets.only(
            bottom:
            maxLines > 1
                ? 70
                : 0,
          ),
          child: Icon(
            prefixIcon,
            size: 18,
            color: kHint,
          ),
        ),

        suffixIcon:
        suffixIcon,

        filled: true,

        fillColor:
        Colors.white,

        errorStyle:
        const TextStyle(
          color: kDanger,
          fontSize: 10.5,
          height: 1.2,
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          borderSide:
          const BorderSide(
            color: kBorder,
            width: 0.8,
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          borderSide:
          const BorderSide(
            color: kBorder,
            width: 0.8,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          borderSide:
          const BorderSide(
            color: kPrimary,
            width: 1.4,
          ),
        ),

        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          borderSide:
          const BorderSide(
            color: kDanger,
            width: 1,
          ),
        ),

        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          borderSide:
          const BorderSide(
            color: kDanger,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // OPERATING REGION SELECTOR
  // ==========================================================================

  Widget _buildRegionSelector() {
    final hasRegions =
        _selectedCountry != null &&
            _selectedWillingRegions
                .isNotEmpty;

    return InkWell(
      onTap:
      _countries.isEmpty ||
          _isSubmitting
          ? null
          : _showCountryAndRegionsPicker,
      borderRadius:
      BorderRadius.circular(
        15,
      ),
      child:
      AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 220,
        ),
        width:
        double.infinity,
        constraints:
        const BoxConstraints(
          minHeight: 56,
        ),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          border:
          Border.all(
            color: hasRegions
                ? kPrimary
                .withOpacity(
              0.50,
            )
                : kBorder,
            width: hasRegions
                ? 1.1
                : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons
                  .travel_explore_rounded,
              size: 19,
              color: hasRegions
                  ? kPrimary
                  : kHint,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: !hasRegions
                  ? const Text(
                'Select country and operating regions',
                style:
                TextStyle(
                  fontSize: 13,
                  color: kHint,
                ),
              )
                  : Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    _selectedCountry!
                        .name,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 10.5,
                      color:
                      kTextMuted,
                      fontWeight:
                      FontWeight
                          .w500,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._selectedWillingRegions
                          .take(3)
                          .map(
                            (
                            region,
                            ) =>
                            _buildRegionChip(
                              region,
                            ),
                      ),

                      if (_selectedWillingRegions
                          .length >
                          3)
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            8,
                            vertical:
                            4,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            kPrimary.withOpacity(
                              0.09,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              20,
                            ),
                          ),
                          child:
                          Text(
                            '+${_selectedWillingRegions.length - 3}',
                            style:
                            const TextStyle(
                              color:
                              kPrimary,
                              fontSize:
                              10.5,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color: kHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionChip(
      String region,
      ) {
    return Container(
      constraints:
      const BoxConstraints(
        maxWidth: 145,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color:
        kPrimary.withOpacity(
          0.09,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        region,
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style:
        const TextStyle(
          fontSize: 10.5,
          color: kPrimary,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================================
  // COUNTRY + REGIONS SHEET
  // ==========================================================================

  void _showCountryAndRegionsPicker() {
    HapticFeedback.lightImpact();

    CountryModel? tempCountry =
        _selectedCountry;

    final Set<String>
    tempSelectedCities =
    Set<String>.from(
      _selectedWillingRegions,
    );

    String searchQuery =
        '';

    showModalBottomSheet(
      context: context,
      isScrollControlled:
      true,
      backgroundColor:
      Colors.transparent,
      builder:
          (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            final List<String>
            allCities =
                tempCountry?.cities ??
                    [];

            final query =
            searchQuery
                .trim()
                .toLowerCase();

            final List<String>
            filteredCities =
            allCities.where(
                  (
                  city,
                  ) {
                if (query
                    .isEmpty) {
                  return true;
                }

                return city
                    .toLowerCase()
                    .contains(
                  query,
                );
              },
            ).toList();

            return SafeArea(
              child:
              FractionallySizedBox(
                heightFactor:
                0.88,
                child:
                Container(
                  decoration:
                  const BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius.vertical(
                      top:
                      Radius.circular(
                        28,
                      ),
                    ),
                  ),
                  child:
                  Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),

                      Container(
                        width: 42,
                        height: 4,
                        decoration:
                        BoxDecoration(
                          color: kBorder,
                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ====================================================
                      // HEADER
                      // ====================================================

                      Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          18,
                        ),
                        child:
                        Row(
                          children: [
                            const Expanded(
                              child:
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Operating Regions',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      18,
                                      fontWeight:
                                      FontWeight.w800,
                                      color:
                                      kTextDark,
                                    ),
                                  ),

                                  SizedBox(
                                    height: 2,
                                  ),

                                  Text(
                                    'Choose a country and cities where your company operates',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      11.5,
                                      color:
                                      kTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed:
                                  () {
                                Navigator.pop(
                                  context,
                                );
                              },
                              icon:
                              const Icon(
                                Icons.close_rounded,
                                color:
                                kHint,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ====================================================
                      // COUNTRY
                      // ====================================================

                      Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          18,
                        ),
                        child:
                        DropdownButtonFormField<
                            CountryModel>(
                          value:
                          tempCountry,
                          isExpanded:
                          true,
                          menuMaxHeight:
                          350,
                          decoration:
                          InputDecoration(
                            hintText:
                            'Select Country',
                            prefixIcon:
                            const Icon(
                              Icons.public_rounded,
                              size: 19,
                              color:
                              kHint,
                            ),
                            filled:
                            true,
                            fillColor:
                            const Color(
                              0xFFF8FAFB,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                15,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                kBorder,
                              ),
                            ),
                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                15,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                kBorder,
                              ),
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                15,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                kPrimary,
                                width:
                                1.3,
                              ),
                            ),
                          ),
                          items:
                          _countries.map(
                                (
                                country,
                                ) {
                              return DropdownMenuItem<
                                  CountryModel>(
                                value:
                                country,
                                child:
                                Text(
                                  country.name,
                                  maxLines:
                                  1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                              (
                              country,
                              ) {
                            HapticFeedback
                                .selectionClick();

                            setSheetState(
                                  () {
                                tempCountry =
                                    country;

                                tempSelectedCities
                                    .clear();

                                searchQuery =
                                '';
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ====================================================
                      // CITIES
                      // ====================================================

                      Expanded(
                        child:
                        tempCountry ==
                            null
                            ? _buildEmptyRegionState(
                          icon:
                          Icons.public_rounded,
                          title:
                          'Choose a country',
                          subtitle:
                          'Cities will appear after selecting a country.',
                        )
                            : allCities
                            .isEmpty
                            ? _buildEmptyRegionState(
                          icon:
                          Icons.location_off_outlined,
                          title:
                          'No cities available',
                          subtitle:
                          'No city data is available for this country.',
                        )
                            : Column(
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal:
                                18,
                              ),
                              child:
                              TextField(
                                onChanged:
                                    (
                                    value,
                                    ) {
                                  setSheetState(
                                        () {
                                      searchQuery =
                                          value;
                                    },
                                  );
                                },
                                decoration:
                                InputDecoration(
                                  hintText:
                                  'Search city...',
                                  hintStyle:
                                  const TextStyle(
                                    color:
                                    kHint,
                                    fontSize:
                                    13,
                                  ),
                                  prefixIcon:
                                  const Icon(
                                    Icons.search_rounded,
                                    color:
                                    kHint,
                                    size:
                                    20,
                                  ),
                                  filled:
                                  true,
                                  fillColor:
                                  const Color(
                                    0xFFF7F9FA,
                                  ),
                                  border:
                                  OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                      14,
                                    ),
                                    borderSide:
                                    BorderSide.none,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal:
                                18,
                              ),
                              child:
                              Row(
                                children: [
                                  Text(
                                    '${filteredCities.length} cities',
                                    style:
                                    const TextStyle(
                                      color:
                                      kTextMuted,
                                      fontSize:
                                      11,
                                    ),
                                  ),

                                  const Spacer(),

                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal:
                                      9,
                                      vertical:
                                      5,
                                    ),
                                    decoration:
                                    BoxDecoration(
                                      color: tempSelectedCities
                                          .isEmpty
                                          ? kSurfaceSoft
                                          : kPrimary.withOpacity(
                                        0.09,
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child:
                                    Text(
                                      '${tempSelectedCities.length} selected',
                                      style:
                                      TextStyle(
                                        color: tempSelectedCities
                                            .isEmpty
                                            ? kTextMuted
                                            : kPrimary,
                                        fontSize:
                                        10.5,
                                        fontWeight:
                                        FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            Expanded(
                              child:
                              filteredCities
                                  .isEmpty
                                  ? const Center(
                                child:
                                Text(
                                  'No cities found',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    13,
                                    color:
                                    kTextMuted,
                                  ),
                                ),
                              )
                                  : ListView.separated(
                                keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount:
                                filteredCities.length,
                                separatorBuilder:
                                    (
                                    context,
                                    index,
                                    ) {
                                  return const Divider(
                                    height:
                                    1,
                                    indent:
                                    18,
                                    endIndent:
                                    18,
                                    color:
                                    kBorder,
                                  );
                                },
                                itemBuilder:
                                    (
                                    context,
                                    index,
                                    ) {
                                  final city =
                                  filteredCities[index];

                                  final selected =
                                  tempSelectedCities.contains(
                                    city,
                                  );

                                  return InkWell(
                                    onTap:
                                        () {
                                      HapticFeedback.selectionClick();

                                      setSheetState(
                                            () {
                                          if (selected) {
                                            tempSelectedCities.remove(
                                              city,
                                            );
                                          } else {
                                            tempSelectedCities.add(
                                              city,
                                            );
                                          }
                                        },
                                      );
                                    },
                                    child:
                                    Padding(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal:
                                        18,
                                        vertical:
                                        13,
                                      ),
                                      child:
                                      Row(
                                        children: [
                                          AnimatedContainer(
                                            duration:
                                            const Duration(
                                              milliseconds:
                                              180,
                                            ),
                                            width:
                                            22,
                                            height:
                                            22,
                                            decoration:
                                            BoxDecoration(
                                              color: selected
                                                  ? kPrimary
                                                  : Colors.white,
                                              borderRadius:
                                              BorderRadius.circular(
                                                7,
                                              ),
                                              border:
                                              Border.all(
                                                color: selected
                                                    ? kPrimary
                                                    : kBorder,
                                              ),
                                            ),
                                            child: selected
                                                ? const Icon(
                                              Icons.check_rounded,
                                              color:
                                              Colors.white,
                                              size:
                                              14,
                                            )
                                                : null,
                                          ),

                                          const SizedBox(
                                            width:
                                            12,
                                          ),

                                          Expanded(
                                            child:
                                            Text(
                                              city,
                                              style:
                                              TextStyle(
                                                color: selected
                                                    ? kPrimary
                                                    : kTextDark,
                                                fontSize:
                                                13.5,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
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

                      // ====================================================
                      // DONE BUTTON
                      // ====================================================

                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(
                          18,
                          10,
                          18,
                          18,
                        ),
                        child:
                        SizedBox(
                          width:
                          double.infinity,
                          height:
                          50,
                          child:
                          ElevatedButton(
                            onPressed:
                            tempCountry ==
                                null
                                ? null
                                : () {
                              HapticFeedback.mediumImpact();

                              setState(
                                    () {
                                  _selectedCountry =
                                      tempCountry;

                                  _selectedWillingRegions
                                    ..clear()
                                    ..addAll(
                                      tempSelectedCities,
                                    );
                                },
                              );

                              Navigator.pop(
                                context,
                              );
                            },
                            style:
                            ElevatedButton.styleFrom(
                              elevation:
                              0,
                              backgroundColor:
                              kPrimary,
                              disabledBackgroundColor:
                              kBorder,
                              foregroundColor:
                              Colors.white,
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  25,
                                ),
                              ),
                            ),
                            child:
                            Text(
                              tempSelectedCities
                                  .isEmpty
                                  ? 'Done'
                                  : 'Done • ${tempSelectedCities.length} Selected',
                              style:
                              const TextStyle(
                                fontSize:
                                13.5,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyRegionState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration:
              BoxDecoration(
                color:
                kPrimary.withOpacity(
                  0.07,
                ),
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 25,
                color:
                kPrimary,
              ),
            ),

            const SizedBox(
              height: 13,
            ),

            Text(
              title,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                kTextDark,
                fontSize:
                14,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              subtitle,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                kTextMuted,
                fontSize:
                11.5,
                height:
                1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // AGREEMENT
  // ==========================================================================

  Widget _buildAgreementSection() {
    return AnimatedContainer(
      duration:
      const Duration(
        milliseconds: 220,
      ),
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _isAgreed
            ? kPrimary.withOpacity(
          0.055,
        )
            : Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          _isAgreed
              ? kPrimary.withOpacity(
            0.38,
          )
              : kBorder,
          width:
          _isAgreed
              ? 1.1
              : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
              value:
              _isAgreed,
              activeColor:
              kPrimary,
              checkColor:
              Colors.white,
              side:
              const BorderSide(
                color:
                kBorder,
                width:
                1.3,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  7,
                ),
              ),
              onChanged:
              _isSubmitting
                  ? null
                  : (value) {
                HapticFeedback.selectionClick();

                setState(() {
                  _isAgreed =
                      value ??
                          false;
                });
              },
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'User Agreement',
                  style:
                  TextStyle(
                    color:
                    kTextDark,
                    fontSize:
                    12.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Wrap(
                  crossAxisAlignment:
                  WrapCrossAlignment
                      .center,
                  children: [
                    const Text(
                      'I agree to the ',
                      style:
                      TextStyle(
                        color:
                        kTextMuted,
                        fontSize:
                        11.5,
                        height:
                        1.45,
                      ),
                    ),

                    GestureDetector(
                      onTap:
                      _showTermsAndConditionsSheet,
                      child:
                      const Text(
                        'User Contract Agreement & Terms',
                        style:
                        TextStyle(
                          color:
                          kPrimary,
                          fontSize:
                          11.5,
                          height:
                          1.45,
                          fontWeight:
                          FontWeight.w700,
                          decoration:
                          TextDecoration.underline,
                          decorationColor:
                          kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TERMS SHEET
  // ==========================================================================

  Future<void> _showTermsAndConditionsSheet() async {
    HapticFeedback.lightImpact();

    await showModalBottomSheet(
      context:
      context,
      isScrollControlled:
      true,
      backgroundColor:
      Colors.transparent,
      builder:
          (context) {
        return DraggableScrollableSheet(
          initialChildSize:
          0.78,
          minChildSize:
          0.50,
          maxChildSize:
          0.93,
          expand:
          false,
          builder:
              (
              context,
              scrollController,
              ) {
            return Material(
              color:
              Colors.white,
              surfaceTintColor:
              Colors.transparent,
              borderRadius:
              const BorderRadius.vertical(
                top:
                Radius.circular(
                  28,
                ),
              ),
              child:
              Column(
                children: [
                  const SizedBox(
                    height:
                    10,
                  ),

                  Container(
                    width:
                    42,
                    height:
                    4,
                    decoration:
                    BoxDecoration(
                      color:
                      kBorder,
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height:
                    18,
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal:
                      20,
                    ),
                    child:
                    Row(
                      children: [
                        Container(
                          width:
                          38,
                          height:
                          38,
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
                            Icons.gavel_rounded,
                            color:
                            kPrimary,
                            size:
                            18,
                          ),
                        ),

                        const SizedBox(
                          width:
                          11,
                        ),

                        const Expanded(
                          child:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Contract Agreement',
                                style:
                                TextStyle(
                                  color:
                                  kTextDark,
                                  fontSize:
                                  17,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),

                              SizedBox(
                                height:
                                2,
                              ),

                              Text(
                                'Terms & Conditions',
                                style:
                                TextStyle(
                                  fontSize:
                                  10.5,
                                  color:
                                  kTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed:
                              () {
                            Navigator.pop(
                              context,
                            );
                          },
                          icon:
                          const Icon(
                            Icons.close_rounded,
                            color:
                            kHint,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:
                    14,
                  ),

                  const Divider(
                    height:
                    1,
                    color:
                    kBorder,
                  ),

                  Expanded(
                    child:
                    SingleChildScrollView(
                      controller:
                      scrollController,
                      padding:
                      const EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        30,
                      ),
                      child:
                      Column(
                        children: [
                          _buildTermsItem(
                            number:
                            '01',
                            title:
                            'Acceptance of Terms',
                            body:
                            'By creating a company account on this platform, you agree to be bound by these Terms & Conditions and our User Contract Agreement.',
                          ),

                          _buildTermsItem(
                            number:
                            '02',
                            title:
                            'Company Responsibilities',
                            body:
                            'Your company agrees to provide accurate information, comply with local aviation regulations, and ensure all posted jobs meet safety standards.',
                          ),

                          _buildTermsItem(
                            number:
                            '03',
                            title:
                            'Pilot Engagement',
                            body:
                            'All engagements with pilots through the platform must follow the agreed scope of work, payment terms, and safety protocols outlined in each job listing.',
                          ),

                          _buildTermsItem(
                            number:
                            '04',
                            title:
                            'Payments & Subscriptions',
                            body:
                            'Subscription fees are billed according to the plan selected and are non-refundable except as required by law.',
                          ),

                          _buildTermsItem(
                            number:
                            '05',
                            title:
                            'Data & Privacy',
                            body:
                            'We collect and process data in accordance with our Privacy Policy to match companies with qualified drone pilots.',
                          ),

                          _buildTermsItem(
                            number:
                            '06',
                            title:
                            'Limitation of Liability',
                            body:
                            'The platform acts as an intermediary and is not liable for damages arising from services performed by independent pilots.',
                          ),

                          _buildTermsItem(
                            number:
                            '07',
                            title:
                            'Termination',
                            body:
                            'We reserve the right to suspend or terminate accounts that violate these terms or engage in fraudulent activity.',
                          ),

                          _buildTermsItem(
                            number:
                            '08',
                            title:
                            'Governing Law',
                            body:
                            'These terms are governed by the laws of the jurisdiction in which the platform operates.',
                            showDivider:
                            false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      18,
                      10,
                      18,
                      18,
                    ),
                    child:
                    SizedBox(
                      width:
                      double.infinity,
                      height:
                      48,
                      child:
                      ElevatedButton(
                        onPressed:
                            () {
                          Navigator.pop(
                            context,
                          );
                        },
                        style:
                        ElevatedButton.styleFrom(
                          elevation:
                          0,
                          backgroundColor:
                          kPrimary,
                          foregroundColor:
                          Colors.white,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                          ),
                        ),
                        child:
                        const Text(
                          'I Understand',
                          style:
                          TextStyle(
                            fontSize:
                            13.5,
                            fontWeight:
                            FontWeight.w700,
                          ),
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

  Widget _buildTermsItem({
    required String number,
    required String title,
    required String body,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment:
              Alignment.center,
              decoration:
              BoxDecoration(
                color:
                kPrimary.withOpacity(
                  0.075,
                ),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: Text(
                number,
                style:
                const TextStyle(
                  color:
                  kPrimary,
                  fontSize:
                  10.5,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(
              width:
              12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    title,
                    style:
                    const TextStyle(
                      color:
                      kTextDark,
                      fontSize:
                      13.5,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height:
                    5,
                  ),

                  Text(
                    body,
                    style:
                    const TextStyle(
                      color:
                      kTextMuted,
                      fontSize:
                      12,
                      height:
                      1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (showDivider)
          const Padding(
            padding:
            EdgeInsets.symmetric(
              vertical:
              15,
            ),
            child:
            Divider(
              height:
              1,
              color:
              kBorder,
            ),
          ),
      ],
    );
  }

  // ==========================================================================
  // PRIMARY BUTTON
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
        if (onPressed !=
            null &&
            !isLoading) {
          setState(() {
            _buttonPressed =
            true;
          });
        }
      },
      onPointerUp:
          (_) {
        if (mounted) {
          setState(() {
            _buttonPressed =
            false;
          });
        }
      },
      onPointerCancel:
          (_) {
        if (mounted) {
          setState(() {
            _buttonPressed =
            false;
          });
        }
      },
      child:
      AnimatedScale(
        duration:
        const Duration(
          milliseconds:
          120,
        ),
        scale:
        _buttonPressed
            ? 0.975
            : 1,
        child:
        Container(
          width:
          double.infinity,
          height:
          54,
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
                blurRadius:
                20,
                offset:
                const Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child:
          ElevatedButton(
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
                milliseconds:
                220,
              ),
              child:
              isLoading
                  ? const SizedBox(
                key:
                ValueKey(
                  'loading',
                ),
                width:
                23,
                height:
                23,
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
                  Text(
                    text,
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize:
                      15,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width:
                    7,
                  ),

                  const Icon(
                    Icons.arrow_forward_rounded,
                    color:
                    Colors.white,
                    size:
                    17,
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
  // BOTTOM NOTE
  // ==========================================================================

  Widget _buildBottomNote() {
    return const Center(
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: kTextMuted,
          ),

          SizedBox(
            width: 5,
          ),

          Flexible(
            child: Text(
              'Your company information is securely protected',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize:
                10.5,
                color:
                kTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // LOAD COUNTRIES
  // ==========================================================================

  Future<void> _loadCountries() async {
    try {
      final countries =
      await _locationService
          .getCountries();

      if (!mounted) {
        return;
      }

      setState(() {
        _countries =
            countries;

        // لا نختار Afghanistan تلقائياً
        _selectedCountry =
        null;

        _selectedWillingRegions
            .clear();
      });

      debugPrint(
        'Countries loaded: ${_countries.length}',
      );
    } catch (e) {
      debugPrint(
        'Failed to load countries: $e',
      );
    }
  }
}

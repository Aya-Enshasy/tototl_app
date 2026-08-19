import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/auth/controllers/auth_controller.dart';
import 'package:tototl_app/features/auth/screens/register/pilot/pilot_register_step_three_screen.dart';
import '../../../models/PilotRegisterRequestModel.dart';
import '../../../models/country_model.dart';
import '../../../services/location_service.dart';

// ============================================================================
// SCREEN 2: Pilot Experience & Work Details
// ============================================================================

class PilotRegisterStepTwoScreen extends StatefulWidget {
  const PilotRegisterStepTwoScreen({
    super.key,
    required this.authController,
    required this.draft,
  });

  final AuthController authController;
  final PilotRegisterRequestModel draft;

  @override
  State<PilotRegisterStepTwoScreen> createState() =>
      _PilotRegisterStepTwoScreenState();
}

class _PilotRegisterStepTwoScreenState
    extends State<PilotRegisterStepTwoScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // FORM
  // ==========================================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _countryController =
  TextEditingController();

  final TextEditingController _stateController =
  TextEditingController();

  final TextEditingController _cityController =
  TextEditingController();

  final TextEditingController _aboutController =
  TextEditingController();

  final TextEditingController _otherLanguageController =
  TextEditingController();

  final TextEditingController _previousCompanyController =
  TextEditingController();

  // ==========================================================================
  // STATE
  // ==========================================================================

  String? _yearsOfExperience;

  final Set<String> _selectedLanguages = {
    'English',
    'Arabic',
  };

  bool _isSubmitting = false;
  bool _buttonPressed = false;

  // ==========================================================================
  // LOCATION
  // ==========================================================================

  final LocationService _locationService =
  LocationService();

  List<CountryModel> _countries = [];

  CountryModel? _selectedCountry;

  final Set<String> _selectedWillingRegions = {};

  // ==========================================================================
  // OPTIONS
  // ==========================================================================

  final List<String> _experienceYears = [
    'Less than 1 year',
    ...List.generate(
      40,
          (index) {
        final years = index + 1;
        return '$years ${years == 1 ? 'year' : 'years'}';
      },
    ),
  ];

  final List<String> _availableLanguages = const [
    'English',
    'Arabic',
    'French',
    'Spanish',
    'Other',
  ];

  // ==========================================================================
  // COLORS
  // ==========================================================================

  static const Color kPrimary =
      AppColors.primary;

  static const Color kPrimarySoft =
      AppColors.blueBg;

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

  late final AnimationController _pageAnimationController;

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
          duration:
          const Duration(milliseconds: 1100),
        );

    _pageAnimationController.forward();

    _loadCountries();
  }

  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _aboutController.dispose();
    _otherLanguageController.dispose();
    _previousCompanyController.dispose();

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
    final double start =
    (index * 0.07)
        .clamp(0.0, 0.70)
        .toDouble();

    final double end =
    (start + 0.30)
        .clamp(0.0, 1.0)
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
          begin:
          const Offset(0, 0.055),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ==========================================================================
  // VALIDATION + NEXT
  // ==========================================================================

  int _experienceYearsForApi() {
    final value = _yearsOfExperience;

    if (value == null ||
        value == 'Less than 1 year') {
      return 0;
    }

    return int.tryParse(
      value.split(' ').first,
    ) ??
        0;
  }

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

    if (_yearsOfExperience == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select your years of experience.',
        isError: true,
      );

      return;
    }

    if (_selectedLanguages.isEmpty) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select at least one language.',
        isError: true,
      );

      return;
    }

    if (_selectedLanguages.contains('Other') &&
        _otherLanguageController.text
            .trim()
            .isEmpty) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please specify the other language.',
        isError: true,
      );

      return;
    }

    if (_selectedWillingRegions.isEmpty) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select at least one region you are willing to work in.',
        isError: true,
      );

      return;
    }

    if (_selectedCountry == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select a work-region country.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final languages =
    _selectedLanguages
        .where(
          (language) =>
      language != 'Other',
    )
        .toList();

    if (_selectedLanguages.contains(
      'Other',
    )) {
      languages.add(
        _otherLanguageController.text
            .trim(),
      );
    }

    final workRegions =
    _selectedWillingRegions
        .map(
          (city) =>
          PilotWorkRegion(
            country:
            _selectedCountry!.name,
            // The current UI chooses country + city for willing regions.
            // It does not collect a separate state for each region.
            state: null,
            city: city,
          ),
    )
        .toList();

    final updatedDraft =
    widget.draft.copyWith(
      experienceYears:
      _experienceYearsForApi(),
      languages:
      languages,
      currentCountry:
      _countryController.text.trim(),
      currentState:
      _stateController.text.trim(),
      currentCity:
      _cityController.text.trim(),
      workRegions:
      workRegions,
      previousCompany:
      _previousCompanyController.text
          .trim()
          .isEmpty
          ? null
          : _previousCompanyController.text
          .trim(),
      bio:
      _aboutController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
        const Duration(
          milliseconds: 450,
        ),
        reverseTransitionDuration:
        const Duration(
          milliseconds: 300,
        ),
        pageBuilder: (
            context,
            animation,
            secondaryAnimation,
            ) {
          return PilotRegisterStepThreeScreen(
            authController:
            widget.authController,
            draft:
            updatedDraft,
          );
        },
        transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
            ) {
          final curved =
          CurvedAnimation(
            parent: animation,
            curve:
            Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
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
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SNACKBAR
  // ==========================================================================

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,

          elevation: 8,

          margin:
          const EdgeInsets.all(18),

          backgroundColor: isError
              ? const Color(0xFFE95C67)
              : const Color(0xFF168F8A),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16),
          ),

          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.15),
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

              const SizedBox(width: 11),

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF8FAFB),

      body: Stack(
        children: [
          // ==================================================================
          // BACKGROUND GLOW
          // ==================================================================

          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                  RadialGradient(
                    colors: [
                      kPrimary.withOpacity(
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
            top: 500,
            left: -150,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
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
                              _buildExperienceBadge(),
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
                                'Pilot Experience',
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
                                'Tell us about your experience, skills, location and preferred work regions.',
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
                              height: 30,
                            ),

                            // ================================================
                            // EXPERIENCE SECTION
                            // ================================================

                            _animatedEntry(
                              index: 4,
                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .workspace_premium_outlined,
                                title:
                                'Experience & Skills',
                                subtitle:
                                'Your professional background',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 5,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  _buildSmallLabel(
                                    'Years of Experience',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildSelectField(
                                    hintText:
                                    'Select Experience Level',
                                    icon: Icons
                                        .workspace_premium_outlined,
                                    value:
                                    _yearsOfExperience,
                                    items:
                                    _experienceYears,
                                    onChanged:
                                        (value) {
                                      setState(
                                            () {
                                          _yearsOfExperience =
                                              value;
                                        },
                                      );
                                    },
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  _buildSmallLabel(
                                    'Languages',
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  _buildMultiSelectChips(
                                    options:
                                    _availableLanguages,
                                    selectedItems:
                                    _selectedLanguages,
                                    onToggle:
                                        (language) {
                                      HapticFeedback
                                          .selectionClick();

                                      setState(
                                            () {
                                          if (_selectedLanguages
                                              .contains(
                                            language,
                                          )) {
                                            _selectedLanguages
                                                .remove(
                                              language,
                                            );
                                          } else {
                                            _selectedLanguages
                                                .add(
                                              language,
                                            );
                                          }

                                          if (!_selectedLanguages
                                              .contains(
                                            'Other',
                                          )) {
                                            _otherLanguageController
                                                .clear();
                                          }
                                        },
                                      );
                                    },
                                  ),

                                  AnimatedSwitcher(
                                    duration:
                                    const Duration(
                                      milliseconds:
                                      280,
                                    ),

                                    switchInCurve:
                                    Curves
                                        .easeOutCubic,

                                    switchOutCurve:
                                    Curves.easeIn,

                                    transitionBuilder:
                                        (
                                        child,
                                        animation,
                                        ) {
                                      return FadeTransition(
                                        opacity:
                                        animation,
                                        child:
                                        SizeTransition(
                                          sizeFactor:
                                          animation,
                                          axisAlignment:
                                          -1,
                                          child:
                                          child,
                                        ),
                                      );
                                    },

                                    child: _selectedLanguages
                                        .contains(
                                      'Other',
                                    )
                                        ? Padding(
                                      key:
                                      const ValueKey(
                                        'other-language',
                                      ),
                                      padding:
                                      const EdgeInsets.only(
                                        top: 13,
                                      ),
                                      child:
                                      _buildTextField(
                                        controller:
                                        _otherLanguageController,
                                        hintText:
                                        'Specify Other Language',
                                        prefixIcon:
                                        Icons.translate_rounded,
                                        validator:
                                            (value) {
                                          if (_selectedLanguages
                                              .contains(
                                            'Other',
                                          ) &&
                                              (value ==
                                                  null ||
                                                  value
                                                      .trim()
                                                      .isEmpty)) {
                                            return 'Language is required';
                                          }

                                          return null;
                                        },
                                      ),
                                    )
                                        : const SizedBox.shrink(
                                      key:
                                      ValueKey(
                                        'no-other-language',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ================================================
                            // CURRENT LOCATION SECTION
                            // ================================================

                            _animatedEntry(
                              index: 6,
                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .location_on_outlined,
                                title:
                                'Current Location',
                                subtitle:
                                'Your main working location',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 7,
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
                                    'State / Region',
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
                                        return 'State / Region is required';
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
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ================================================
                            // WORK PREFERENCES
                            // ================================================

                            _animatedEntry(
                              index: 8,
                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .travel_explore_rounded,
                                title:
                                'Work Preferences',
                                subtitle:
                                'Where you are willing to work',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 9,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  _buildSmallLabel(
                                    'Regions Willing To Work',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildRegionSelector(),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ================================================
                            // PROFESSIONAL BACKGROUND
                            // ================================================

                            _animatedEntry(
                              index: 10,
                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .business_center_outlined,
                                title:
                                'Professional Background',
                                subtitle:
                                'Tell companies more about you',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 11,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  _buildSmallLabel(
                                    'Previous Company',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _previousCompanyController,
                                    hintText:
                                    'Enter Previous Company Name',
                                    prefixIcon:
                                    Icons
                                        .business_rounded,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  _buildSmallLabel(
                                    'About Me / Professional Description',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _aboutController,

                                    hintText:
                                    'Describe your drone experience, skills, specialties and professional background...',

                                    prefixIcon:
                                    Icons
                                        .notes_rounded,

                                    maxLines: 5,

                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Professional description is required';
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
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            // ================================================
                            // BUTTON
                            // ================================================

                            _animatedEntry(
                              index: 12,
                              child:
                              _buildPrimaryButton(
                                text:
                                'Continue',
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
                              index: 13,
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
              const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                  color: kBorder,
                ),
              ),

              child: const Text(
                'STEP 2 OF 4',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  fontWeight:
                  FontWeight.w700,
                  color: kTextMuted,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Responsive progress bar
        Row(
          children: List.generate(
            4,
                (index) {
              final bool active =
                  index <= 1;

              return Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.only(
                    right:
                    index == 3 ? 0 : 6,
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
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),

                      color: active
                          ? kPrimary
                          : kBorder,

                      boxShadow: active
                          ? [
                        BoxShadow(
                          color: kPrimary
                              .withOpacity(
                            0.18,
                          ),
                          blurRadius: 7,
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

  Widget _buildExperienceBadge() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
        kPrimary.withOpacity(0.085),

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons
                .workspace_premium_outlined,
            color: kPrimary,
            size: 14,
          ),

          SizedBox(width: 6),

          Text(
            'PROFESSIONAL PROFILE',
            style: TextStyle(
              color: kPrimary,
              fontSize: 10,
              fontWeight:
              FontWeight.w700,
              letterSpacing: 0.65,
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

          decoration: BoxDecoration(
            color:
            kPrimary.withOpacity(0.09),

            borderRadius:
            BorderRadius.circular(11),
          ),

          child: Icon(
            icon,
            color: kPrimary,
            size: 18,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,

                style: const TextStyle(
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

  Widget _buildSmallLabel(
      String text,
      ) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: kTextDark,
      ),
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
        BorderRadius.circular(50),

        onTap: _isSubmitting
            ? null
            : () {
          HapticFeedback
              .selectionClick();

          Navigator.pop(context);
        },

        child: Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            border: Border.all(
              color: Colors.black
                  .withOpacity(0.045),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.035),

                blurRadius: 9,

                offset:
                const Offset(0, 3),
              ),
            ],
          ),

          child: const Icon(
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
    required TextEditingController
    controller,

    required String hintText,

    IconData? prefixIcon,

    TextInputType keyboardType =
        TextInputType.text,

    TextInputAction? textInputAction,

    int maxLines = 1,

    Widget? suffixIcon,

    String? Function(String?)?
    validator,
  }) {
    return TextFormField(
      controller: controller,

      enabled: !_isSubmitting,

      keyboardType: keyboardType,

      textInputAction:
      textInputAction,

      maxLines: maxLines,

      validator: validator,

      autovalidateMode:
      AutovalidateMode
          .onUserInteraction,

      style: const TextStyle(
        fontSize: 13.5,
        color: kTextDark,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: hintText,

        hintMaxLines:
        maxLines > 1 ? 3 : 1,

        hintStyle: const TextStyle(
          color: kHint,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),

        prefixIcon:
        prefixIcon != null
            ? Padding(
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
        )
            : null,

        suffixIcon: suffixIcon,

        filled: true,

        fillColor: Colors.white,

        errorStyle:
        const TextStyle(
          fontSize: 10.5,
          color: kDanger,
          height: 1.2,
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: kBorder,
            width: 0.8,
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: kBorder,
            width: 0.8,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: kPrimary,
            width: 1.4,
          ),
        ),

        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: kDanger,
            width: 1,
          ),
        ),

        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: kDanger,
            width: 1.3,
          ),
        ),

        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: kBorder,
            width: 0.8,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // SELECT FIELD
  // ==========================================================================

  Widget _buildSelectField({
    required String hintText,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return FormField<String>(
      validator: (_) {
        if (value == null ||
            value.isEmpty) {
          return 'Selection is required';
        }

        return null;
      },

      builder: (state) {
        final hasValue =
            value != null &&
                value.isNotEmpty;

        return InkWell(
          borderRadius:
          BorderRadius.circular(15),

          onTap: _isSubmitting
              ? null
              : () {
            _openSelectSheet(
              title:
              'Years of Experience',

              items: items,

              selected: value,

              onSelected:
                  (selectedValue) {
                onChanged(
                  selectedValue,
                );

                state.didChange(
                  selectedValue,
                );
              },
            );
          },

          child: Container(
            width: double.infinity,

            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius.circular(
                15,
              ),

              border: Border.all(
                color: state.hasError
                    ? kDanger
                    : kBorder,

                width: state.hasError
                    ? 1
                    : 0.8,
              ),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Icon(
                      icon,

                      size: 18,

                      color: hasValue
                          ? kPrimary
                          : kHint,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        value ??
                            hintText,

                        maxLines: 1,

                        overflow:
                        TextOverflow
                            .ellipsis,

                        style: TextStyle(
                          fontSize: 13.5,

                          fontWeight:
                          hasValue
                              ? FontWeight
                              .w600
                              : FontWeight
                              .w400,

                          color:
                          hasValue
                              ? kTextDark
                              : kHint,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,

                      size: 20,

                      color: kHint,
                    ),
                  ],
                ),

                if (state.hasError)
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 7,
                      left: 28,
                    ),

                    child: Text(
                      state.errorText!,

                      style:
                      const TextStyle(
                        color: kDanger,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // EXPERIENCE BOTTOM SHEET
  // ==========================================================================

  Future<void> _openSelectSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?>
    onSelected,
  }) async {
    HapticFeedback.lightImpact();

    await showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return SafeArea(
          child: Container(
            decoration:
            const BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius.vertical(
                top:
                Radius.circular(28),
              ),
            ),

            padding:
            const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              24,
            ),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Container(
                  width: 42,
                  height: 4,

                  decoration: BoxDecoration(
                    color: kBorder,

                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,

                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight
                              .w800,
                          color: kTextDark,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      icon:
                      const Icon(
                        Icons.close_rounded,
                        color: kHint,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                ...items.map(
                      (item) {
                    final isSelected =
                        item == selected;

                    return Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 9,
                      ),

                      child: Material(
                        color: isSelected
                            ? kPrimary
                            .withOpacity(
                          0.075,
                        )
                            : kSurfaceSoft,

                        borderRadius:
                        BorderRadius
                            .circular(
                          15,
                        ),

                        child: InkWell(
                          borderRadius:
                          BorderRadius
                              .circular(
                            15,
                          ),

                          onTap: () {
                            HapticFeedback
                                .selectionClick();

                            onSelected(
                              item,
                            );

                            Navigator.pop(
                              context,
                            );
                          },

                          child: Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              15,
                              vertical: 14,
                            ),

                            decoration:
                            BoxDecoration(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                15,
                              ),

                              border:
                              Border.all(
                                color: isSelected
                                    ? kPrimary
                                    : Colors
                                    .transparent,

                                width: 1,
                              ),
                            ),

                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,

                                  decoration:
                                  BoxDecoration(
                                    color: isSelected
                                        ? kPrimary.withOpacity(
                                      0.12,
                                    )
                                        : Colors.white,

                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10,
                                    ),
                                  ),

                                  child:
                                  Icon(
                                    Icons
                                        .workspace_premium_outlined,

                                    size: 17,

                                    color: isSelected
                                        ? kPrimary
                                        : kHint,
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                  Text(
                                    item,

                                    style:
                                    TextStyle(
                                      fontSize:
                                      13.5,

                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,

                                      color: isSelected
                                          ? kPrimary
                                          : kTextDark,
                                    ),
                                  ),
                                ),

                                AnimatedSwitcher(
                                  duration:
                                  const Duration(
                                    milliseconds:
                                    180,
                                  ),

                                  child: isSelected
                                      ? const Icon(
                                    Icons.check_circle_rounded,
                                    key: ValueKey(
                                      'yes',
                                    ),
                                    size: 20,
                                    color: kPrimary,
                                  )
                                      : const SizedBox(
                                    key: ValueKey(
                                      'no',
                                    ),
                                    width: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // LANGUAGE CHIPS
  // ==========================================================================

  Widget _buildMultiSelectChips({
    required List<String> options,
    required Set<String> selectedItems,
    required ValueChanged<String>
    onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 9,

      children: options.map(
            (item) {
          final selected =
          selectedItems.contains(item);

          return InkWell(
            borderRadius:
            BorderRadius.circular(22),

            onTap: () {
              onToggle(item);
            },

            child: AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 220,
              ),

              curve:
              Curves.easeOutCubic,

              padding:
              const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),

              decoration: BoxDecoration(
                color: selected
                    ? kPrimary
                    .withOpacity(0.09)
                    : Colors.white,

                borderRadius:
                BorderRadius.circular(
                  22,
                ),

                border: Border.all(
                  color: selected
                      ? kPrimary
                      : kBorder,

                  width:
                  selected ? 1.2 : 0.8,
                ),

                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: kPrimary
                        .withOpacity(
                      0.07,
                    ),

                    blurRadius: 10,

                    offset:
                    const Offset(
                      0,
                      3,
                    ),
                  ),
                ]
                    : [],
              ),

              child: Row(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  AnimatedSwitcher(
                    duration:
                    const Duration(
                      milliseconds: 180,
                    ),

                    child: selected
                        ? const Padding(
                      key:
                      ValueKey(
                        'checked',
                      ),

                      padding:
                      EdgeInsets.only(
                        right: 5,
                      ),

                      child: Icon(
                        Icons
                            .check_rounded,

                        size: 14,

                        color:
                        kPrimary,
                      ),
                    )
                        : const SizedBox(
                      key:
                      ValueKey(
                        'unchecked',
                      ),
                    ),
                  ),

                  Text(
                    item,

                    style: TextStyle(
                      fontSize: 12.5,

                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,

                      color: selected
                          ? kPrimary
                          : kTextDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // REGION SELECTOR
  // ==========================================================================

  Widget _buildRegionSelector() {
    final hasRegions =
        _selectedWillingRegions
            .isNotEmpty;

    return InkWell(
      onTap: _countries.isEmpty ||
          _isSubmitting
          ? null
          : _showCountryAndRegionsPicker,

      borderRadius:
      BorderRadius.circular(15),

      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 250,
        ),

        width: double.infinity,

        constraints:
        const BoxConstraints(
          minHeight: 54,
        ),

        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(15),

          border: Border.all(
            color: hasRegions
                ? kPrimary
                .withOpacity(0.50)
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

            const SizedBox(width: 10),

            Expanded(
              child: !hasRegions
                  ? const Text(
                'Select country and regions',
                style: TextStyle(
                  color: kHint,
                  fontSize: 13,
                ),
              )
                  : Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  if (_selectedCountry !=
                      null)
                    Text(
                      _selectedCountry!
                          .name,

                      maxLines: 1,

                      overflow:
                      TextOverflow
                          .ellipsis,

                      style:
                      const TextStyle(
                        fontSize: 11,
                        color:
                        kTextMuted,
                        fontWeight:
                        FontWeight
                            .w500,
                      ),
                    ),

                  if (_selectedCountry !=
                      null)
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
                            horizontal: 8,
                            vertical: 4,
                          ),

                          decoration:
                          BoxDecoration(
                            color: kPrimary
                                .withOpacity(
                              0.10,
                            ),

                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),

                          child: Text(
                            '+${_selectedWillingRegions.length - 3}',

                            style:
                            const TextStyle(
                              color:
                              kPrimary,

                              fontSize: 10.5,

                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

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

      decoration: BoxDecoration(
        color:
        kPrimary.withOpacity(0.09),

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Text(
        region,

        maxLines: 1,

        overflow:
        TextOverflow.ellipsis,

        style: const TextStyle(
          color: kPrimary,

          fontSize: 10.5,

          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================================
  // COUNTRY + REGIONS BOTTOM SHEET
  // ==========================================================================

  void _showCountryAndRegionsPicker() {
    HapticFeedback.lightImpact();

    CountryModel? tempCountry =
        _selectedCountry;

    final Set<String> tempSelectedCities =
    Set<String>.from(
      _selectedWillingRegions,
    );

    String searchQuery = '';

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor:
      Colors.transparent,

      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            final List<String> allCities =
                tempCountry?.cities ?? [];

            final query =
            searchQuery
                .trim()
                .toLowerCase();

            final List<String>
            filteredCities =
            allCities.where(
                  (city) {
                if (query.isEmpty) {
                  return true;
                }

                return city
                    .toLowerCase()
                    .contains(query);
              },
            ).toList();

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.88,

                child: Container(
                  decoration:
                  const BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius
                        .vertical(
                      top: Radius.circular(
                        28,
                      ),
                    ),
                  ),

                  child: Column(
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
                          BorderRadius
                              .circular(
                            20,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==============================================
                      // HEADER
                      // ==============================================

                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                        ),

                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  Text(
                                    'Work Regions',

                                    style:
                                    TextStyle(
                                      fontSize:
                                      18,

                                      fontWeight:
                                      FontWeight
                                          .w800,

                                      color:
                                      kTextDark,
                                    ),
                                  ),

                                  SizedBox(
                                    height: 2,
                                  ),

                                  Text(
                                    'Choose a country and the cities you can work in',

                                    style:
                                    TextStyle(
                                      color:
                                      kTextMuted,

                                      fontSize:
                                      11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },

                              icon:
                              const Icon(
                                Icons
                                    .close_rounded,

                                color: kHint,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==============================================
                      // COUNTRY
                      // ==============================================

                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                        ),

                        child:
                        DropdownButtonFormField<
                            CountryModel>(
                          value:
                          tempCountry,

                          isExpanded: true,

                          menuMaxHeight:
                          350,

                          decoration:
                          InputDecoration(
                            labelText:
                            'Country',

                            hintText:
                            'Select Country',

                            prefixIcon:
                            const Icon(
                              Icons
                                  .public_rounded,

                              color: kHint,

                              size: 19,
                            ),

                            filled: true,

                            fillColor:
                            const Color(
                              0xFFF8FAFB,
                            ),

                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
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
                              BorderRadius
                                  .circular(
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
                              BorderRadius
                                  .circular(
                                15,
                              ),

                              borderSide:
                              const BorderSide(
                                color:
                                kPrimary,

                                width: 1.3,
                              ),
                            ),
                          ),

                          items:
                          _countries.map(
                                (country) {
                              return DropdownMenuItem<
                                  CountryModel>(
                                value: country,

                                child: Text(
                                  country.name,

                                  maxLines: 1,

                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                ),
                              );
                            },
                          ).toList(),

                          onChanged:
                              (country) {
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

                      // ==============================================
                      // CITY AREA
                      // ==============================================

                      Expanded(
                        child:
                        tempCountry == null
                            ? _buildEmptyRegionState(
                          icon:
                          Icons.public_rounded,

                          title:
                          'Choose a country',

                          subtitle:
                          'Cities will appear here after selecting a country.',
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
                            // ==================================
                            // SEARCH
                            // ==================================

                            Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal:
                                18,
                              ),

                              child:
                              TextField(
                                onChanged:
                                    (value) {
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

                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                    vertical:
                                    13,
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

                            // ==================================
                            // SELECTED COUNT
                            // ==================================

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

                                  AnimatedContainer(
                                    duration:
                                    const Duration(
                                      milliseconds:
                                      200,
                                    ),

                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal:
                                      9,
                                      vertical:
                                      5,
                                    ),

                                    decoration:
                                    BoxDecoration(
                                      color: tempSelectedCities.isEmpty
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
                                        color: tempSelectedCities.isEmpty
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
                              child: filteredCities
                                  .isEmpty
                                  ? const Center(
                                child:
                                Text(
                                  'No cities found',

                                  style:
                                  TextStyle(
                                    color:
                                    kTextMuted,

                                    fontSize:
                                    13,
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

                                                width:
                                                1.2,
                                              ),
                                            ),

                                            child: selected
                                                ? const Icon(
                                              Icons.check_rounded,

                                              size:
                                              14,

                                              color:
                                              Colors.white,
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

                      // ==============================================
                      // DONE
                      // ==============================================

                      Padding(
                        padding:
                        const EdgeInsets
                            .fromLTRB(
                          18,
                          10,
                          18,
                          18,
                        ),

                        child: SizedBox(
                          width:
                          double.infinity,

                          height: 50,

                          child:
                          ElevatedButton(
                            onPressed:
                            tempCountry ==
                                null
                                ? null
                                : () {
                              HapticFeedback
                                  .mediumImpact();

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
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              kPrimary,

                              foregroundColor:
                              Colors.white,

                              disabledBackgroundColor:
                              kBorder,

                              elevation: 0,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  25,
                                ),
                              ),
                            ),

                            child: Text(
                              tempSelectedCities
                                  .isEmpty
                                  ? 'Done'
                                  : 'Done • ${tempSelectedCities.length} Selected',

                              style:
                              const TextStyle(
                                fontSize: 13.5,

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
        const EdgeInsets.all(30),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color:
                kPrimary.withOpacity(
                  0.07,
                ),

                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,

                color: kPrimary,

                size: 25,
              ),
            ),

            const SizedBox(
              height: 13,
            ),

            Text(
              title,

              textAlign:
              TextAlign.center,

              style: const TextStyle(
                color: kTextDark,

                fontSize: 14,

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

              style: const TextStyle(
                color: kTextMuted,

                fontSize: 11.5,

                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // PRIMARY BUTTON
  // ==========================================================================

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Listener(
      onPointerDown: (_) {
        if (onPressed != null &&
            !isLoading) {
          setState(() {
            _buttonPressed = true;
          });
        }
      },

      onPointerUp: (_) {
        if (mounted) {
          setState(() {
            _buttonPressed = false;
          });
        }
      },

      onPointerCancel: (_) {
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
        _buttonPressed ? 0.975 : 1,

        child: Container(
          width: double.infinity,

          height: 54,

          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(28),

            gradient:
            const LinearGradient(
              begin:
              Alignment.centerLeft,

              end:
              Alignment.centerRight,

              colors: [
                Color(0xFF0D8AA5),
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
                const Offset(0, 7),
              ),
            ],
          ),

          child: ElevatedButton(
            onPressed: onPressed,

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

            child: AnimatedSwitcher(
              duration:
              const Duration(
                milliseconds: 220,
              ),

              child: isLoading
                  ? const SizedBox(
                key:
                ValueKey(
                  'loading',
                ),

                width: 23,
                height: 23,

                child:
                CircularProgressIndicator(
                  strokeWidth: 2.4,

                  color: Colors.white,
                ),
              )
                  : Row(
                key:
                const ValueKey(
                  'normal',
                ),

                mainAxisAlignment:
                MainAxisAlignment
                    .center,

                children: [
                  Flexible(
                    child: Text(
                      text,

                      overflow:
                      TextOverflow
                          .ellipsis,

                      style:
                      const TextStyle(
                        color:
                        Colors.white,

                        fontSize: 15,

                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  const Icon(
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
            Icons.info_outline_rounded,

            size: 12,

            color: kTextMuted,
          ),

          SizedBox(width: 5),

          Flexible(
            child: Text(
              'You can update these details later from your profile.',

              textAlign:
              TextAlign.center,

              style: TextStyle(
                color: kTextMuted,

                fontSize: 10.5,
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

      if (!mounted) return;

      setState(() {
        _countries = countries;

        // Do not automatically choose Afghanistan
        _selectedCountry = null;

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

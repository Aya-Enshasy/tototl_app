import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tototl_app/core/theme/app_colors.dart';

import '../../../models/country_model.dart';
import '../../../services/location_service.dart';
import 'company_register_step_tow_screen.dart';

// ============================================================================
// COMPANY REGISTRATION - STEP 1
// ============================================================================

class CompanyRegisterStepOneScreen extends StatefulWidget {
  const CompanyRegisterStepOneScreen({
    super.key,
  });

  @override
  State<CompanyRegisterStepOneScreen> createState() =>
      _CompanyRegisterStepOneScreenState();
}

class _CompanyRegisterStepOneScreenState
    extends State<CompanyRegisterStepOneScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // FORM
  // ==========================================================================

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _companyNameController =
  TextEditingController();

  final TextEditingController _userIdController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  // ==========================================================================
  // STATE
  // ==========================================================================

  String? _selectedCompanyType;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isSubmitting = false;
  bool _buttonPressed = false;
  bool _isPickingLogo = false;

  File? _companyLogo;

  // ==========================================================================
  // COUNTRY
  // ==========================================================================

  final LocationService _locationService =
  LocationService();

  List<CountryModel> _countries = [];

  CountryModel? _selectedCountry;

  // ==========================================================================
  // IMAGE PICKER
  // ==========================================================================

  final ImagePicker _imagePicker =
  ImagePicker();

  // ==========================================================================
  // COMPANY TYPES
  // ==========================================================================

  final List<String> _companyTypes = const [
    'Construction',
    'Energy',
    'Real Estate',
    'Inspection',
    'Agriculture',
    'Other',
  ];

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
  // ANIMATIONS
  // ==========================================================================

  late final AnimationController
  _pageAnimationController;

  late final AnimationController
  _logoFloatController;

  late final Animation<double>
  _logoFloatAnimation;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
        Colors.transparent,
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
          const Duration(
            milliseconds: 1050,
          ),
        );

    _logoFloatController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(
            milliseconds: 2200,
          ),
        );

    _logoFloatAnimation =
        Tween<double>(
          begin: -2.5,
          end: 2.5,
        ).animate(
          CurvedAnimation(
            parent:
            _logoFloatController,
            curve:
            Curves.easeInOut,
          ),
        );

    _pageAnimationController.forward();

    _logoFloatController.repeat(
      reverse: true,
    );

    _loadCountries();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _companyNameController.dispose();
    _userIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();

    _pageAnimationController.dispose();
    _logoFloatController.dispose();

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
      0.68,
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
      parent:
      _pageAnimationController,
      curve: Interval(
        start,
        end,
        curve:
        Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position:
        Tween<Offset>(
          begin:
          const Offset(
            0,
            0.06,
          ),
          end:
          Offset.zero,
        ).animate(
          animation,
        ),
        child:
        child,
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

      CountryModel? defaultCountry;

      for (final country
      in countries) {
        final name =
        country.name
            .toLowerCase();

        if (country.dialCode ==
            '+970' ||
            name.contains(
              'palestin',
            )) {
          defaultCountry =
              country;

          break;
        }
      }

      setState(() {
        _countries =
            countries;

        if (countries.isNotEmpty) {
          _selectedCountry =
              defaultCountry ??
                  countries.first;
        }
      });
    } catch (e) {
      debugPrint(
        'Countries loading error: $e',
      );
    }
  }

  // ==========================================================================
  // COMPANY LOGO
  // ==========================================================================

  Future<void> _pickCompanyLogo(
      ImageSource source,
      ) async {
    if (_isPickingLogo ||
        _isSubmitting) {
      return;
    }

    HapticFeedback
        .selectionClick();

    setState(() {
      _isPickingLogo =
      true;
    });

    try {
      final picked =
      await _imagePicker
          .pickImage(
        source:
        source,
        imageQuality:
        85,
        maxWidth:
        1200,
      );

      if (picked ==
          null) {
        return;
      }

      final file =
      File(
        picked.path,
      );

      if (!await file
          .exists()) {
        if (mounted) {
          _showSnack(
            'The selected image could not be found.',
            isError:
            true,
          );
        }

        return;
      }

      final size =
      await file.length();

      if (size >
          10 *
              1024 *
              1024) {
        if (mounted) {
          _showSnack(
            'Company logo must be smaller than 10 MB.',
            isError:
            true,
          );
        }

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _companyLogo =
            file;
      });

      HapticFeedback
          .lightImpact();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnack(
        'Unable to open image. Please check app permissions.',
        isError:
        true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingLogo =
          false;
        });
      }
    }
  }

  // ==========================================================================
  // LOGO SOURCE SHEET
  // ==========================================================================

  void _showLogoSourceSheet() {
    if (_isSubmitting) {
      return;
    }

    HapticFeedback
        .lightImpact();

    showModalBottomSheet(
      context:
      context,
      backgroundColor:
      Colors.transparent,
      isScrollControlled:
      true,
      builder:
          (context) {
        return SafeArea(
          child:
          Container(
            padding:
            const EdgeInsets
                .fromLTRB(
              18,
              10,
              18,
              24,
            ),
            decoration:
            const BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius
                  .vertical(
                top:
                Radius.circular(
                  28,
                ),
              ),
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
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
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                  20,
                ),

                const Align(
                  alignment:
                  Alignment.centerLeft,
                  child:
                  Text(
                    'Company Logo',
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
                ),

                const SizedBox(
                  height:
                  4,
                ),

                const Align(
                  alignment:
                  Alignment.centerLeft,
                  child:
                  Text(
                    'Add your official company logo.',
                    style:
                    TextStyle(
                      fontSize:
                      11.5,
                      color:
                      kTextMuted,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                  18,
                ),

                _buildLogoSheetOption(
                  icon:
                  Icons.camera_alt_rounded,
                  title:
                  'Take a Photo',
                  subtitle:
                  'Use your device camera',
                  onTap:
                      () {
                    Navigator.pop(
                      context,
                    );

                    _pickCompanyLogo(
                      ImageSource.camera,
                    );
                  },
                ),

                const SizedBox(
                  height:
                  10,
                ),

                _buildLogoSheetOption(
                  icon:
                  Icons.photo_library_rounded,
                  title:
                  'Choose from Gallery',
                  subtitle:
                  'Select your company logo',
                  onTap:
                      () {
                    Navigator.pop(
                      context,
                    );

                    _pickCompanyLogo(
                      ImageSource.gallery,
                    );
                  },
                ),

                if (_companyLogo !=
                    null) ...[
                  const SizedBox(
                    height:
                    10,
                  ),

                  _buildLogoSheetOption(
                    icon:
                    Icons.delete_outline_rounded,
                    title:
                    'Remove Logo',
                    subtitle:
                    'Remove the selected image',
                    destructive:
                    true,
                    onTap:
                        () {
                      Navigator.pop(
                        context,
                      );

                      setState(() {
                        _companyLogo =
                        null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive =
    false,
  }) {
    final color =
    destructive
        ? kDanger
        : kPrimary;

    return Material(
      color: destructive
          ? kDanger
          .withOpacity(
        0.05,
      )
          : kSurfaceSoft,
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child:
      InkWell(
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        onTap:
        onTap,
        child:
        Padding(
          padding:
          const EdgeInsets
              .symmetric(
            horizontal:
            14,
            vertical:
            13,
          ),
          child:
          Row(
            children: [
              Container(
                width:
                40,
                height:
                40,
                decoration:
                BoxDecoration(
                  color:
                  color.withOpacity(
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                Icon(
                  icon,
                  color:
                  color,
                  size:
                  19,
                ),
              ),

              const SizedBox(
                width:
                12,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      TextStyle(
                        fontSize:
                        13.5,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        destructive
                            ? color
                            : kTextDark,
                      ),
                    ),
                    const SizedBox(
                      height:
                      2,
                    ),
                    Text(
                      subtitle,
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

              Icon(
                Icons.chevron_right_rounded,
                color:
                color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // COMPANY LOGO UI
  // ==========================================================================

  Widget _buildCompanyLogo() {
    return AnimatedBuilder(
      animation:
      _logoFloatAnimation,
      builder:
          (
          context,
          child,
          ) {
        return Transform.translate(
          offset:
          Offset(
            0,
            _logoFloatAnimation.value,
          ),
          child:
          child,
        );
      },
      child:
      GestureDetector(
        onTap:
        _showLogoSourceSheet,
        child:
        Column(
          children: [
            Stack(
              clipBehavior:
              Clip.none,
              children: [
                Container(
                  width:
                  112,
                  height:
                  112,
                  padding:
                  const EdgeInsets.all(
                    4,
                  ),
                  decoration:
                  BoxDecoration(
                    shape:
                    BoxShape.circle,
                    gradient:
                    LinearGradient(
                      begin:
                      Alignment.topLeft,
                      end:
                      Alignment.bottomRight,
                      colors: [
                        kPrimary
                            .withOpacity(
                          0.22,
                        ),
                        kPrimary
                            .withOpacity(
                          0.035,
                        ),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        kPrimary.withOpacity(
                          0.12,
                        ),
                        blurRadius:
                        24,
                        offset:
                        const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child:
                  Container(
                    padding:
                    const EdgeInsets.all(
                      3,
                    ),
                    decoration:
                    const BoxDecoration(
                      shape:
                      BoxShape.circle,
                      color:
                      Colors.white,
                    ),
                    child:
                    ClipOval(
                      child:
                      AnimatedSwitcher(
                        duration:
                        const Duration(
                          milliseconds:
                          300,
                        ),
                        child:
                        _isPickingLogo
                            ? const Center(
                          key:
                          ValueKey(
                            'loading',
                          ),
                          child:
                          SizedBox(
                            width:
                            25,
                            height:
                            25,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2.3,
                              color:
                              kPrimary,
                            ),
                          ),
                        )
                            : _companyLogo !=
                            null
                            ? Image.file(
                          _companyLogo!,
                          key:
                          ValueKey(
                            _companyLogo!.path,
                          ),
                          fit:
                          BoxFit.cover,
                          width:
                          102,
                          height:
                          102,
                        )
                            : Container(
                          key:
                          const ValueKey(
                            'placeholder',
                          ),
                          color:
                          const Color(
                            0xFFF1F6F8,
                          ),
                          child:
                          const Icon(
                            Icons.business_rounded,
                            size:
                            53,
                            color:
                            Color(
                              0xFFB8C6CE,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right:
                  -1,
                  bottom:
                  3,
                  child:
                  Container(
                    width:
                    35,
                    height:
                    35,
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      gradient:
                      const LinearGradient(
                        colors: [
                          Color(
                            0xFF0D8AA5,
                          ),
                          kPrimary,
                        ],
                      ),
                      border:
                      Border.all(
                        color:
                        Colors.white,
                        width:
                        3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          kPrimary.withOpacity(
                            0.25,
                          ),
                          blurRadius:
                          11,
                          offset:
                          const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),
                    child:
                    Icon(
                      _companyLogo ==
                          null
                          ? Icons.add_a_photo_rounded
                          : Icons.edit_rounded,
                      color:
                      Colors.white,
                      size:
                      15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
              12,
            ),

            Text(
              _companyLogo ==
                  null
                  ? 'Add company logo'
                  : 'Change company logo',
              style:
              const TextStyle(
                fontSize:
                12.5,
                fontWeight:
                FontWeight.w700,
                color:
                kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // NEXT
  // ==========================================================================

  Future<void> _handleNext() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context)
        .unfocus();

    final valid =
        _formKey.currentState
            ?.validate() ??
            false;

    if (!valid) {
      HapticFeedback
          .heavyImpact();

      _showSnack(
        'Please complete all required fields.',
        isError:
        true,
      );

      return;
    }

    if (_selectedCompanyType ==
        null) {
      HapticFeedback
          .heavyImpact();

      _showSnack(
        'Please select a company type.',
        isError:
        true,
      );

      return;
    }

    setState(() {
      _isSubmitting =
      true;
    });

    // DESIGN ONLY - NO API
    await Future.delayed(
      const Duration(
        milliseconds:
        400,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting =
      false;
    });

    HapticFeedback
        .mediumImpact();

    Navigator.push(
      context,
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
        pageBuilder:
            (
            context,
            animation,
            secondaryAnimation,
            ) {
          return const CompanyRegisterStepTwoScreen();
        },
        transitionsBuilder:
            (
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
  }

  // ==========================================================================
  // SNACK
  // ==========================================================================

  void _showSnack(
      String message, {
        bool isError =
        false,
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
          elevation:
          8,
          margin:
          const EdgeInsets.all(
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
          content:
          Row(
            children: [
              Container(
                width:
                34,
                height:
                34,
                decoration:
                BoxDecoration(
                  color:
                  Colors.white.withOpacity(
                    0.15,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_rounded,
                  color:
                  Colors.white,
                  size:
                  20,
                ),
              ),

              const SizedBox(
                width:
                11,
              ),

              Expanded(
                child:
                Text(
                  message,
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize:
                    12.5,
                    fontWeight:
                    FontWeight.w600,
                    height:
                    1.3,
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
      body:
      Stack(
        children: [
          // ==================================================================
          // BACKGROUND GLOW
          // ==================================================================

          Positioned(
            top:
            -120,
            right:
            -100,
            child:
            IgnorePointer(
              child:
              Container(
                width:
                280,
                height:
                280,
                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,
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
            top:
            500,
            left:
            -150,
            child:
            IgnorePointer(
              child:
              Container(
                width:
                280,
                height:
                280,
                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,
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
            child:
            LayoutBuilder(
              builder:
                  (
                  context,
                  constraints,
                  ) {
                return SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    34,
                  ),
                  child:
                  Center(
                    child:
                    ConstrainedBox(
                      constraints:
                      const BoxConstraints(
                        maxWidth:
                        560,
                      ),
                      child:
                      Form(
                        key:
                        _formKey,
                        child:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // ================================================
                            // HEADER
                            // ================================================

                            _animatedEntry(
                              index:
                              0,
                              child:
                              _buildHeader(),
                            ),

                            const SizedBox(
                              height:
                              26,
                            ),

                            // ================================================
                            // BADGE
                            // ================================================

                            _animatedEntry(
                              index:
                              1,
                              child:
                              _buildCompanyBadge(),
                            ),

                            const SizedBox(
                              height:
                              12,
                            ),

                            // ================================================
                            // TITLE
                            // ================================================

                            _animatedEntry(
                              index:
                              2,
                              child:
                              const Text(
                                'Create Company Account',
                                style:
                                TextStyle(
                                  fontSize:
                                  27,
                                  fontWeight:
                                  FontWeight.w800,
                                  color:
                                  kTextDark,
                                  letterSpacing:
                                  -0.6,
                                  height:
                                  1.15,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                              7,
                            ),

                            _animatedEntry(
                              index:
                              3,
                              child:
                              const Text(
                                'Complete your company information to start connecting with professional drone pilots.',
                                style:
                                TextStyle(
                                  fontSize:
                                  13.5,
                                  height:
                                  1.5,
                                  color:
                                  kTextMuted,
                                  fontWeight:
                                  FontWeight.w400,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                              27,
                            ),

                            // ================================================
                            // LOGO
                            // ================================================

                            _animatedEntry(
                              index:
                              4,
                              child:
                              Center(
                                child:
                                _buildCompanyLogo(),
                              ),
                            ),

                            const SizedBox(
                              height:
                              32,
                            ),

                            // ================================================
                            // SECTION
                            // ================================================

                            _animatedEntry(
                              index:
                              5,
                              child:
                              _buildSectionHeader(),
                            ),

                            const SizedBox(
                              height:
                              17,
                            ),

                            // ================================================
                            // FIELDS - NO BIG WHITE CARD
                            // ================================================

                            _animatedEntry(
                              index:
                              6,
                              child:
                              Column(
                                children: [
                                  // Company Name
                                  _buildTextField(
                                    controller:
                                    _companyNameController,
                                    hintText:
                                    'Company Name',
                                    prefixIcon:
                                    Icons.business_outlined,
                                    textInputAction:
                                    TextInputAction.next,
                                    validator:
                                        (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Company name is required';
                                      }

                                      if (value.trim().length < 2) {
                                        return 'Enter a valid company name';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height:
                                    13,
                                  ),

                                  // Username
                                  _buildTextField(
                                    controller:
                                    _userIdController,
                                    hintText:
                                    'User ID / Username',
                                    prefixIcon:
                                    Icons.alternate_email_rounded,
                                    textInputAction:
                                    TextInputAction.next,
                                    validator:
                                        (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'User ID is required';
                                      }

                                      if (value.trim().length < 3) {
                                        return 'Username must be at least 3 characters';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height:
                                    13,
                                  ),

                                  // Email
                                  _buildTextField(
                                    controller:
                                    _emailController,
                                    hintText:
                                    'Email Address',
                                    prefixIcon:
                                    Icons.email_outlined,
                                    keyboardType:
                                    TextInputType.emailAddress,
                                    textInputAction:
                                    TextInputAction.next,
                                    validator:
                                        (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email address is required';
                                      }

                                      final emailRegex =
                                      RegExp(
                                        r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$',
                                      );

                                      if (!emailRegex.hasMatch(
                                        value.trim(),
                                      )) {
                                        return 'Enter a valid email address';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height:
                                    13,
                                  ),

                                  // Phone
                                  _buildPhoneField(),

                                  const SizedBox(
                                    height:
                                    13,
                                  ),

                                  // Industry
                                  _buildCompanyTypeField(),

                                  const SizedBox(
                                    height:
                                    13,
                                  ),

                                  // Password
                                  _buildTextField(
                                    controller:
                                    _passwordController,
                                    hintText:
                                    'Password',
                                    prefixIcon:
                                    Icons.lock_outline_rounded,
                                    obscureText:
                                    _obscurePassword,
                                    textInputAction:
                                    TextInputAction.next,
                                    suffixIcon:
                                    IconButton(
                                      onPressed:
                                      _isSubmitting
                                          ? null
                                          : () {
                                        HapticFeedback.selectionClick();

                                        setState(() {
                                          _obscurePassword =
                                          !_obscurePassword;
                                        });
                                      },
                                      icon:
                                      AnimatedSwitcher(
                                        duration:
                                        const Duration(
                                          milliseconds:
                                          180,
                                        ),
                                        child:
                                        Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          key:
                                          ValueKey(
                                            _obscurePassword,
                                          ),
                                          size:
                                          18,
                                          color:
                                          kHint,
                                        ),
                                      ),
                                    ),
                                    validator:
                                        (value) {
                                      if (value == null ||
                                          value.isEmpty) {
                                        return 'Password is required';
                                      }

                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height:
                                    13,
                                  ),

                                  // Confirm Password
                                  _buildTextField(
                                    controller:
                                    _confirmPasswordController,
                                    hintText:
                                    'Confirm Password',
                                    prefixIcon:
                                    Icons.lock_reset_rounded,
                                    obscureText:
                                    _obscureConfirmPassword,
                                    textInputAction:
                                    TextInputAction.done,
                                    suffixIcon:
                                    IconButton(
                                      onPressed:
                                      _isSubmitting
                                          ? null
                                          : () {
                                        HapticFeedback.selectionClick();

                                        setState(() {
                                          _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                        });
                                      },
                                      icon:
                                      AnimatedSwitcher(
                                        duration:
                                        const Duration(
                                          milliseconds:
                                          180,
                                        ),
                                        child:
                                        Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          key:
                                          ValueKey(
                                            _obscureConfirmPassword,
                                          ),
                                          size:
                                          18,
                                          color:
                                          kHint,
                                        ),
                                      ),
                                    ),
                                    validator:
                                        (value) {
                                      if (value == null ||
                                          value.isEmpty) {
                                        return 'Confirm password is required';
                                      }

                                      if (value !=
                                          _passwordController.text) {
                                        return 'Passwords do not match';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height:
                              29,
                            ),

                            // ================================================
                            // BUTTON
                            // ================================================

                            _animatedEntry(
                              index:
                              7,
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
                              height:
                              14,
                            ),

                            _animatedEntry(
                              index:
                              8,
                              child:
                              _buildBottomNote(),
                            ),

                            const SizedBox(
                              height:
                              8,
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
                horizontal:
                11,
                vertical:
                6,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                border:
                Border.all(
                  color:
                  kBorder,
                ),
              ),
              child:
              const Text(
                'STEP 1 OF 3',
                style:
                TextStyle(
                  fontSize:
                  10,
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
          height:
          15,
        ),

        Row(
          children:
          List.generate(
            3,
                (index) {
              final active =
                  index == 0;

              return Expanded(
                child:
                Padding(
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
                    height:
                    4,
                    decoration:
                    BoxDecoration(
                      color:
                      active
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
        horizontal:
        11,
        vertical:
        6,
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
            color:
            kPrimary,
            size:
            14,
          ),

          SizedBox(
            width:
            6,
          ),

          Text(
            'COMPANY ONBOARDING',
            style:
            TextStyle(
              color:
              kPrimary,
              fontSize:
              10,
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
  // SECTION
  // ==========================================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width:
          35,
          height:
          35,
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
            Icons.business_center_outlined,
            color:
            kPrimary,
            size:
            18,
          ),
        ),

        const SizedBox(
          width:
          10,
        ),

        const Expanded(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Company Details',
                style:
                TextStyle(
                  fontSize:
                  15,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  kTextDark,
                ),
              ),

              SizedBox(
                height:
                2,
              ),

              Text(
                'Complete your company account information',
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
      ],
    );
  }

  // ==========================================================================
  // BACK
  // ==========================================================================

  Widget _buildBackButton() {
    return Material(
      color:
      Colors.transparent,
      child:
      InkWell(
        borderRadius:
        BorderRadius.circular(
          50,
        ),
        onTap:
        _isSubmitting
            ? null
            : () {
          HapticFeedback.selectionClick();

          Navigator.pop(
            context,
          );
        },
        child:
        Container(
          width:
          38,
          height:
          38,
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            shape:
            BoxShape.circle,
            border:
            Border.all(
              color:
              Colors.black.withOpacity(
                0.045,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(
                  0.035,
                ),
                blurRadius:
                9,
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
            Icons.arrow_back_ios_new_rounded,
            size:
            13,
            color:
            kTextDark,
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
    bool obscureText =
    false,
    bool readOnly =
    false,
    TextInputType keyboardType =
        TextInputType.text,
    TextInputAction? textInputAction,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:
      controller,
      enabled:
      !_isSubmitting ||
          readOnly,
      obscureText:
      obscureText,
      readOnly:
      readOnly,
      keyboardType:
      keyboardType,
      textInputAction:
      textInputAction,
      onTap:
      onTap,
      validator:
      validator,
      autovalidateMode:
      AutovalidateMode.onUserInteraction,
      style:
      const TextStyle(
        fontSize:
        13.5,
        color:
        kTextDark,
        fontWeight:
        FontWeight.w500,
      ),
      decoration:
      InputDecoration(
        hintText:
        hintText,

        hintStyle:
        const TextStyle(
          color:
          kHint,
          fontSize:
          13,
          fontWeight:
          FontWeight.w400,
        ),

        prefixIcon:
        prefixIcon ==
            null
            ? null
            : Icon(
          prefixIcon,
          size:
          18,
          color:
          kHint,
        ),

        suffixIcon:
        suffixIcon,

        filled:
        true,
        fillColor:
        Colors.white,

        errorStyle:
        const TextStyle(
          color:
          kDanger,
          fontSize:
          10.5,
          height:
          1.2,
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal:
          14,
          vertical:
          15,
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
            width:
            0.8,
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
            width:
            0.8,
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
            1.4,
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
            color:
            kDanger,
            width:
            1,
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
            color:
            kDanger,
            width:
            1.3,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // PHONE
  // ==========================================================================

  Widget _buildPhoneField() {
    return TextFormField(
      controller:
      _phoneController,
      enabled:
      !_isSubmitting,
      keyboardType:
      TextInputType.phone,
      textInputAction:
      TextInputAction.next,
      autovalidateMode:
      AutovalidateMode.onUserInteraction,

      validator:
          (value) {
        if (value ==
            null ||
            value
                .trim()
                .isEmpty) {
          return 'Phone number is required';
        }

        final numbers =
        value.replaceAll(
          RegExp(
            r'[^0-9]',
          ),
          '',
        );

        if (numbers.length <
            7) {
          return 'Enter a valid phone number';
        }

        return null;
      },

      style:
      const TextStyle(
        fontSize:
        13.5,
        color:
        kTextDark,
        fontWeight:
        FontWeight.w500,
      ),

      decoration:
      InputDecoration(
        hintText:
        'Phone Number',

        hintStyle:
        const TextStyle(
          color:
          kHint,
          fontSize:
          13,
        ),

        prefixIconConstraints:
        const BoxConstraints(
          minWidth:
          0,
          minHeight:
          0,
        ),

        prefixIcon:
        Padding(
          padding:
          const EdgeInsets.only(
            left:
            10,
            right:
            5,
          ),
          child:
          Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              InkWell(
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
                onTap:
                _countries.isEmpty
                    ? null
                    : _showCountryPicker,
                child:
                Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    3,
                    vertical:
                    7,
                  ),
                  child:
                  Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry?.dialCode ??
                            '+970',
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
                        width:
                        2,
                      ),

                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color:
                        kHint,
                        size:
                        16,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                width:
                1,
                height:
                20,
                margin:
                const EdgeInsets.symmetric(
                  horizontal:
                  6,
                ),
                color:
                kBorder,
              ),
            ],
          ),
        ),

        filled:
        true,
        fillColor:
        Colors.white,

        errorStyle:
        const TextStyle(
          color:
          kDanger,
          fontSize:
          10.5,
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal:
          12,
          vertical:
          15,
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
            1.4,
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
            color:
            kDanger,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // COUNTRY PICKER
  // ==========================================================================

  Future<void> _showCountryPicker() async {
    if (_countries.isEmpty ||
        _isSubmitting) {
      return;
    }

    HapticFeedback
        .lightImpact();

    String search =
        '';

    await showModalBottomSheet(
      context:
      context,
      isScrollControlled:
      true,
      backgroundColor:
      Colors.transparent,
      builder:
          (context) {
        return StatefulBuilder(
          builder:
              (
              context,
              setSheetState,
              ) {
            final filtered =
            _countries.where(
                  (
                  country,
                  ) {
                final query =
                search
                    .trim()
                    .toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                return country.name
                    .toLowerCase()
                    .contains(
                  query,
                ) ||
                    country.dialCode
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
                0.78,
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
                                    'Country Code',
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
                                    height:
                                    2,
                                  ),

                                  Text(
                                    'Select your company calling code',
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
                        height:
                        12,
                      ),

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
                                search =
                                    value;
                              },
                            );
                          },
                          decoration:
                          InputDecoration(
                            hintText:
                            'Search country or code',
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
                            kSurfaceSoft,
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                15,
                              ),
                              borderSide:
                              BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height:
                        12,
                      ),

                      const Divider(
                        height:
                        1,
                        color:
                        kBorder,
                      ),

                      Expanded(
                        child:
                        ListView.separated(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount:
                          filtered.length,
                          separatorBuilder:
                              (
                              _,
                              __,
                              ) =>
                          const Divider(
                            height:
                            1,
                            indent:
                            18,
                            endIndent:
                            18,
                            color:
                            kBorder,
                          ),
                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            final country =
                            filtered[index];

                            final selected =
                                _selectedCountry?.name ==
                                    country.name &&
                                    _selectedCountry?.dialCode ==
                                        country.dialCode;

                            return InkWell(
                              onTap:
                                  () {
                                HapticFeedback.selectionClick();

                                setState(() {
                                  _selectedCountry =
                                      country;
                                });

                                Navigator.pop(
                                  context,
                                );
                              },
                              child:
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal:
                                  18,
                                  vertical:
                                  14,
                                ),
                                child:
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                      Text(
                                        country.name,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style:
                                        TextStyle(
                                          fontSize:
                                          13.5,
                                          fontWeight:
                                          selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color:
                                          selected
                                              ? kPrimary
                                              : kTextDark,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width:
                                      10,
                                    ),

                                    Text(
                                      country.dialCode,
                                      style:
                                      TextStyle(
                                        fontSize:
                                        13,
                                        fontWeight:
                                        FontWeight.w700,
                                        color:
                                        selected
                                            ? kPrimary
                                            : kTextMuted,
                                      ),
                                    ),

                                    const SizedBox(
                                      width:
                                      9,
                                    ),

                                    SizedBox(
                                      width:
                                      20,
                                      child:
                                      selected
                                          ? const Icon(
                                        Icons.check_circle_rounded,
                                        color:
                                        kPrimary,
                                        size:
                                        19,
                                      )
                                          : null,
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
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // COMPANY TYPE FIELD
  // ==========================================================================

  Widget _buildCompanyTypeField() {
    return FormField<String>(
      validator:
          (_) {
        if (_selectedCompanyType ==
            null ||
            _selectedCompanyType!
                .isEmpty) {
          return 'Industry type is required';
        }

        return null;
      },
      builder:
          (state) {
        final selected =
            _selectedCompanyType !=
                null;

        return InkWell(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          onTap:
          _isSubmitting
              ? null
              : () {
            _showCompanyTypeSheet(
              onSelected:
                  (value) {
                setState(() {
                  _selectedCompanyType =
                      value;
                });

                state.didChange(
                  value,
                );
              },
            );
          },
          child:
          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              14,
              vertical:
              14,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                15,
              ),
              border:
              Border.all(
                color:
                state.hasError
                    ? kDanger
                    : kBorder,
                width:
                state.hasError
                    ? 1
                    : 0.8,
              ),
            ),
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size:
                      18,
                      color:
                      selected
                          ? kPrimary
                          : kHint,
                    ),

                    const SizedBox(
                      width:
                      10,
                    ),

                    Expanded(
                      child:
                      Text(
                        _selectedCompanyType ??
                            'Industry Type',
                        style:
                        TextStyle(
                          fontSize:
                          13.5,
                          fontWeight:
                          selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color:
                          selected
                              ? kTextDark
                              : kHint,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color:
                      kHint,
                      size:
                      20,
                    ),
                  ],
                ),

                if (state.hasError)
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      top:
                      7,
                      left:
                      28,
                    ),
                    child:
                    Text(
                      state.errorText!,
                      style:
                      const TextStyle(
                        color:
                        kDanger,
                        fontSize:
                        10.5,
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
  // COMPANY TYPE SHEET
  // ==========================================================================

  Future<void> _showCompanyTypeSheet({
    required ValueChanged<String> onSelected,
  }) async {
    HapticFeedback
        .lightImpact();

    await showModalBottomSheet(
      context:
      context,
      backgroundColor:
      Colors.transparent,
      isScrollControlled:
      true,
      builder:
          (context) {
        return SafeArea(
          child:
          Container(
            padding:
            const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              24,
            ),
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
              mainAxisSize:
              MainAxisSize.min,
              children: [
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
                  20,
                ),

                const Row(
                  children: [
                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Industry Type',
                            style:
                            TextStyle(
                              color:
                              kTextDark,
                              fontSize:
                              18,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),

                          SizedBox(
                            height:
                            2,
                          ),

                          Text(
                            'Choose the category that best describes your company',
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
                  ],
                ),

                const SizedBox(
                  height:
                  16,
                ),

                ..._companyTypes.map(
                      (
                      item,
                      ) {
                    final selected =
                        _selectedCompanyType ==
                            item;

                    return Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom:
                        8,
                      ),
                      child:
                      Material(
                        color:
                        selected
                            ? kPrimary.withOpacity(
                          0.075,
                        )
                            : kSurfaceSoft,
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                        child:
                        InkWell(
                          borderRadius:
                          BorderRadius.circular(
                            15,
                          ),
                          onTap:
                              () {
                            HapticFeedback.selectionClick();

                            onSelected(
                              item,
                            );

                            Navigator.pop(
                              context,
                            );
                          },
                          child:
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal:
                              14,
                              vertical:
                              13,
                            ),
                            decoration:
                            BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(
                                15,
                              ),
                              border:
                              Border.all(
                                color:
                                selected
                                    ? kPrimary
                                    : Colors.transparent,
                              ),
                            ),
                            child:
                            Row(
                              children: [
                                Container(
                                  width:
                                  34,
                                  height:
                                  34,
                                  decoration:
                                  BoxDecoration(
                                    color:
                                    selected
                                        ? kPrimary.withOpacity(
                                      0.10,
                                    )
                                        : Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child:
                                  Icon(
                                    _industryIcon(
                                      item,
                                    ),
                                    color:
                                    selected
                                        ? kPrimary
                                        : kHint,
                                    size:
                                    17,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                  12,
                                ),

                                Expanded(
                                  child:
                                  Text(
                                    item,
                                    style:
                                    TextStyle(
                                      color:
                                      selected
                                          ? kPrimary
                                          : kTextDark,
                                      fontSize:
                                      13.5,
                                      fontWeight:
                                      selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),

                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color:
                                    kPrimary,
                                    size:
                                    20,
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

  IconData _industryIcon(
      String type,
      ) {
    switch (type) {
      case 'Construction':
        return Icons.construction_rounded;

      case 'Energy':
        return Icons.bolt_rounded;

      case 'Real Estate':
        return Icons.apartment_rounded;

      case 'Inspection':
        return Icons.manage_search_rounded;

      case 'Agriculture':
        return Icons.eco_rounded;

      default:
        return Icons.business_center_outlined;
    }
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
                  color:
                  Colors.white,
                  strokeWidth:
                  2.4,
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
  // NOTE
  // ==========================================================================

  Widget _buildBottomNote() {
    return const Center(
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size:
            12,
            color:
            kTextMuted,
          ),

          SizedBox(
            width:
            5,
          ),

          Flexible(
            child:
            Text(
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
}
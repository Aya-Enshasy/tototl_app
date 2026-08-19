import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/auth/controllers/auth_controller.dart';
import 'package:tototl_app/features/auth/screens/register/pilot/pilot_register_step_four_screen.dart';

import '../../../models/PilotRegisterRequestModel.dart';

// ============================================================================
// SCREEN 3: Pilot Drone Information
// ============================================================================

class PilotRegisterStepThreeScreen extends StatefulWidget {
  const PilotRegisterStepThreeScreen({
    super.key,
    required this.authController,
    required this.draft,
  });

  final AuthController authController;
  final PilotRegisterRequestModel draft;

  @override
  State<PilotRegisterStepThreeScreen> createState() =>
      _PilotRegisterStepThreeScreenState();
}

class _PilotRegisterStepThreeScreenState
    extends State<PilotRegisterStepThreeScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // FORM
  // ==========================================================================

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // Drone Information
  final TextEditingController _makeController =
  TextEditingController();

  final TextEditingController _modelController =
  TextEditingController();

  final TextEditingController _serialController =
  TextEditingController();

  final TextEditingController _weightController =
  TextEditingController();

  // Flight Information
  final TextEditingController _flightTimeController =
  TextEditingController();

  final TextEditingController _totalBatteriesController =
  TextEditingController();

  final TextEditingController _batteryTypeController =
  TextEditingController();

  // Service Rates
  final TextEditingController _batteryUsageController =
  TextEditingController();

  final TextEditingController _hourlyRateController =
  TextEditingController();

  final TextEditingController _dailyRateController =
  TextEditingController();

  final TextEditingController _emergencyFeeController =
  TextEditingController();

  // ==========================================================================
  // STATE
  // ==========================================================================

  String? _selectedYear;

  File? _droneImage;

  bool _isPickingImage = false;
  bool _isSubmitting = false;
  bool _buttonPressed = false;

  // ==========================================================================
  // ACCESSORIES
  // ==========================================================================

  final List<String> _availableAccessories = const [
    'Thermal Camera',
    'RTK Module',
    'Spotlight',
    'Parachute Safety System',
    'Zoom Camera',
    'Multispectral Sensor',
    'Speaker / Loudspeaker',
    'Winch / Release Mechanism',
  ];

  Set<String> _selectedAccessories = {};

  // ==========================================================================
  // IMAGE
  // ==========================================================================

  final ImagePicker _picker =
  ImagePicker();

  // ==========================================================================
  // YEARS
  // ==========================================================================

  late final List<String> _years =
  List.generate(
    15,
        (index) =>
        (DateTime.now().year - index)
            .toString(),
  );

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

  late final AnimationController
  _pageAnimationController;

  late final AnimationController
  _droneAnimationController;

  late final Animation<double>
  _droneFloatAnimation;

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
            milliseconds: 1150,
          ),
        );

    _droneAnimationController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(
            milliseconds: 2200,
          ),
        );

    _droneFloatAnimation =
        Tween<double>(
          begin: -3,
          end: 3,
        ).animate(
          CurvedAnimation(
            parent:
            _droneAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _pageAnimationController
        .forward();

    _droneAnimationController
        .repeat(
      reverse: true,
    );
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _weightController.dispose();

    _flightTimeController.dispose();
    _totalBatteriesController.dispose();
    _batteryTypeController.dispose();

    _batteryUsageController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _emergencyFeeController.dispose();

    _pageAnimationController.dispose();
    _droneAnimationController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // PAGE ANIMATION
  // ==========================================================================

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final double start =
    (index * 0.06)
        .clamp(
      0.0,
      0.72,
    )
        .toDouble();

    final double end =
    (start + 0.30)
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
            0.055,
          ),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ==========================================================================
  // DRONE IMAGE
  // ==========================================================================

  Future<void> _pickDroneImage(
      ImageSource source,
      ) async {
    if (_isPickingImage ||
        _isSubmitting) {
      return;
    }

    HapticFeedback
        .selectionClick();

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picked =
      await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked == null) {
        return;
      }

      final file =
      File(picked.path);

      if (!await file.exists()) {
        if (mounted) {
          _showSnack(
            'The selected image could not be found.',
            isError: true,
          );
        }

        return;
      }

      final fileSize =
      await file.length();

      if (fileSize >
          10 * 1024 * 1024) {
        if (mounted) {
          _showSnack(
            'Drone photo must be smaller than 10 MB.',
            isError: true,
          );
        }

        return;
      }

      if (!mounted) return;

      setState(() {
        _droneImage = file;
      });

      HapticFeedback
          .lightImpact();
    } on PlatformException {
      if (!mounted) return;

      _showSnack(
        'Unable to open the image picker. Check app permissions.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;

      _showSnack(
        'Unable to upload this image. Please try another photo.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  // ==========================================================================
  // IMAGE SOURCE SHEET
  // ==========================================================================

  void _showImageSourceActionSheet() {
    if (_isSubmitting) return;

    HapticFeedback
        .lightImpact();

    showModalBottomSheet(
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
                Radius.circular(
                  28,
                ),
              ),
            ),

            padding:
            const EdgeInsets
                .fromLTRB(
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
                  height: 20,
                ),

                const Align(
                  alignment:
                  Alignment
                      .centerLeft,
                  child: Text(
                    'Drone Photo',
                    style:
                    TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight
                          .w800,
                      color:
                      kTextDark,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                const Align(
                  alignment:
                  Alignment
                      .centerLeft,
                  child: Text(
                    'Add a clear photo of your aircraft.',
                    style:
                    TextStyle(
                      fontSize: 11.5,
                      color:
                      kTextMuted,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                _buildSheetOption(
                  icon: Icons
                      .camera_alt_rounded,
                  title:
                  'Take a Photo',
                  subtitle:
                  'Use your device camera',
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _pickDroneImage(
                      ImageSource.camera,
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildSheetOption(
                  icon: Icons
                      .photo_library_rounded,
                  title:
                  'Choose from Gallery',
                  subtitle:
                  'Select an existing drone photo',
                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _pickDroneImage(
                      ImageSource.gallery,
                    );
                  },
                ),

                if (_droneImage !=
                    null) ...[
                  const SizedBox(
                    height: 10,
                  ),

                  _buildSheetOption(
                    icon: Icons
                        .delete_outline_rounded,
                    title:
                    'Remove Photo',
                    subtitle:
                    'Remove the selected image',
                    destructive: true,
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      HapticFeedback
                          .lightImpact();

                      setState(() {
                        _droneImage =
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

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive
        ? kDanger
        : kPrimary;

    return Material(
      color: destructive
          ? kDanger.withOpacity(
        0.05,
      )
          : kSurfaceSoft,

      borderRadius:
      BorderRadius.circular(16),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          16,
        ),

        onTap: onTap,

        child: Padding(
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 14,
            vertical: 13,
          ),

          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration:
                BoxDecoration(
                  color: color
                      .withOpacity(
                    0.10,
                  ),

                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),

              const SizedBox(
                width: 12,
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
                      TextStyle(
                        color: destructive
                            ? color
                            : kTextDark,

                        fontSize:
                        13.5,

                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
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
                Icons
                    .chevron_right_rounded,
                size: 20,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // VALIDATION + NEXT
  // ==========================================================================

  String _capabilityToApiValue(
      String label,
      ) {
    // `thermal` is confirmed by the existing API examples.
    // The remaining slugs follow the UI labels and should be checked
    // against the backend enum if the backend restricts capabilities.
    const values = {
      'Thermal Camera': 'thermal',
      'RTK Module': 'rtk',
      'Spotlight': 'spotlight',
      'Parachute Safety System':
      'parachute',
      'Zoom Camera': 'zoom',
      'Multispectral Sensor':
      'multispectral',
      'Speaker / Loudspeaker':
      'speaker',
      'Winch / Release Mechanism':
      'winch',
    };

    return values[label] ?? label;
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

    if (_selectedYear == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select manufacturing year.',
        isError: true,
      );

      return;
    }

    final weight =
    double.tryParse(
      _weightController.text.trim(),
    );

    final flightTime =
    int.tryParse(
      _flightTimeController.text.trim(),
    );

    final totalBatteries =
    int.tryParse(
      _totalBatteriesController.text
          .trim(),
    );

    final hourlyRate =
    double.tryParse(
      _hourlyRateController.text.trim(),
    );

    final dailyRate =
    double.tryParse(
      _dailyRateController.text.trim(),
    );

    final emergencyFee =
    double.tryParse(
      _emergencyFeeController.text
          .trim(),
    );

    if (weight == null ||
        flightTime == null ||
        totalBatteries == null ||
        hourlyRate == null ||
        dailyRate == null ||
        emergencyFee == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please enter valid numeric drone values.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final drone =
    PilotDroneRequest(
      imagePath:
      _droneImage?.path,
      make:
      _makeController.text.trim(),
      model:
      _modelController.text.trim(),
      manufactureYear:
      int.parse(_selectedYear!),
      serialNumber:
      _serialController.text.trim(),
      weightKg:
      weight,
      capabilities:
      _selectedAccessories
          .map(
        _capabilityToApiValue,
      )
          .toList(),
      flightTimePerBatteryMinutes:
      flightTime,
      totalBatteries:
      totalBatteries,
      batteryType:
      _batteryTypeController.text
          .trim()
          .isEmpty
          ? null
          : _batteryTypeController.text
          .trim(),
      batteryUsageFee:
      double.tryParse(
        _batteryUsageController.text
            .trim(),
      ),
      hourlyRate:
      hourlyRate,
      dailyRate:
      dailyRate,
      emergencyCalloutFee:
      emergencyFee,
    );

    final updatedDraft =
    widget.draft.copyWith(
      drone:
      drone,
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
          return PilotRegisterStepFourScreen(
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
          SnackBarBehavior
              .floating,

          elevation: 8,

          margin:
          const EdgeInsets
              .all(18),

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
            BorderRadius
                .circular(
              16,
            ),
          ),

          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.15,
                  ),

                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  isError
                      ? Icons
                      .error_outline_rounded
                      : Icons
                      .check_rounded,

                  color:
                  Colors.white,

                  size: 20,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Text(
                  message,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,

                    fontSize:
                    12.5,

                    fontWeight:
                    FontWeight
                        .w600,

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
          // DECORATIVE BACKGROUND
          // ==================================================================

          Positioned(
            top: -125,
            right: -105,

            child: IgnorePointer(
              child: Container(
                width: 285,
                height: 285,

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

                      Colors
                          .transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 620,
            left: -160,

            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,

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

                      Colors
                          .transparent,
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
                  const EdgeInsets
                      .fromLTRB(
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
                              _buildDroneBadge(),
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
                                'Your Drone',
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
                                'Add your aircraft details, flight capabilities and service rates.',
                                style:
                                TextStyle(
                                  fontSize:
                                  13.5,

                                  color:
                                  kTextMuted,

                                  fontWeight:
                                  FontWeight
                                      .w400,

                                  height: 1.5,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            // ================================================
                            // DRONE IMAGE
                            // ================================================

                            _animatedEntry(
                              index: 4,

                              child: Center(
                                child:
                                _buildDroneImagePicker(),
                              ),
                            ),

                            const SizedBox(
                              height: 34,
                            ),

                            // ================================================
                            // AIRCRAFT DETAILS
                            // ================================================

                            _animatedEntry(
                              index: 5,

                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .flight_outlined,

                                title:
                                'Aircraft Details',

                                subtitle:
                                'Basic information about your drone',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 6,

                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  // Manufacturer
                                  _buildSmallLabel(
                                    'Make / Manufacturer',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _makeController,

                                    hintText:
                                    'e.g. DJI, Autel Robotics',

                                    prefixIcon: Icons
                                        .precision_manufacturing_outlined,

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
                                        return 'Make is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Model
                                  _buildSmallLabel(
                                    'Drone Model',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _modelController,

                                    hintText:
                                    'e.g. Mavic 3 Enterprise',

                                    prefixIcon: Icons
                                        .airplanemode_active_rounded,

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
                                        return 'Model is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Year
                                  _buildSmallLabel(
                                    'Year of Manufacture',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildSelectField(
                                    hintText:
                                    'Select Year',

                                    icon: Icons
                                        .calendar_month_rounded,

                                    value:
                                    _selectedYear,

                                    items: _years,

                                    onChanged:
                                        (value) {
                                      setState(
                                            () {
                                          _selectedYear =
                                              value;
                                        },
                                      );
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Serial
                                  _buildSmallLabel(
                                    'Serial Number',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _serialController,

                                    hintText:
                                    'e.g. 1581F4ARX2109',

                                    prefixIcon: Icons
                                        .confirmation_number_outlined,

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
                                        return 'Serial number is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Weight
                                  _buildSmallLabel(
                                    'Drone Weight (kg)',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _weightController,

                                    hintText:
                                    'e.g. 1.2',

                                    prefixIcon: Icons
                                        .fitness_center_rounded,

                                    keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                      decimal:
                                      true,
                                    ),

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
                                        return 'Weight is required';
                                      }

                                      final weight =
                                      double
                                          .tryParse(
                                        value
                                            .trim(),
                                      );

                                      if (weight ==
                                          null ||
                                          weight <=
                                              0) {
                                        return 'Enter a valid weight';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Accessories
                                  _buildSmallLabel(
                                    'Accessories & Payload',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildMultiSelectField(
                                    hintText:
                                    'Select accessories',

                                    icon: Icons
                                        .add_box_outlined,

                                    selectedItems:
                                    _selectedAccessories,

                                    items:
                                    _availableAccessories,

                                    onChanged:
                                        (updated) {
                                      setState(
                                            () {
                                          _selectedAccessories =
                                              updated;
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 32,
                            ),

                            // ================================================
                            // FLIGHT INFORMATION
                            // ================================================

                            _animatedEntry(
                              index: 7,

                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .flight_takeoff_rounded,

                                title:
                                'Flight Information',

                                subtitle:
                                'Battery and flight capabilities',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 8,

                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  _buildSmallLabel(
                                    'Flight Time per Battery (hours)',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _flightTimeController,

                                    hintText:
                                    'e.g. 3',

                                    prefixIcon:
                                    Icons
                                        .timer_outlined,

                                    keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                      decimal:
                                      true,
                                    ),

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
                                        return 'Flight time is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  _buildSmallLabel(
                                    'Total Batteries',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _totalBatteriesController,

                                    hintText:
                                    'e.g. 4',

                                    prefixIcon: Icons
                                        .battery_full_rounded,

                                    keyboardType:
                                    TextInputType
                                        .number,

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
                                        return 'Total batteries is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  _buildSmallLabel(
                                    'Battery Type',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _batteryTypeController,

                                    hintText:
                                    'e.g. Lithium',

                                    prefixIcon: Icons
                                        .battery_charging_full_rounded,

                                    textInputAction:
                                    TextInputAction
                                        .next,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 32,
                            ),

                            // ================================================
                            // SERVICE RATES
                            // ================================================

                            _animatedEntry(
                              index: 9,

                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .payments_outlined,

                                title:
                                'Service Rates',

                                subtitle:
                                'Set your standard pricing',
                              ),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            _animatedEntry(
                              index: 10,

                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  // Battery Usage Fee
                                  _buildSmallLabel(
                                    'Battery Usage Fee',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _batteryUsageController,

                                    hintText:
                                    'e.g. 50',

                                    prefixIcon: Icons
                                        .battery_saver_rounded,

                                    keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                      decimal:
                                      true,
                                    ),

                                    textInputAction:
                                    TextInputAction
                                        .next,
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Hourly
                                  _buildSmallLabel(
                                    'Hourly Rate',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _hourlyRateController,

                                    hintText:
                                    'e.g. 50',

                                    prefixIcon: Icons
                                        .attach_money_rounded,

                                    keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                      decimal:
                                      true,
                                    ),

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
                                        return 'Hourly rate is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Daily
                                  _buildSmallLabel(
                                    'Daily Rate',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _dailyRateController,

                                    hintText:
                                    'e.g. 350',

                                    prefixIcon: Icons
                                        .calendar_today_rounded,

                                    keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                      decimal:
                                      true,
                                    ),

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
                                        return 'Daily rate is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Emergency
                                  _buildSmallLabel(
                                    'Emergency / Call-Out Fee',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _emergencyFeeController,

                                    hintText:
                                    'e.g. 100',

                                    prefixIcon:
                                    Icons
                                        .bolt_rounded,

                                    keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                      decimal:
                                      true,
                                    ),

                                    textInputAction:
                                    TextInputAction
                                        .done,

                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Emergency fee is required';
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
                            // NEXT
                            // ================================================

                            _animatedEntry(
                              index: 11,

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
                BorderRadius
                    .circular(
                  20,
                ),

                border:
                Border.all(
                  color: kBorder,
                ),
              ),

              child: const Text(
                'STEP 3 OF 4',

                style: TextStyle(
                  fontSize: 10,

                  letterSpacing:
                  0.5,

                  fontWeight:
                  FontWeight
                      .w700,

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
          children:
          List.generate(
            4,
                (index) {
              final active =
                  index <= 2;

              return Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.only(
                    right:
                    index == 3
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

                    curve: Curves
                        .easeOutCubic,

                    height: 4,

                    decoration:
                    BoxDecoration(
                      color: active
                          ? kPrimary
                          : kBorder,

                      borderRadius:
                      BorderRadius
                          .circular(
                        20,
                      ),

                      boxShadow:
                      active
                          ? [
                        BoxShadow(
                          color: kPrimary.withOpacity(
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

  Widget _buildDroneBadge() {
    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 11,
        vertical: 6,
      ),

      decoration:
      BoxDecoration(
        color: kPrimary
            .withOpacity(
          0.085,
        ),

        borderRadius:
        BorderRadius
            .circular(
          20,
        ),
      ),

      child: const Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Icon(
            Icons
                .flight_takeoff_rounded,

            color: kPrimary,

            size: 14,
          ),

          SizedBox(
            width: 6,
          ),

          Text(
            'AIRCRAFT PROFILE',

            style: TextStyle(
              color: kPrimary,

              fontSize: 10,

              fontWeight:
              FontWeight
                  .w700,

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
            color: kPrimary
                .withOpacity(
              0.09,
            ),

            borderRadius:
            BorderRadius
                .circular(
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
            CrossAxisAlignment
                .start,

            children: [
              Text(
                title,

                style:
                const TextStyle(
                  fontSize: 15,

                  fontWeight:
                  FontWeight
                      .w700,

                  color:
                  kTextDark,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                subtitle,

                maxLines: 2,

                overflow:
                TextOverflow
                    .ellipsis,

                style:
                const TextStyle(
                  fontSize: 10.5,

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

  Widget _buildSmallLabel(
      String label,
      ) {
    return Text(
      label,

      style: const TextStyle(
        fontSize: 12.5,

        fontWeight:
        FontWeight.w700,

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
        BorderRadius.circular(
          50,
        ),

        onTap: _isSubmitting
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

            shape:
            BoxShape.circle,

            border:
            Border.all(
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
  // DRONE IMAGE UI
  // ==========================================================================

  Widget _buildDroneImagePicker() {
    return AnimatedBuilder(
      animation:
      _droneFloatAnimation,

      builder: (
          context,
          child,
          ) {
        return Transform
            .translate(
          offset: Offset(
            0,
            _droneFloatAnimation
                .value,
          ),

          child: child,
        );
      },

      child: GestureDetector(
        onTap:
        _showImageSourceActionSheet,

        child: Column(
          children: [
            Stack(
              clipBehavior:
              Clip.none,

              children: [
                Container(
                  width: 132,
                  height: 132,

                  decoration:
                  BoxDecoration(
                    borderRadius:
                    BorderRadius
                        .circular(
                      30,
                    ),

                    gradient:
                    LinearGradient(
                      begin:
                      Alignment
                          .topLeft,

                      end:
                      Alignment
                          .bottomRight,

                      colors: [
                        kPrimary
                            .withOpacity(
                          0.20,
                        ),

                        kPrimary
                            .withOpacity(
                          0.035,
                        ),
                      ],
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: kPrimary
                            .withOpacity(
                          0.12,
                        ),

                        blurRadius:
                        25,

                        offset:
                        const Offset(
                          0,
                          9,
                        ),
                      ),
                    ],
                  ),

                  padding:
                  const EdgeInsets
                      .all(
                    4,
                  ),

                  child: Container(
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius
                          .circular(
                        27,
                      ),
                    ),

                    padding:
                    const EdgeInsets
                        .all(
                      3,
                    ),

                    child: ClipRRect(
                      borderRadius:
                      BorderRadius
                          .circular(
                        24,
                      ),

                      child:
                      AnimatedSwitcher(
                        duration:
                        const Duration(
                          milliseconds:
                          300,
                        ),

                        child: _isPickingImage
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
                              color:
                              kPrimary,

                              strokeWidth:
                              2.3,
                            ),
                          ),
                        )
                            : _droneImage != null
                            ? Image.file(
                          _droneImage!,

                          key:
                          ValueKey(
                            _droneImage!
                                .path,
                          ),

                          fit:
                          BoxFit.cover,

                          width:
                          double.infinity,

                          height:
                          double.infinity,

                          errorBuilder:
                              (
                              context,
                              error,
                              stackTrace,
                              ) {
                            return _buildDronePlaceholder();
                          },
                        )
                            : _buildDronePlaceholder(),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: -3,
                  bottom: -3,

                  child: Container(
                    width: 36,
                    height: 36,

                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape
                          .circle,

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

                        width: 3,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: kPrimary
                              .withOpacity(
                            0.25,
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

                    child: Icon(
                      _droneImage ==
                          null
                          ? Icons
                          .add_a_photo_rounded
                          : Icons
                          .edit_rounded,

                      color:
                      Colors.white,

                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 13,
            ),

            Text(
              _droneImage == null
                  ? 'Add drone photo'
                  : 'Change drone photo',

              style:
              const TextStyle(
                fontSize: 12.5,

                fontWeight:
                FontWeight
                    .w700,

                color: kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDronePlaceholder() {
    return Container(
      color:
      const Color(
        0xFFF2F6F8,
      ),

      child: Stack(
        alignment:
        Alignment.center,

        children: [
          Positioned(
            top: 18,
            right: 16,

            child: Container(
              width: 26,
              height: 26,

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
          ),

          const Icon(
            Icons
                .flight_takeoff_rounded,

            size: 59,

            color: Color(
              0xFFBAC8CF,
            ),
          ),
        ],
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

    String? Function(String?)?
    validator,
  }) {
    return TextFormField(
      controller: controller,

      enabled: !_isSubmitting,

      keyboardType:
      keyboardType,

      textInputAction:
      textInputAction,

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
        hintText:
        hintText,

        hintStyle:
        const TextStyle(
          color: kHint,

          fontSize: 13,

          fontWeight:
          FontWeight.w400,
        ),

        prefixIcon:
        prefixIcon != null
            ? Icon(
          prefixIcon,

          size: 18,

          color: kHint,
        )
            : null,

        errorStyle:
        const TextStyle(
          fontSize: 10.5,

          color: kDanger,

          height: 1.2,
        ),

        filled: true,

        fillColor:
        Colors.white,

        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal: 14,
          vertical: 15,
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
            color: kBorder,

            width: 0.8,
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
            color: kBorder,

            width: 0.8,
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
            color: kPrimary,

            width: 1.4,
          ),
        ),

        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius
              .circular(
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
          BorderRadius
              .circular(
            15,
          ),

          borderSide:
          const BorderSide(
            color: kDanger,

            width: 1.3,
          ),
        ),

        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius
              .circular(
            15,
          ),

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
  // YEAR SELECT FIELD
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
          BorderRadius
              .circular(
            15,
          ),

          onTap: _isSubmitting
              ? null
              : () {
            _openSelectSheet(
              title:
              'Year of Manufacture',

              items: items,

              selected:
              value,

              onSelected:
                  (
                  selectedValue,
                  ) {
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
            width:
            double.infinity,

            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
              vertical: 14,
            ),

            decoration:
            BoxDecoration(
              color:
              Colors.white,

              borderRadius:
              BorderRadius
                  .circular(
                15,
              ),

              border:
              Border.all(
                color: state
                    .hasError
                    ? kDanger
                    : kBorder,

                width: state
                    .hasError
                    ? 1
                    : 0.8,
              ),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                Row(
                  children: [
                    Icon(
                      icon,

                      size: 18,

                      color:
                      hasValue
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

                        style:
                        TextStyle(
                          fontSize:
                          13.5,

                          fontWeight:
                          hasValue
                              ? FontWeight.w600
                              : FontWeight.w400,

                          color:
                          hasValue
                              ? kTextDark
                              : kHint,
                        ),
                      ),
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
                    const EdgeInsets
                        .only(
                      top: 7,
                      left: 28,
                    ),

                    child: Text(
                      state
                          .errorText!,

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
  // YEAR SHEET
  // ==========================================================================

  Future<void> _openSelectSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?>
    onSelected,
  }) async {
    HapticFeedback
        .lightImpact();

    await showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.68,

            child: Container(
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
                    height: 18,
                  ),

                  Padding(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal:
                      18,
                    ),

                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,

                            style:
                            const TextStyle(
                              fontSize:
                              18,

                              fontWeight:
                              FontWeight
                                  .w800,

                              color:
                              kTextDark,
                            ),
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
                            Icons
                                .close_rounded,

                            color:
                            kHint,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Expanded(
                    child:
                    ListView.separated(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        18,
                        0,
                        18,
                        18,
                      ),

                      itemCount:
                      items.length,

                      separatorBuilder:
                          (
                          context,
                          index,
                          ) {
                        return const SizedBox(
                          height: 8,
                        );
                      },

                      itemBuilder:
                          (
                          context,
                          index,
                          ) {
                        final item =
                        items[
                        index];

                        final isSelected =
                            item ==
                                selected;

                        return Material(
                          color: isSelected
                              ? kPrimary
                              .withOpacity(
                            0.08,
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

                            onTap:
                                () {
                              HapticFeedback
                                  .selectionClick();

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
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                15,

                                vertical:
                                13,
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
                                      color: isSelected
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
                                      Icons
                                          .calendar_month_rounded,

                                      size:
                                      17,

                                      color: isSelected
                                          ? kPrimary
                                          : kHint,
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
                                        color: isSelected
                                            ? kPrimary
                                            : kTextDark,

                                        fontSize:
                                        13.5,

                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  if (isSelected)
                                    const Icon(
                                      Icons
                                          .check_circle_rounded,

                                      color:
                                      kPrimary,

                                      size:
                                      20,
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
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // ACCESSORIES FIELD
  // ==========================================================================

  Widget _buildMultiSelectField({
    required String hintText,
    required IconData icon,
    required Set<String> selectedItems,
    required List<String> items,
    required ValueChanged<Set<String>>
    onChanged,
  }) {
    final hasSelection =
        selectedItems.isNotEmpty;

    return InkWell(
      borderRadius:
      BorderRadius.circular(
        15,
      ),

      onTap: _isSubmitting
          ? null
          : () {
        _openMultiSelectSheet(
          title:
          'Accessories & Payload',

          items: items,

          selectedItems:
          selectedItems,

          onConfirm:
          onChanged,
        );
      },

      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 220,
        ),

        width:
        double.infinity,

        constraints:
        const BoxConstraints(
          minHeight: 54,
        ),

        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 14,
          vertical: 12,
        ),

        decoration:
        BoxDecoration(
          color:
          Colors.white,

          borderRadius:
          BorderRadius
              .circular(
            15,
          ),

          border:
          Border.all(
            color: hasSelection
                ? kPrimary
                .withOpacity(
              0.50,
            )
                : kBorder,

            width: hasSelection
                ? 1.1
                : 0.8,
          ),
        ),

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment
              .center,

          children: [
            Icon(
              icon,

              size: 18,

              color:
              hasSelection
                  ? kPrimary
                  : kHint,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: selectedItems
                  .isEmpty
                  ? Text(
                hintText,

                style:
                const TextStyle(
                  fontSize:
                  13,

                  color:
                  kHint,
                ),
              )
                  : Wrap(
                spacing: 6,

                runSpacing:
                6,

                children: [
                  ...selectedItems
                      .take(3)
                      .map(
                        (
                        item,
                        ) =>
                        _buildAccessoryChip(
                          item,
                          selectedItems,
                          onChanged,
                        ),
                  ),

                  if (selectedItems
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
                        color: kPrimary
                            .withOpacity(
                          0.09,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),

                      child: Text(
                        '+${selectedItems.length - 3}',

                        style:
                        const TextStyle(
                          color:
                          kPrimary,

                          fontSize:
                          10.5,

                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,

              size: 20,

              color: kHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessoryChip(
      String item,
      Set<String> selectedItems,
      ValueChanged<Set<String>>
      onChanged,
      ) {
    return Container(
      constraints:
      const BoxConstraints(
        maxWidth: 150,
      ),

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
          0.09,
        ),

        borderRadius:
        BorderRadius
            .circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Flexible(
            child: Text(
              item,

              maxLines: 1,

              overflow:
              TextOverflow
                  .ellipsis,

              style:
              const TextStyle(
                fontSize: 10.5,

                fontWeight:
                FontWeight
                    .w600,

                color:
                kPrimary,
              ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          GestureDetector(
            behavior:
            HitTestBehavior
                .opaque,

            onTap: () {
              HapticFeedback
                  .selectionClick();

              final updated =
              Set<String>.from(
                selectedItems,
              )..remove(item);

              onChanged(
                updated,
              );
            },

            child:
            const Icon(
              Icons.close_rounded,

              size: 13,

              color:
              kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ACCESSORIES SHEET
  // ==========================================================================

  Future<void> _openMultiSelectSheet({
    required String title,
    required List<String> items,
    required Set<String> selectedItems,
    required ValueChanged<Set<String>>
    onConfirm,
  }) async {
    HapticFeedback
        .lightImpact();

    final Set<String>
    tempSelected =
    Set<String>.from(
      selectedItems,
    );

    await showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.82,

                child: Container(
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
                        height: 18,
                      ),

                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          18,
                        ),

                        child: Row(
                          children: [
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
                                      fontSize:
                                      18,

                                      fontWeight:
                                      FontWeight
                                          .w800,

                                      color:
                                      kTextDark,
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                    2,
                                  ),

                                  const Text(
                                    'Select all equipment available with your drone',

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
                                Icons
                                    .close_rounded,

                                color:
                                kHint,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          18,
                        ),

                        child: Row(
                          children: [
                            const Text(
                              'Available Accessories',

                              style:
                              TextStyle(
                                fontSize:
                                11,

                                color:
                                kTextMuted,

                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                            ),

                            const Spacer(),

                            AnimatedContainer(
                              duration:
                              const Duration(
                                milliseconds:
                                180,
                              ),

                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                9,

                                vertical:
                                5,
                              ),

                              decoration:
                              BoxDecoration(
                                color: tempSelected
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
                                '${tempSelected.length} selected',

                                style:
                                TextStyle(
                                  fontSize:
                                  10.5,

                                  fontWeight:
                                  FontWeight
                                      .w700,

                                  color: tempSelected
                                      .isEmpty
                                      ? kTextMuted
                                      : kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Expanded(
                        child:
                        ListView.separated(
                          padding:
                          const EdgeInsets
                              .fromLTRB(
                            18,
                            0,
                            18,
                            8,
                          ),

                          itemCount:
                          items.length,

                          separatorBuilder:
                              (
                              context,
                              index,
                              ) {
                            return const SizedBox(
                              height:
                              8,
                            );
                          },

                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            final item =
                            items[
                            index];

                            final selected =
                            tempSelected
                                .contains(
                              item,
                            );

                            return Material(
                              color: selected
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
                                  HapticFeedback
                                      .selectionClick();

                                  setSheetState(
                                        () {
                                      if (selected) {
                                        tempSelected.remove(
                                          item,
                                        );
                                      } else {
                                        tempSelected.add(
                                          item,
                                        );
                                      }
                                    },
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
                                      color: selected
                                          ? kPrimary
                                          : Colors.transparent,
                                    ),
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
                                        23,

                                        height:
                                        23,

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

                                          color: Colors.white,

                                          size: 15,
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
                                          item,

                                          style:
                                          TextStyle(
                                            fontSize:
                                            13.5,

                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,

                                            color: selected
                                                ? kPrimary
                                                : kTextDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding:
                        const EdgeInsets
                            .fromLTRB(
                          18,
                          8,
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
                                () {
                              HapticFeedback
                                  .mediumImpact();

                              onConfirm(
                                Set<String>.from(
                                  tempSelected,
                                ),
                              );

                              Navigator.pop(
                                context,
                              );
                            },

                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              kPrimary,

                              foregroundColor:
                              Colors.white,

                              elevation:
                              0,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  25,
                                ),
                              ),
                            ),

                            child: Text(
                              tempSelected
                                  .isEmpty
                                  ? 'Done'
                                  : 'Done • ${tempSelected.length} Selected',

                              style:
                              const TextStyle(
                                fontSize:
                                13.5,

                                fontWeight:
                                FontWeight
                                    .w700,
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

  // ==========================================================================
  // PRIMARY BUTTON
  // ==========================================================================

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback?
    onPressed,
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
            BorderRadius
                .circular(
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
                color: kPrimary
                    .withOpacity(
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
            ElevatedButton
                .styleFrom(
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

                        fontSize:
                        15,

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
            Icons
                .verified_user_outlined,

            size: 12,

            color: kTextMuted,
          ),

          SizedBox(
            width: 5,
          ),

          Flexible(
            child: Text(
              'Make sure your aircraft information is accurate.',

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

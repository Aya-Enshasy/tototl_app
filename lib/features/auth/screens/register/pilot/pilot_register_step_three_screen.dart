import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/auth/screens/register/pilot/pilot_register_step_four_screen.dart';

class PilotRegisterStepThreeScreen extends StatefulWidget {
  const PilotRegisterStepThreeScreen({super.key});

  @override
  State<PilotRegisterStepThreeScreen> createState() =>
      _PilotRegisterStepThreeScreenState();
}

class _PilotRegisterStepThreeScreenState
    extends State<PilotRegisterStepThreeScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

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

  String? _selectedYear;
  File? _droneImage;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  // Accessories multi-select state
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

  final ImagePicker _picker = ImagePicker();
  late final List<String> _years = List.generate(
    15,
        (index) => (DateTime.now().year - index).toString(),
  );

  static const Color kPrimary = AppColors.primary;
  static const Color kPrimarySoft = AppColors.blueBg;
  static const Color kTextDark = AppColors.text;
  static const Color kTextMuted = AppColors.grey;
  static const Color kHint = AppColors.lightGrey;
  static const Color kBorder = AppColors.border;
  static const Color kSurfaceSoft = AppColors.bg;
  static const Color kDanger = AppColors.red;

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
    super.dispose();
  }

  Future<void> _pickDroneImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked == null) return;

      final file = File(picked.path);
      if (await file.exists() && mounted) {
        setState(() => _droneImage = file);
      }
    } on PlatformException catch (_) {
      if (mounted) {
        _showSnack('Unable to open the image picker. Check app permissions.');
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Unable to upload this image. Please try another photo.');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kTextDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showImageSourceActionSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Drone Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSheetOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take a Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDroneImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose from Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDroneImage(ImageSource.gallery);
                    },
                  ),
                  if (_droneImage != null) ...[
                    const SizedBox(height: 10),
                    _buildSheetOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove Photo',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _droneImage = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? kDanger : kPrimary;
    return Material(
      color: kSurfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? color : kTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSelectSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == selected;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isSelected ? kPrimarySoft : kSurfaceSoft,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onSelected(item);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? kPrimary
                                        : Colors.transparent,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected ? kPrimary : kTextDark,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 20,
                                        color: kPrimary,
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
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Multi-select Bottom Sheet (used for Accessories)
  // ---------------------------------------------------------------------
  Future<void> _openMultiSelectSheet({
    required String title,
    required List<String> items,
    required Set<String> selectedItems,
    required ValueChanged<Set<String>> onConfirm,
  }) async {
    HapticFeedback.lightImpact();
    Set<String> tempSelected = Set<String>.from(selectedItems);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Material(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: kBorder,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                          ),
                          Text(
                            '${tempSelected.length} selected',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: kTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.45,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = tempSelected.contains(item);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color:
                                isSelected ? kPrimarySoft : kSurfaceSoft,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setSheetState(() {
                                      isSelected
                                          ? tempSelected.remove(item)
                                          : tempSelected.add(item);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_box_rounded
                                              : Icons
                                              .check_box_outline_blank_rounded,
                                          size: 20,
                                          color:
                                          isSelected ? kPrimary : kHint,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? kPrimary
                                                  : kTextDark,
                                            ),
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
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            onConfirm(tempSelected);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (_selectedYear == null) {
      _showSnack('Please select manufacturing year');
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const PilotRegisterStepFourScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.3, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                Row(
                  children: [
                    _buildBackButton(),
                    const Spacer(),
                    _buildAnimatedStepIndicator(currentStep: 3),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 28),

                // Title & Subtitle
                const Text(
                  'Your\nDrone',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add the aircraft details you use for missions',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 26),

                // Drone Image Upload Section
                Center(child: _buildDroneImagePicker()),
                const SizedBox(height: 28),

                // Make / Manufacturer
                _buildSectionLabel('Make / Manufacturer'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _makeController,
                  hintText: 'e.g. DJI, Autel Robotics',
                  suffixIcon: const Icon(
                    Icons.precision_manufacturing_outlined,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Make is required' : null,
                ),
                const SizedBox(height: 16),

                // Model
                _buildSectionLabel('Drone Model'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _modelController,
                  hintText: 'e.g. Mavic 3 Enterprise',
                  suffixIcon: const Icon(
                    Icons.airplanemode_active_rounded,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Model is required' : null,
                ),
                const SizedBox(height: 16),

                // Year Selection
                _buildSectionLabel('Year of Manufacture'),
                const SizedBox(height: 8),
                _buildSelectField(
                  hintText: 'Select Year',
                  icon: Icons.calendar_month_rounded,
                  value: _selectedYear,
                  items: _years,
                  onChanged: (val) => setState(() => _selectedYear = val),
                ),
                const SizedBox(height: 16),

                // Serial Number
                _buildSectionLabel('Serial Number'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _serialController,
                  hintText: 'e.g. 1581F4ARX2109',
                  suffixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Serial number is required' : null,
                ),
                const SizedBox(height: 16),

                // Drone Weight
                _buildSectionLabel('Drone Weight (kg)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _weightController,
                  hintText: 'e.g. 1.2',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffixIcon: const Icon(
                    Icons.fitness_center_rounded,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Weight is required' : null,
                ),
                const SizedBox(height: 16),

                // Accessories (Optional) — Multi-select dropdown
                _buildSectionLabel('Accessories & Payload'),
                const SizedBox(height: 8),
                _buildMultiSelectField(
                  hintText: 'Select accessories',
                  icon: Icons.add_box_outlined,
                  selectedItems: _selectedAccessories,
                  items: _availableAccessories,
                  onChanged: (updated) =>
                      setState(() => _selectedAccessories = updated),
                ),

                // ---------------------------------------------------------
                // Flight Information
                // ---------------------------------------------------------
                const SizedBox(height: 28),
                _buildGroupHeader('✈️', 'Flight Information'),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Flight Time per Battery (hours)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _flightTimeController,
                            hintText: 'e.g. 3',
                            keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            suffixIcon: const Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: kHint,
                            ),
                            validator: (value) => value == null ||
                                value.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Total Batteries'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _totalBatteriesController,
                            hintText: 'e.g. 4',
                            keyboardType: TextInputType.number,
                            suffixIcon: const Icon(
                              Icons.battery_full_rounded,
                              size: 18,
                              color: kHint,
                            ),
                            validator: (value) => value == null ||
                                value.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Battery Type'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _batteryTypeController,
                  hintText: 'e.g. Lithium',
                  suffixIcon: const Icon(
                    Icons.battery_charging_full_rounded,
                    size: 18,
                    color: kHint,
                  ),
                ),

                // ---------------------------------------------------------
                // Service Rates
                // ---------------------------------------------------------
                const SizedBox(height: 26),
                _buildGroupHeader('💰', 'Service Rates'),
                const SizedBox(height: 14),
                _buildSectionLabel('Battery Usage Fee'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _batteryUsageController,
                  hintText: 'e.g. 50',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffixIcon: const Icon(
                    Icons.battery_saver_rounded,
                    size: 18,
                    color: kHint,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Hourly Rate'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _hourlyRateController,
                  hintText: 'e.g. 50',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffixIcon: const Icon(
                    Icons.attach_money_rounded,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Daily Rate'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _dailyRateController,
                  hintText: 'e.g. 350',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Emergency / Call-Out Fee'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emergencyFeeController,
                  hintText: 'e.g. 100',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffixIcon: const Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: kHint,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 32),

                // Next Button
                _buildPrimaryButton(
                  text: 'Next',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleNext,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Custom UI Helpers & Subwidgets
  // ---------------------------------------------------------------------

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: kTextDark,
      ),
    );
  }

  /// عنوان مجموعة حقول (زي "Flight Information" أو "Service Rates")
  /// مع إيموجي صغير وخط فاصل بسيط قبله.
  Widget _buildGroupHeader(String emoji, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: kBorder),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kTextDark,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 13,
          color: kTextDark,
        ),
      ),
    );
  }

  Widget _buildDroneImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _droneImage == null ? kBorder : kPrimary,
                width: _droneImage == null ? 0.8 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: _isPickingImage
                  ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: kPrimary,
                  ),
                ),
              )
                  : _droneImage != null
                  ? Image.file(
                _droneImage!,
                key: ValueKey(_droneImage!.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.airplanemode_active_rounded,
                    size: 58,
                    color: kHint,
                  );
                },
              )
                  : Container(
                color: kSurfaceSoft,
                child: const Icon(
                  Icons.airplanemode_active_rounded,
                  size: 58,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _droneImage == null
                    ? Icons.add_a_photo_rounded
                    : Icons.edit_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStepIndicator({required int currentStep}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == currentStep;
        final isPassed = stepNumber < currentStep;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              width: isActive ? 22 : 18,
              height: isActive ? 22 : 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isPassed ? kPrimary : Colors.white,
                border: Border.all(
                  color: isActive || isPassed ? kPrimary : kBorder,
                  width: isActive ? 0 : 1.2,
                ),
              ),
              child: Center(
                child: isPassed
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : kHint,
                  ),
                ),
              ),
            ),
            if (index < 3)
              Container(
                width: 26,
                height: 1.5,
                color: stepNumber < currentStep ? kPrimary : kBorder,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 13.5,
        color: kTextDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: kHint,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(fontSize: 11, color: kDanger),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDanger, width: 1),
        ),
      ),
    );
  }

  Widget _buildSelectField({
    required String hintText,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return FormField<String>(
      initialValue: value,
      validator: (v) => value == null ? 'Selection is required' : null,
      builder: (state) {
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openSelectSheet(
            title: hintText,
            items: items,
            selected: value,
            onSelected: (val) {
              onChanged(val);
              state.didChange(val);
            },
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: state.hasError ? kDanger : kBorder,
                width: state.hasError ? 1 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: kHint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        value ?? hintText,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: value == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: value == null ? kHint : kTextDark,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: kHint,
                    ),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 28),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(fontSize: 11, color: kDanger),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Multi-select "field" that looks like a TextField and shows selected chips
  Widget _buildMultiSelectField({
    required String hintText,
    required IconData icon,
    required Set<String> selectedItems,
    required List<String> items,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openMultiSelectSheet(
        title: hintText,
        items: items,
        selectedItems: selectedItems,
        onConfirm: onChanged,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: kHint),
            const SizedBox(width: 10),
            Expanded(
              child: selectedItems.isEmpty
                  ? Text(
                hintText,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: kHint,
                  fontWeight: FontWeight.w400,
                ),
              )
                  : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedItems.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimarySoft,
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: kPrimary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final updated =
                            Set<String>.from(selectedItems)
                              ..remove(item);
                            onChanged(updated);
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: kHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null && !isLoading ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), kPrimary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
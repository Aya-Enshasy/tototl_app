import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'company_register_step_four_screen.dart';

class CompanyRegisterStepThreeScreen extends StatefulWidget {
  const CompanyRegisterStepThreeScreen({super.key});

  @override
  State<CompanyRegisterStepThreeScreen> createState() =>
      _CompanyRegisterStepThreeScreenState();
}

class _CompanyRegisterStepThreeScreenState
    extends State<CompanyRegisterStepThreeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Theme colors (same palette used across the flow)
  static const Color kPrimary = Color(0xFF3F6DFB);
  static const Color kPrimarySoft = Color(0xFFEBF1FF);
  static const Color kTextDark = Color(0xFF1A1A1A);
  static const Color kTextMuted = Color(0xFF8F93A3);
  static const Color kBorder = Color(0xFFE5E7EB);
  static const Color kSurfaceSoft = Color(0xFFF9FAFB);
  static const Color kDanger = Color(0xFFEF4444);

  // 1. Job Types (multi-select)
  final List<String> _jobTypes = [
    'Inspection',
    'Mapping',
    'Photography',
    'Construction Monitoring',
    'Surveying',
    'Other',
  ];
  Set<String> _selectedJobTypes = {};
  final TextEditingController _otherJobTypeController =
  TextEditingController();

  // 2. Drone Requirements (multi-select)
  final List<String> _droneRequirements = [
    'Thermal Camera',
    'Laser',
    'Night Vision',
    'LiDAR',
    'Radar',
    'Imaging',
  ];
  Set<String> _selectedDroneRequirements = {};

  // 3. Drone Size Requirement (single-select)
  String? _selectedDroneSize;
  final List<String> _droneSizes = ['Small', 'Medium', 'Large'];

  // 4. Safety Requirements
  bool _safetyTrainingRequired = false;
  bool _specialCertificationsRequired = false;

  // 5. Other Requirements Controller
  final TextEditingController _otherRequirementsController =
  TextEditingController();

  // 6. Job Site Options
  bool _includePIDs = false;
  bool _includeImages = false;

  @override
  void dispose() {
    _otherRequirementsController.dispose();
    _otherJobTypeController.dispose();
    super.dispose();
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

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedJobTypes.isEmpty) {
      _showSnack('Please select at least one Job Type');
      return;
    }
    if (_selectedJobTypes.contains('Other') &&
        _otherJobTypeController.text.trim().isEmpty) {
      _showSnack('Please specify the other job type');
      return;
    }
    if (_selectedDroneSize == null) {
      _showSnack('Please select a Drone Size Requirement');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyRegisterStepFourScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Multi-select Bottom Sheet (used for Job Types & Drone Requirements)
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
                                          color: isSelected
                                              ? kPrimary
                                              : kTextMuted,
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

  // Field that looks like a bordered input, opens the multi-select sheet,
  // and displays selected values as removable chips inside the field.
  Widget _buildMultiSelectField({
    required String hintText,
    required IconData icon,
    required Set<String> selectedItems,
    required List<String> items,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openMultiSelectSheet(
        title: hintText,
        items: items,
        selectedItems: selectedItems,
        onConfirm: onChanged,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kSurfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: kTextMuted),
            const SizedBox(width: 10),
            Expanded(
              child: selectedItems.isEmpty
                  ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  hintText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA0A5BA),
                    fontWeight: FontWeight.w400,
                  ),
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
              color: Color(0xFF9CA3AF),
            ),
          ],
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
                // Top Navigation Bar
                Row(
                  children: [
                    _buildBackButton(),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(currentStep: 3),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
                const SizedBox(height: 30),

                // Title & Subtitle
                const Text(
                  'Job Requirements',
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
                  'Define your drone job specifications to match suitable pilots',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // Job Types (multi-select dropdown field)
                const Text(
                  'Job Types',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select all services required for your projects',
                  style: TextStyle(fontSize: 12.5, color: kTextMuted),
                ),
                const SizedBox(height: 12),
                _buildMultiSelectField(
                  hintText: 'Select job types',
                  icon: Icons.work_outline_rounded,
                  selectedItems: _selectedJobTypes,
                  items: _jobTypes,
                  onChanged: (updated) =>
                      setState(() => _selectedJobTypes = updated),
                ),
                // "Other" text field appears only when Other is selected
                if (_selectedJobTypes.contains('Other')) ...[
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _otherJobTypeController,
                    hintText: 'Please specify the job type',
                  ),
                ],
                const SizedBox(height: 24),

                // Drone Requirements (multi-select dropdown field)
                const Text(
                  'Drone Equipment & Sensors',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select required sensors and cameras',
                  style: TextStyle(fontSize: 12.5, color: kTextMuted),
                ),
                const SizedBox(height: 12),
                _buildMultiSelectField(
                  hintText: 'Select equipment & sensors',
                  icon: Icons.sensors_rounded,
                  selectedItems: _selectedDroneRequirements,
                  items: _droneRequirements,
                  onChanged: (updated) =>
                      setState(() => _selectedDroneRequirements = updated),
                ),
                const SizedBox(height: 24),

                // Drone Size Requirement
                const Text(
                  'Drone Size Requirement',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _droneSizes.map((size) {
                    final isSelected = _selectedDroneSize == size;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _selectedDroneSize = size);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? kPrimary : kSurfaceSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? kPrimary : kBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                size,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? Colors.white : kTextDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Safety Requirements
                const Text(
                  'Safety Requirements',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCheckboxRow(
                  title: 'Safety Training Required',
                  value: _safetyTrainingRequired,
                  onChanged: (val) {
                    setState(() => _safetyTrainingRequired = val ?? false);
                  },
                ),
                _buildCheckboxRow(
                  title: 'Special Certifications Required',
                  value: _specialCertificationsRequired,
                  onChanged: (val) {
                    setState(
                            () => _specialCertificationsRequired = val ?? false);
                  },
                ),
                const SizedBox(height: 24),

                // Other Requirements
                const Text(
                  'Other Requirements',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _otherRequirementsController,
                  hintText:
                  'Any special permissions, insurance, or pilot experience...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Job Site Options
                const Text(
                  'Job Site Options',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCheckboxRow(
                  title: 'Include P&IDs of Job Site',
                  value: _includePIDs,
                  onChanged: (val) {
                    setState(() => _includePIDs = val ?? false);
                  },
                ),
                _buildCheckboxRow(
                  title: 'Include Images of Job Site',
                  value: _includeImages,
                  onChanged: (val) {
                    setState(() => _includeImages = val ?? false);
                  },
                ),
                const SizedBox(height: 32),

                // Next Button
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
                        color: kPrimary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleNext,
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
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
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
  // WIDGETS
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
                    color:
                    isActive ? Colors.white : const Color(0xFF9CA3AF),
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

  Widget _buildCheckboxRow({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  activeColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: kTextDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 14.5,
          color: kTextDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA0A5BA), fontSize: 14),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/features/auth/register/pilot/pilot_register_step_three_screen.dart';

// ===========================================================================
// SCREEN 2: Pilot Experience & Work Details
// ===========================================================================
class PilotRegisterStepTwoScreen extends StatefulWidget {
  const PilotRegisterStepTwoScreen({super.key});

  @override
  State<PilotRegisterStepTwoScreen> createState() =>
      _PilotRegisterStepTwoScreenState();
}

class _PilotRegisterStepTwoScreenState
    extends State<PilotRegisterStepTwoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  // Selection States
  String? _yearsOfExperience;
  final Set<String> _selectedLanguages = {'English', 'Arabic'};
  final Set<String> _selectedWillingRegions = {'Riyadh', 'Jeddah'};

  bool _isSubmitting = false;

  // Options Lists
  final List<String> _experienceYears = const [
    'Less than 1 year',
    '1-3 years',
    '3-5 years',
    'More than 5 years',
  ];

  final List<String> _availableLanguages = const [
    'English',
    'Arabic',
    'French',
    'Spanish',
    'Other',
  ];

  final List<String> _availableWillingRegions = const [
    'Riyadh',
    'Jeddah',
    'Dammam',
    'NEOM',
    'Dubai',
    'Abu Dhabi',
    'All Regions',
  ];

  // Application Theme Colors
  static const Color kPrimary = Color(0xFF1E56F0);
  static const Color kPrimarySoft = Color(0xFFEFF3FE);
  static const Color kTextDark = Color(0xFF0F172A);
  static const Color kTextMuted = Color(0xFF64748B);
  static const Color kHint = Color(0xFF94A3B8);
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kSurfaceSoft = Color(0xFFF8FAFC);
  static const Color kDanger = Color(0xFFEF4444);

  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _aboutController.dispose();
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

  // ---------------------------------------------------------------------
  // Bottom Sheet Selection Helper
  // ---------------------------------------------------------------------
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
                  ...items.map((item) {
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
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Navigation & Validation
  // ---------------------------------------------------------------------
  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (_yearsOfExperience == null) {
      _showSnack('Please select your years of experience');
      return;
    }

    if (_selectedLanguages.isEmpty) {
      _showSnack('Please select at least one language');
      return;
    }

    if (_selectedWillingRegions.isEmpty) {
      _showSnack('Please select at least one region you are willing to work in');
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
        const PilotRegisterStepThreeScreen(),
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
                    _buildAnimatedStepIndicator(currentStep: 2),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 28),

                // Screen Title & Subtitle
                const Text(
                  'Pilot Experience',
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
                  "Provide your professional background, skills, and work preferences.",
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // 1. Years of Experience
                _buildSectionLabel('Years of Experience'),
                const SizedBox(height: 8),
                _buildSelectField(
                  hintText: 'Select Experience Level',
                  icon: Icons.workspace_premium_outlined,
                  value: _yearsOfExperience,
                  items: _experienceYears,
                  onChanged: (val) => setState(() => _yearsOfExperience = val),
                ),
                const SizedBox(height: 20),

                // 2. Languages Spoken (Multi-select Chips)
                _buildSectionLabel('Languages'),
                const SizedBox(height: 8),
                _buildMultiSelectChips(
                  options: _availableLanguages,
                  selectedItems: _selectedLanguages,
                  onToggle: (lang) {
                    setState(() {
                      if (_selectedLanguages.contains(lang)) {
                        _selectedLanguages.remove(lang);
                      } else {
                        _selectedLanguages.add(lang);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 3. Current Region (Main Working Location)
                _buildSectionLabel('Current Region (Main Working Location)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _countryController,
                  hintText: 'Country (e.g. Saudi Arabia)',
                  prefixIcon: Icons.public_rounded,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Country is required' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        hintText: 'State / Region',
                        prefixIcon: Icons.map_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'State/Region is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        hintText: 'City',
                        prefixIcon: Icons.location_city_rounded,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'City is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Regions Willing To Work (Multi-select)
                _buildSectionLabel('Regions Willing To Work'),
                const SizedBox(height: 8),
                _buildMultiSelectChips(
                  options: _availableWillingRegions,
                  selectedItems: _selectedWillingRegions,
                  onToggle: (region) {
                    setState(() {
                      if (_selectedWillingRegions.contains(region)) {
                        _selectedWillingRegions.remove(region);
                      } else {
                        _selectedWillingRegions.add(region);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 5. About Me / Professional Description
                _buildSectionLabel('About Me / Professional Description'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _aboutController,
                  hintText:
                  'Describe your drone experience, skills, types of drone jobs you specialize in, and professional background...',
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Professional description is required'
                      : null,
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
  // Sub-Widgets
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

  Widget _buildAnimatedStepIndicator({required int currentStep}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        int stepNumber = index + 1;
        bool isActive = stepNumber == currentStep;
        bool isPassed = stepNumber < currentStep;

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

  Widget _buildMultiSelectChips({
    required List<String> options,
    required Set<String> selectedItems,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final isSelected = selectedItems.contains(item);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onToggle(item);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? kPrimarySoft : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? kPrimary : kBorder,
                width: isSelected ? 1.4 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded, size: 15, color: kPrimary),
                  const SizedBox(width: 5),
                ],
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? kPrimary : kTextDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
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
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: kHint)
            : null,
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
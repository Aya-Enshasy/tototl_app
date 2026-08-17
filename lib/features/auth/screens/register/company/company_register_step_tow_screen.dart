import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 import 'package:tototl_app/core/theme/app_colors.dart';
import '../../../models/country_model.dart';
import '../../../services/location_service.dart';
import 'company_register_step_four_screen.dart';
import 'company_register_step_three_screen.dart';

class CompanyRegisterStepTwoScreen extends StatefulWidget {
  const CompanyRegisterStepTwoScreen({super.key});

  @override
  State<CompanyRegisterStepTwoScreen> createState() =>
      _CompanyRegisterStepTwoScreenState();
}

class _CompanyRegisterStepTwoScreenState
    extends State<CompanyRegisterStepTwoScreen> {
  final _formKey = GlobalKey<FormState>();

  // متحكمات النصوص
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final LocationService _locationService = LocationService();

  List<CountryModel> _countries = [];

  CountryModel? _selectedCountry;

  final Set<String> _selectedWillingRegions = {};

  bool _isSubmitting = false;
  // حالة الموافقة على الشروط
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }



  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // if (_selectedRegions.isEmpty) {
    //   _showSnack('Please select at least one operating region');
    //   return;
    // }
    if (!_isAgreed) {
      _showSnack('Please agree to the User Contract Agreement & Terms');
      return;
    }

    // الانتقال للخطوة الثالثة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyRegisterStepFourScreen(),
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
                // 1. شريط العلوي (زر الرجوع + مؤشر 4 خطوات)
                // ==========================================
                Row(
                  children: [
                    _buildBackButton(),
                    Expanded(
                      child: Center(
                        child: _buildStepIndicator(currentStep: 2),
                      ),
                    ),
                    const SizedBox(width: 38), // لموازنة زر الرجوع
                  ],
                ),
                const SizedBox(height: 30),

                // ==========================================
                // 2. العناوين والنصوص (Header)
                // ==========================================
                const Text(
                  'Company\nProfile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Collect company information and operating areas',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // ==========================================
                // 3. حقول الموقع الجغرافي (Location Fields)
                // ==========================================

                // Country
                _buildTextField(
                  controller: _countryController,
                  hintText: 'Country',
                  prefixIcon: Icons.public_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Country is required' : null,
                ),
                const SizedBox(height: 14),

                // State / Province & City (في صف واحد)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        hintText: 'State / Province',
                        prefixIcon: Icons.map_outlined,
                        validator: (val) => val == null || val.trim().isEmpty ? 'State is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        hintText: 'City',
                        prefixIcon: Icons.location_city_rounded,
                        validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Company Address
                _buildTextField(
                  controller: _addressController,
                  hintText: 'Company Address',
                  prefixIcon: Icons.home_work_outlined,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 24),

                // ==========================================
                // 4. مناطق التشغيل (Operating Regions)
                // ==========================================
                const Text(
                  'Operating Regions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select regions where your company operates',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8F93A3),
                  ),
                ),
                const SizedBox(height: 12),

                _buildRegionSelector(),
                const SizedBox(height: 24),

                // ==========================================
                // 5. وصف الشركة (Company Description)
                // ==========================================
                const Text(
                  'Company Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionController,
                  hintText: 'Company background, services provided, industry experience...',
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please describe your company' : null,
                ),
                const SizedBox(height: 20),

                // ==========================================
                // 6. الموافقة على الشروط (Agreement Checkbox)
                // ==========================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isAgreed,
                        activeColor: const Color(0xFF16C6C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) {
                          setState(() => _isAgreed = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'User Contract Agreement and Terms & Conditions',
                              style: const TextStyle(
                                color: Color(0xFF16C6C7),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showTermsAndConditionsSheet,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ==========================================
                // 7. زر الانتقال للخطوة التالية (Next Button)
                // ==========================================
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF16C6C7),
                        Color(0xFF0D8AA5),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16C6C7).withOpacity(0.35),
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
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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
  // WIDGETS المخصصة لتناسب أسلوب وتصميم قسم الدرون
  // ===========================================================================

  // زر الرجوع المخصص بالدائرة المتناسقة
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

  // مؤشر الخطوات الـ 4 المخصص للشركة
  Widget _buildStepIndicator({required int currentStep}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
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
                    ? const Color(0xFF16C6C7)
                    : Colors.white,
                border: Border.all(
                  color: isActive || isPassed
                      ? const Color(0xFF16C6C7)
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
                color: isPassed ? const Color(0xFF16C6C7) : const Color(0xFFE5E7EB),
              ),
          ],
        );
      }),
    );
  }

  // بناء حقول النصوص بأسلوب الخانات الموحد
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    String? Function(String?)? validator,  int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(
        fontSize: 13.5,
        color: AppColors.kTextDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
            color: AppColors.kHint, fontSize: 13, fontWeight: FontWeight.w400),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.kHint)
            : null,
        suffixIcon: suffixIcon,
        errorStyle: const TextStyle(fontSize: 11, color: AppColors.kDanger),
        fillColor: Colors.white,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kBorder, width: 0.8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kBorder, width: 0.8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.kDanger, width: 1)),
      ),
    );
  }


  Future<void> _showTermsAndConditionsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 300),
        vsync: Navigator.of(context),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'User Contract Agreement & Terms',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: const Text(
                        // ضع نص الشروط والأحكام الفعلي هون
                        '1. Acceptance of Terms\n'
                            'By creating a company account on this platform, you agree to be bound by these Terms & Conditions and our User Contract Agreement.\n\n'
                            '2. Company Responsibilities\n'
                            'Your company agrees to provide accurate information, comply with local aviation regulations, and ensure all posted jobs meet safety standards.\n\n'
                            '3. Pilot Engagement\n'
                            'All engagements with pilots through the platform must follow the agreed scope of work, payment terms, and safety protocols outlined in each job listing.\n\n'
                            '4. Payments & Subscriptions\n'
                            'Subscription fees are billed according to the plan selected and are non-refundable except as required by law.\n\n'
                            '5. Data & Privacy\n'
                            'We collect and process data in accordance with our Privacy Policy to match companies with qualified drone pilots.\n\n'
                            '6. Limitation of Liability\n'
                            'The platform acts as an intermediary and is not liable for damages arising from services performed by independent pilots.\n\n'
                            '7. Termination\n'
                            'We reserve the right to suspend or terminate accounts that violate these terms or engage in fraudulent activity.\n\n'
                            '8. Governing Law\n'
                            'These terms are governed by the laws of the jurisdiction in which the platform operates.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF4B5563),
                          height: 1.6,
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

  Widget _buildRegionSelector() {
    return InkWell(
      onTap: _countries.isEmpty
          ? null
          : _showCountryAndRegionsPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 52,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _selectedCountry == null
                  ? const Text(
                'Select country and regions',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.kHint,
                ),
              )
                  : _selectedWillingRegions.isEmpty
                  ? Text(
                _selectedCountry!.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark,
                ),
              )
                  : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._selectedWillingRegions
                      .take(2)
                      .map(
                        (region) =>
                        _buildRegionChip(region),
                  ),
                  if (_selectedWillingRegions.length > 2)
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${_selectedWillingRegions.length - 2}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.kHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionChip(String region) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        region,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.kPrimary,
        ),
      ),
    );
  }

  void _showCountryAndRegionsPicker() {
    CountryModel? tempCountry = _selectedCountry;

    final Set<String> tempSelectedCities =
    Set<String>.from(_selectedWillingRegions);

    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final List<String> allCities =
                tempCountry?.cities ?? [];

            final List<String> filteredCities =
            allCities.where((city) {
              final query =
              searchQuery.trim().toLowerCase();

              if (query.isEmpty) {
                return true;
              }

              return city.toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Container(
                height:
                MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.kBorder,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==============================
                    // Header
                    // ==============================

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Regions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextDark,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.kHint,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==============================
                    // COUNTRY DROPDOWN
                    // ==============================

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        12,
                      ),
                      child: DropdownButtonFormField<CountryModel>(
                        value: tempCountry,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Country',
                          hintText: 'Select Country',
                          prefixIcon: const Icon(
                            Icons.public_rounded,
                            color: AppColors.kHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.kBorder,
                            ),
                          ),
                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.kPrimary,
                              width: 1.2,
                            ),
                          ),
                        ),
                        hint: const Text(
                          'Select Country',
                        ),
                        items: _countries.map((country) {
                          return DropdownMenuItem<CountryModel>(
                            value: country,
                            child: Text(
                              country.name,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (country) {
                          setSheetState(() {
                            tempCountry = country;

                            // مهم:
                            // عند تغيير الدولة نمسح المدن
                            tempSelectedCities.clear();

                            searchQuery = '';
                          });
                        },
                      ),
                    ),

                    // ==============================
                    // Cities
                    // ==============================

                    Expanded(
                      child: tempCountry == null
                          ? const Center(
                        child: Text(
                          'Select a country to see its cities',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.kHint,
                          ),
                        ),
                      )
                          : allCities.isEmpty
                          ? const Center(
                        child: Text(
                          'No cities available',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.kHint,
                          ),
                        ),
                      )
                          : Column(
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 20,
                            ),
                            child: TextField(
                              onChanged: (value) {
                                setSheetState(() {
                                  searchQuery =
                                      value;
                                });
                              },
                              decoration:
                              InputDecoration(
                                hintText:
                                'Search city...',
                                prefixIcon:
                                const Icon(
                                  Icons
                                      .search_rounded,
                                  size: 20,
                                  color:
                                  AppColors.kHint,
                                ),
                                filled: true,
                                fillColor:
                                const Color(
                                  0xFFF7F7F7,
                                ),
                                border:
                                OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    12,
                                  ),
                                  borderSide:
                                  BorderSide.none,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Expanded(
                            child:
                            ListView.separated(
                              itemCount:
                              filteredCities
                                  .length,
                              separatorBuilder:
                                  (context, index) {
                                return const Divider(
                                  height: 1,
                                  indent: 20,
                                  endIndent: 20,
                                  color:
                                  AppColors
                                      .kBorder,
                                );
                              },
                              itemBuilder:
                                  (context, index) {
                                final city =
                                filteredCities[
                                index];

                                final isSelected =
                                tempSelectedCities
                                    .contains(
                                    city);

                                return CheckboxListTile(
                                  value:
                                  isSelected,
                                  title: Text(city),
                                  activeColor:
                                  AppColors
                                      .kPrimary,
                                  onChanged:
                                      (value) {
                                    setSheetState(() {
                                      if (value ==
                                          true) {
                                        tempSelectedCities
                                            .add(
                                            city);
                                      } else {
                                        tempSelectedCities
                                            .remove(
                                            city);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==============================
                    // DONE
                    // ==============================

                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        20,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                          tempCountry == null
                              ? null
                              : () {
                            setState(() {
                              _selectedCountry =
                                  tempCountry;

                              _selectedWillingRegions
                                ..clear()
                                ..addAll(
                                  tempSelectedCities,
                                );
                            });

                            Navigator.pop(context);
                          },
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.kPrimary,
                            foregroundColor:
                            Colors.white,
                            elevation: 0,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadCountries() async {
    try {
      final countries =
      await _locationService.getCountries();

      if (!mounted) return;

      setState(() {
        _countries = countries;

        // لا تختار Afghanistan تلقائيًا
        _selectedCountry = null;

        _selectedWillingRegions.clear();
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/features/auth/models/country_model.dart';
import 'package:tototl_app/features/auth/services/location_service.dart';

import '../../controllers/company_profile_controller.dart';
import '../../models/company_profile_model.dart';
import '../../models/company_profile_update_model.dart';
import '../../services/company_profile_service.dart';

// ============================================================================
// COLORS
// ============================================================================

const Color _primary = Color(0xFF16C6C7);
const Color _primaryDark = Color(0xFF0D8AA5);
const Color _navy = Color(0xFF0B263C);
const Color _background = Color(0xFFF7F9FB);
const Color _surface = Colors.white;
const Color _surfaceSoft = Color(0xFFF8FAFC);
const Color _primarySoft = Color(0xFFEAFBFB);
const Color _border = Color(0xFFE6EDF2);
const Color _text = Color(0xFF11283D);
const Color _textMuted = Color(0xFF66788A);
const Color _hint = Color(0xFF98A6B4);
const Color _danger = Color(0xFFE45858);

// ============================================================================
// COMPANY EDIT PROFILE SCREEN
// ============================================================================

class CompanyEditProfileScreen extends StatefulWidget {
  const CompanyEditProfileScreen({
    super.key,
  });

  @override
  State<CompanyEditProfileScreen> createState() =>
      _CompanyEditProfileScreenState();
}

class _CompanyEditProfileScreenState
    extends State<CompanyEditProfileScreen> {
  // ==========================================================================
  // FORMS
  // ==========================================================================

  final GlobalKey<FormState> _companyFormKey =
  GlobalKey<FormState>();

  final GlobalKey<FormState> _locationFormKey =
  GlobalKey<FormState>();

  // ==========================================================================
  // API / CONTROLLER
  // ==========================================================================

  late final ApiClient _apiClient;
  late final CompanyProfileService _profileService;
  late final CompanyProfileController _profileController;

  final LocationService _locationService =
  LocationService();

  // ==========================================================================
  // CURRENT DATA
  // ==========================================================================

  CompanyAccountModel _account =
  const CompanyAccountModel();

  CompanyProfileModel _profile =
  const CompanyProfileModel();

  // ==========================================================================
  // TEXT CONTROLLERS
  // ==========================================================================

  final TextEditingController _companyNameController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  final TextEditingController _stateController =
  TextEditingController();

  final TextEditingController _addressController =
  TextEditingController();

  final TextEditingController _websiteController =
  TextEditingController();

  // ==========================================================================
  // STATE
  // ==========================================================================

  int _currentStep = 0;
  bool _loading = true;
  bool _saving = false;

  String _industryType = '';
  String _country = '';
  String _city = '';

  List<CountryModel> _countries = <CountryModel>[];

  final List<_EditableWorkRegion> _workRegions =
  <_EditableWorkRegion>[];

  // Same company types used in registration.
  static const List<String> _companyTypes = [
    'Construction',
    'Energy',
    'Real Estate',
    'Inspection',
    'Agriculture',
    'Other',
  ];

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    _apiClient = ApiClient();

    _profileService =
        CompanyProfileService(_apiClient);

    _profileController =
        CompanyProfileController(_profileService);

    _loadData();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _websiteController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // LOAD
  // ==========================================================================

  Future<void> _loadData() async {
    final data =
    await _profileController.loadEditProfile();

    if (!mounted) return;

    if (data == null) {
      setState(() {
        _loading = false;
      });

      _showSnack(
        _profileController.errorMessage ??
            'Unable to load company profile.',
        isError: true,
      );

      return;
    }

    _account = data.account;
    _profile = data.profile;

    _companyNameController.text =
        _profile.companyName;

    _descriptionController.text =
        _profile.description;

    _industryType =
        _profile.industryType;

    _country =
        _profile.country;

    _stateController.text =
        _profile.state;

    _city =
        _profile.city;

    _addressController.text =
        _profile.address;

    _websiteController.text =
        _profile.website;

    _workRegions
      ..clear()
      ..addAll(
        _profile.workRegions.map(
              (region) => _EditableWorkRegion(
            country: region.country,
            state: region.state,
            city: region.city,
          ),
        ),
      );

    try {
      _countries =
      await _locationService.getCountries();
    } catch (_) {
      _countries = <CountryModel>[];
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  void _continue() {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      final valid =
          _companyFormKey.currentState?.validate() ??
              false;

      if (!valid) {
        HapticFeedback.heavyImpact();
        return;
      }

      HapticFeedback.selectionClick();

      setState(() {
        _currentStep = 1;
      });

      return;
    }

    _save();
  }

  void _handleBack() {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
      });

      return;
    }

    Navigator.pop(context);
  }

  // ==========================================================================
  // SAVE
  // ==========================================================================

  Future<void> _save() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    final valid =
        _locationFormKey.currentState?.validate() ??
            false;

    if (!valid) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please check the highlighted fields.',
        isError: true,
      );

      return;
    }

    final companyName =
    _companyNameController.text.trim();

    if (companyName.isEmpty) {
      setState(() {
        _currentStep = 0;
      });

      _showSnack(
        'Company name is required.',
        isError: true,
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    final request =
    CompanyProfileUpdateRequest(
      companyName: companyName,
      industryType: _industryType,
      description:
      _descriptionController.text,
      country: _country,
      state: _stateController.text,
      city: _city,
      address: _addressController.text,
      website: _normalizeWebsite(
        _websiteController.text,
      ),
      workRegions: _workRegions
          .map(
            (region) => CompanyWorkRegionInput(
          country: region.country,
          state: region.state,
          city: region.city,
        ),
      )
          .toList(),
    );

    final updated =
    await _profileController.updateProfile(
      request,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (updated == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        _profileController.errorMessage ??
            'Unable to update company profile.',
        isError: true,
      );

      return;
    }

    HapticFeedback.mediumImpact();

    _showSnack(
      'Company profile updated successfully.',
    );

    await Future.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      true,
    );
  }

  // ==========================================================================
  // INDUSTRY
  // ==========================================================================

  Future<void> _selectIndustry() async {
    final values =
    <String>[..._companyTypes];

    final current =
    _industryType.trim();

    if (current.isNotEmpty &&
        !values.contains(current)) {
      values.insert(0, current);
    }

    final selected =
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SimpleSelectionSheet(
          title: 'Company Industry',
          selected: _industryType,
          values: values,
          icon: Icons.apartment_rounded,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _industryType = selected;
    });
  }

  // ==========================================================================
  // CURRENT COMPANY COUNTRY / CITY
  // ==========================================================================

  Future<void> _selectCountry() async {
    final selected =
    await _showCountryPicker(
      title: 'Company Country',
      selectedName: _country,
    );

    if (selected == null) return;

    setState(() {
      final changed =
          selected.name.trim().toLowerCase() !=
              _country.trim().toLowerCase();

      _country = selected.name;

      if (changed) {
        _city = '';
      }
    });
  }

  Future<void> _selectCity() async {
    final country =
    _findCountry(_country);

    if (country == null) {
      _showSnack(
        'Select the company country first.',
        isError: true,
      );

      return;
    }

    final selected =
    await _showCityPicker(
      country: country,
      selectedCity: _city,
    );

    if (selected == null) return;

    setState(() {
      _city = selected;
    });
  }

  // ==========================================================================
  // WORK REGIONS
  // ==========================================================================

  Future<void> _addWorkRegion() async {
    if (_countries.isEmpty) {
      _showSnack(
        'Country data is unavailable.',
        isError: true,
      );
      return;
    }

    final region =
    await showModalBottomSheet<
        _EditableWorkRegion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkRegionEditorSheet(
        countries: _countries,
      ),
    );

    if (region == null) return;

    setState(() {
      _workRegions.add(region);
    });
  }

  Future<void> _editWorkRegion(
      int index,
      ) async {
    final region =
    await showModalBottomSheet<
        _EditableWorkRegion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkRegionEditorSheet(
        countries: _countries,
        initial: _workRegions[index],
      ),
    );

    if (region == null) return;

    setState(() {
      _workRegions[index] = region;
    });
  }

  // ==========================================================================
  // COUNTRY PICKER
  // ==========================================================================

  Future<CountryModel?> _showCountryPicker({
    required String title,
    String selectedName = '',
  }) async {
    if (_countries.isEmpty) {
      _showSnack(
        'Country data is unavailable.',
        isError: true,
      );

      return null;
    }

    String query = '';

    return showModalBottomSheet<CountryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            final filtered =
            _countries.where(
                  (country) {
                final q =
                query.trim().toLowerCase();

                if (q.isEmpty) return true;

                return country.name
                    .toLowerCase()
                    .contains(q);
              },
            ).toList();

            return SafeArea(
              child: Container(
                height:
                MediaQuery.of(context).size.height *
                    0.78,
                decoration:
                const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const _SheetHandle(),
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        20,
                        18,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style:
                              const TextStyle(
                                color: _text,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                        decoration:
                        _pickerDecoration(
                          'Search country...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                        itemCount:
                        filtered.length,
                        separatorBuilder:
                            (_, __) =>
                        const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: _border,
                        ),
                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final country =
                          filtered[index];

                          final selected =
                              country.name
                                  .trim()
                                  .toLowerCase() ==
                                  selectedName
                                      .trim()
                                      .toLowerCase();

                          return ListTile(
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 20,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration:
                              BoxDecoration(
                                color: selected
                                    ? _primarySoft
                                    : _surfaceSoft,
                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Icon(
                                Icons.public_rounded,
                                color: selected
                                    ? _primaryDark
                                    : _hint,
                                size: 17,
                              ),
                            ),
                            title: Text(
                              country.name,
                              style: TextStyle(
                                color: selected
                                    ? _primaryDark
                                    : _text,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                              _primaryDark,
                              size: 19,
                            )
                                : null,
                            onTap: () {
                              Navigator.pop(
                                context,
                                country,
                              );
                            },
                          );
                        },
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

  // ==========================================================================
  // CITY PICKER
  // ==========================================================================

  Future<String?> _showCityPicker({
    required CountryModel country,
    String selectedCity = '',
  }) async {
    String query = '';

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            final cities =
            country.cities.where(
                  (city) {
                final q =
                query.trim().toLowerCase();

                if (q.isEmpty) return true;

                return city
                    .toLowerCase()
                    .contains(q);
              },
            ).toList();

            return SafeArea(
              child: Container(
                height:
                MediaQuery.of(context).size.height *
                    0.78,
                decoration:
                const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const _SheetHandle(),
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        20,
                        18,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                const Text(
                                  'Select City',
                                  style:
                                  TextStyle(
                                    color: _text,
                                    fontSize: 18,
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  country.name,
                                  style:
                                  const TextStyle(
                                    color: _textMuted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                        decoration:
                        _pickerDecoration(
                          'Search city...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: cities.isEmpty
                          ? const Center(
                        child: Text(
                          'No cities found.',
                          style: TextStyle(
                            color: _textMuted,
                          ),
                        ),
                      )
                          : ListView.separated(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                        itemCount: cities.length,
                        separatorBuilder:
                            (_, __) =>
                        const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: _border,
                        ),
                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final city =
                          cities[index];

                          final selected =
                              city
                                  .trim()
                                  .toLowerCase() ==
                                  selectedCity
                                      .trim()
                                      .toLowerCase();

                          return ListTile(
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 20,
                            ),
                            title: Text(
                              city,
                              style:
                              TextStyle(
                                color: selected
                                    ? _primaryDark
                                    : _text,
                                fontWeight:
                                selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                              _primaryDark,
                            )
                                : null,
                            onTap: () {
                              Navigator.pop(
                                context,
                                city,
                              );
                            },
                          );
                        },
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

  CountryModel? _findCountry(
      String name,
      ) {
    final target =
    name.trim().toLowerCase();

    if (target.isEmpty) return null;

    for (final country in _countries) {
      if (country.name.trim().toLowerCase() ==
          target) {
        return country;
      }
    }

    return null;
  }

  // ==========================================================================
  // SNACK
  // ==========================================================================

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        isError ? _danger : _navy,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons
                  .check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: _primaryDark,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: _background,
        surfaceTintColor: _background,
        titleSpacing: 0,
        title: _TopBar(
          step: _currentStep,
          onBack: _saving
              ? () {}
              : _handleBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                0,
              ),
              child: _StepIndicator(
                currentStep: _currentStep,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration:
                const Duration(
                  milliseconds: 260,
                ),
                child: _currentStep == 0
                    ? _buildCompanyStep()
                    : _buildLocationStep(),
              ),
            ),
            _BottomBar(
              currentStep: _currentStep,
              saving: _saving,
              onBack: _handleBack,
              onContinue: _continue,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // STEP 1
  // ==========================================================================

  Widget _buildCompanyStep() {
    return Form(
      key: _companyFormKey,
      child: ListView(
        key: const ValueKey(
          'company-step',
        ),
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior
            .onDrag,
        padding:
        const EdgeInsets.fromLTRB(
          18,
          16,
          18,
          28,
        ),
        children: [
          const _IntroCard(
            icon: Icons.apartment_rounded,
            eyebrow: 'COMPANY PROFILE',
            title:
            'Keep your business identity current.',
            subtitle:
            'Update the information pilots see when they review your company.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            icon:
            Icons.business_center_outlined,
            title: 'Company details',
            subtitle:
            'Public business information',
            child: Column(
              children: [
                _FormField(
                  controller:
                  _companyNameController,
                  label: 'Company name',
                  hint:
                  'Enter company name',
                  icon:
                  Icons.apartment_rounded,
                  textCapitalization:
                  TextCapitalization.words,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Company name is required';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 13),
                _PickerField(
                  label: 'Industry',
                  value: _industryType,
                  hint:
                  'Select company industry',
                  icon:
                  Icons.category_outlined,
                  onTap: _selectIndustry,
                ),
                const SizedBox(height: 13),
                _FormField(
                  controller:
                  _descriptionController,
                  label:
                  'Company description',
                  hint:
                  'Tell pilots what your company does...',
                  icon:
                  Icons.notes_rounded,
                  maxLines: 5,
                  minLines: 4,
                  textCapitalization:
                  TextCapitalization.sentences,
                  textInputAction:
                  TextInputAction.newline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Locked because these fields are not part of PATCH /company/profile.
          _LockedAccountCard(
            account: _account,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 2
  // ==========================================================================

  Widget _buildLocationStep() {
    return Form(
      key: _locationFormKey,
      child: ListView(
        key: const ValueKey(
          'location-step',
        ),
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior
            .onDrag,
        padding:
        const EdgeInsets.fromLTRB(
          18,
          16,
          18,
          28,
        ),
        children: [
          const _IntroCard(
            icon: Icons.public_rounded,
            eyebrow: 'OPERATING AREA',
            title:
            'Show pilots where you operate.',
            subtitle:
            'Your company location and operating regions help match the right pilots to your jobs.',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            icon:
            Icons.location_on_outlined,
            title: 'Company location',
            subtitle:
            'Main business location',
            child: Column(
              children: [
                _PickerField(
                  label: 'Country',
                  value: _country,
                  hint: 'Select country',
                  icon:
                  Icons.public_rounded,
                  onTap: _selectCountry,
                ),
                const SizedBox(height: 13),
                _FormField(
                  controller:
                  _stateController,
                  label:
                  'State / Region',
                  hint:
                  'Optional state or region',
                  icon:
                  Icons.map_outlined,
                  textCapitalization:
                  TextCapitalization.words,
                ),
                const SizedBox(height: 13),
                _PickerField(
                  label: 'City',
                  value: _city,
                  hint:
                  _country.trim().isEmpty
                      ? 'Select country first'
                      : 'Select city',
                  icon:
                  Icons.location_city_outlined,
                  onTap: _selectCity,
                ),
                const SizedBox(height: 13),
                _FormField(
                  controller:
                  _addressController,
                  label: 'Address',
                  hint:
                  'Business address',
                  icon:
                  Icons.home_work_outlined,
                  textCapitalization:
                  TextCapitalization.words,
                ),
                const SizedBox(height: 13),
                _FormField(
                  controller:
                  _websiteController,
                  label: 'Website',
                  hint:
                  'https://company.com',
                  icon:
                  Icons.language_rounded,
                  keyboardType:
                  TextInputType.url,
                  textInputAction:
                  TextInputAction.done,
                  validator:
                  _websiteValidator,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            icon:
            Icons.travel_explore_rounded,
            title: 'Operating regions',
            subtitle:
            'Areas where your company manages work',
            trailing: _CountPill(
              count: _workRegions.length,
            ),
            child: Column(
              children: [
                if (_workRegions.isEmpty)
                  const _EmptyRegions()
                else
                  ...List.generate(
                    _workRegions.length,
                        (index) {
                      final region =
                      _workRegions[index];

                      return Padding(
                        padding:
                        EdgeInsets.only(
                          bottom: index ==
                              _workRegions.length -
                                  1
                              ? 0
                              : 9,
                        ),
                        child:
                        _WorkRegionTile(
                          region: region,
                          onEdit: () =>
                              _editWorkRegion(
                                index,
                              ),
                          onDelete: () {
                            HapticFeedback
                                .selectionClick();

                            setState(() {
                              _workRegions.removeAt(
                                index,
                              );
                            });
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    _addWorkRegion,
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      _primaryDark,
                      side:
                      const BorderSide(
                        color: _border,
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 13,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Add Operating Region',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP BAR
// ============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.onBack,
  });

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        14,
        9,
        18,
        6,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onBack,
              customBorder:
              const CircleBorder(),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _border,
                  ),
                ),
                child: const Icon(
                  Icons
                      .arrow_back_ios_new_rounded,
                  color: _navy,
                  size: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Company Profile',
                  style: TextStyle(
                    color: _text,
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step == 0
                      ? 'Business identity & account'
                      : 'Location & operating regions',
                  style:
                  const TextStyle(
                    color: _textMuted,
                    fontSize: 10.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius:
              BorderRadius.circular(30),
            ),
            child: Text(
              '${step + 1} / 2',
              style:
              const TextStyle(
                color: _primaryDark,
                fontSize: 10,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP INDICATOR
// ============================================================================

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StepItem(
            index: 0,
            currentStep: currentStep,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StepItem(
            index: 1,
            currentStep: currentStep,
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.currentStep,
  });

  final int index;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final active =
        index <= currentStep;

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 220),
      height: 5,
      decoration: BoxDecoration(
        color:
        active ? _primary : _border,
        borderRadius:
        BorderRadius.circular(30),
      ),
    );
  }
}

// ============================================================================
// INTRO CARD
// ============================================================================

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        18,
      ),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071C2F),
            Color(0xFF0D6579),
          ],
        ),
        borderRadius:
        BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.12),
            blurRadius: 22,
            offset:
            const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              Colors.white.withOpacity(0.10),
              borderRadius:
              BorderRadius.circular(17),
              border: Border.all(
                color:
                Colors.white.withOpacity(0.12),
              ),
            ),
            child: Icon(
              icon,
              color:
              const Color(0xFF8EF2E2),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF8EF2E2),
                    fontSize: 8.8,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    height: 1.16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.72),
                    fontSize: 10.4,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        17,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset:
            const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration:
                BoxDecoration(
                  color: _primarySoft,
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: _primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        color: _textMuted,
                        fontSize: 9.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!,
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// LOCKED ACCOUNT
// ============================================================================

class _LockedAccountCard
    extends StatelessWidget {
  const _LockedAccountCard({
    required this.account,
  });

  final CompanyAccountModel account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        15,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F9),
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: _textMuted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account details',
                      style:
                      TextStyle(
                        color: _text,
                        fontSize: 13.5,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'These fields are managed by your account and cannot be edited here.',
                      style:
                      TextStyle(
                        color: _textMuted,
                        fontSize: 9.6,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _DisabledInfo(
            icon:
            Icons.person_outline_rounded,
            label: 'Account name',
            value: _display(
              account.name,
            ),
          ),
          const SizedBox(height: 8),
          _DisabledInfo(
            icon:
            Icons.alternate_email_rounded,
            label: 'Username',
            value: _display(
              account.displayUsername,
            ),
          ),
          const SizedBox(height: 8),
          _DisabledInfo(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _display(
              account.email,
            ),
          ),
          const SizedBox(height: 8),
          _DisabledInfo(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _display(
              account.phone,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledInfo extends StatelessWidget {
  const _DisabledInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
        Colors.white.withOpacity(0.72),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _hint,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                  const TextStyle(
                    color: _hint,
                    fontSize: 9.4,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style:
                  const TextStyle(
                    color: _textMuted,
                    fontSize: 11.5,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_rounded,
            color: _hint,
            size: 13,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORM FIELD
// ============================================================================

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization =
        TextCapitalization.none,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.only(
            left: 2,
            bottom: 7,
          ),
          child: Text(
            label,
            style:
            const TextStyle(
              color: _text,
              fontSize: 11.4,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction:
          textInputAction,
          textCapitalization:
          textCapitalization,
          minLines: minLines,
          maxLines: maxLines,
          style:
          const TextStyle(
            color: _text,
            fontSize: 12.5,
            fontWeight:
            FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(
              color: _hint,
              fontSize: 11.5,
            ),
            prefixIcon: Icon(
              icon,
              color: _primaryDark,
              size: 18,
            ),
            filled: true,
            fillColor: _surfaceSoft,
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide:
              const BorderSide(
                color: _border,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide:
              const BorderSide(
                color: _primary,
                width: 1.3,
              ),
            ),
            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide:
              const BorderSide(
                color: _danger,
              ),
            ),
            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(16),
              borderSide:
              const BorderSide(
                color: _danger,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PICKER FIELD
// ============================================================================

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.only(
            left: 2,
            bottom: 7,
          ),
          child: Text(
            label,
            style:
            const TextStyle(
              color: _text,
              fontSize: 11.4,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          borderRadius:
          BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius:
            BorderRadius.circular(16),
            child: Ink(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 13,
              ),
              decoration:
              BoxDecoration(
                color: _surfaceSoft,
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color:
                    _primaryDark,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value.trim().isEmpty
                          ? hint
                          : value,
                      style:
                      TextStyle(
                        color:
                        value.trim().isEmpty
                            ? _hint
                            : _text,
                        fontSize: 12.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    color: _hint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WORK REGION TILE
// ============================================================================

class _WorkRegionTile extends StatelessWidget {
  const _WorkRegionTile({
    required this.region,
    required this.onEdit,
    required this.onDelete,
  });

  final _EditableWorkRegion region;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        10,
        8,
        10,
      ),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
            const BoxDecoration(
              color: _primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: _primaryDark,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              region.displayLabel,
              style:
              const TextStyle(
                color: _text,
                fontSize: 11.5,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            visualDensity:
            VisualDensity.compact,
            icon: const Icon(
              Icons.edit_outlined,
              color: _primaryDark,
              size: 18,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            visualDensity:
            VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: _danger,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRegions extends StatelessWidget {
  const _EmptyRegions();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.travel_explore_outlined,
            color: _hint,
            size: 24,
          ),
          SizedBox(height: 6),
          Text(
            'No operating regions selected',
            style: TextStyle(
              color: _textMuted,
              fontSize: 10.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style:
        const TextStyle(
          color: _primaryDark,
          fontSize: 10,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM BAR
// ============================================================================

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentStep,
    required this.saving,
    required this.onBack,
    required this.onContinue,
  });

  final int currentStep;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        11,
        18,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: _border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset:
            const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep == 1) ...[
            Expanded(
              child: OutlinedButton(
                onPressed:
                saving ? null : onBack,
                style:
                OutlinedButton.styleFrom(
                  foregroundColor: _text,
                  side:
                  const BorderSide(
                    color: _border,
                  ),
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(17),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex:
            currentStep == 1 ? 2 : 1,
            child: FilledButton(
              onPressed:
              saving ? null : onContinue,
              style:
              FilledButton.styleFrom(
                backgroundColor:
                _primaryDark,
                foregroundColor:
                Colors.white,
                disabledBackgroundColor:
                _primaryDark.withOpacity(0.55),
                padding:
                const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(17),
                ),
              ),
              child: saving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                    Colors.white,
                  ),
                ),
              )
                  : Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    currentStep == 0
                        ? Icons
                        .arrow_forward_rounded
                        : Icons
                        .check_rounded,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    currentStep == 0
                        ? 'Continue'
                        : 'Save Changes',
                    style:
                    const TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SIMPLE SELECTION SHEET
// ============================================================================

class _SimpleSelectionSheet
    extends StatelessWidget {
  const _SimpleSelectionSheet({
    required this.title,
    required this.selected,
    required this.values,
    required this.icon,
  });

  final String title;
  final String selected;
  final List<String> values;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration:
        const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 18),
            Align(
              alignment:
              Alignment.centerLeft,
              child: Text(
                title,
                style:
                const TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...values.map(
                  (value) {
                final isSelected =
                    value.trim().toLowerCase() ==
                        selected.trim().toLowerCase();

                return ListTile(
                  contentPadding:
                  EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration:
                    BoxDecoration(
                      color: isSelected
                          ? _primarySoft
                          : _surfaceSoft,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? _primaryDark
                          : _hint,
                      size: 17,
                    ),
                  ),
                  title: Text(
                    value,
                    style:
                    TextStyle(
                      color: isSelected
                          ? _primaryDark
                          : _text,
                      fontWeight:
                      isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                    Icons
                        .check_circle_rounded,
                    color: _primaryDark,
                  )
                      : null,
                  onTap: () {
                    Navigator.pop(
                      context,
                      value,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WORK REGION EDITOR
// ============================================================================

class _WorkRegionEditorSheet
    extends StatefulWidget {
  const _WorkRegionEditorSheet({
    required this.countries,
    this.initial,
  });

  final List<CountryModel> countries;
  final _EditableWorkRegion? initial;

  @override
  State<_WorkRegionEditorSheet>
  createState() =>
      _WorkRegionEditorSheetState();
}

class _WorkRegionEditorSheetState
    extends State<_WorkRegionEditorSheet> {
  late String _country;
  late String _city;

  late final TextEditingController
  _stateController;

  @override
  void initState() {
    super.initState();

    _country =
        widget.initial?.country ?? '';

    _city =
        widget.initial?.city ?? '';

    _stateController =
        TextEditingController(
          text:
          widget.initial?.state ?? '',
        );
  }

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }

  CountryModel? get _selectedCountry {
    final target =
    _country.trim().toLowerCase();

    if (target.isEmpty) return null;

    for (final country
    in widget.countries) {
      if (country.name
          .trim()
          .toLowerCase() ==
          target) {
        return country;
      }
    }

    return null;
  }

  Future<void> _pickCountry() async {
    String query = '';

    final selected =
    await showModalBottomSheet<
        CountryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            final filtered =
            widget.countries.where(
                  (country) {
                final q =
                query.trim().toLowerCase();

                if (q.isEmpty) return true;

                return country.name
                    .toLowerCase()
                    .contains(q);
              },
            ).toList();

            return SafeArea(
              child: Container(
                height:
                MediaQuery.of(context).size.height *
                    0.72,
                decoration:
                const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const _SheetHandle(),
                    const Padding(
                      padding:
                      EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        12,
                      ),
                      child: Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Text(
                          'Operating Country',
                          style:
                          TextStyle(
                            color: _text,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                        decoration:
                        _pickerDecoration(
                          'Search country...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                      ListView.separated(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                        itemCount:
                        filtered.length,
                        separatorBuilder:
                            (_, __) =>
                        const Divider(
                          height: 1,
                          color: _border,
                          indent: 20,
                          endIndent: 20,
                        ),
                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final country =
                          filtered[index];

                          return ListTile(
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 20,
                            ),
                            leading: const Icon(
                              Icons.public_rounded,
                              color: _primaryDark,
                              size: 18,
                            ),
                            title: Text(
                              country.name,
                            ),
                            onTap: () {
                              Navigator.pop(
                                context,
                                country,
                              );
                            },
                          );
                        },
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

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      final changed =
          selected.name.trim().toLowerCase() !=
              _country.trim().toLowerCase();

      _country = selected.name;

      if (changed) {
        _city = '';
      }
    });
  }

  Future<void> _pickCity() async {
    final country =
        _selectedCountry;

    if (country == null) return;

    String query = '';

    final selected =
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            final cities =
            country.cities.where(
                  (city) {
                final q =
                query.trim().toLowerCase();

                if (q.isEmpty) return true;

                return city
                    .toLowerCase()
                    .contains(q);
              },
            ).toList();

            return SafeArea(
              child: Container(
                height:
                MediaQuery.of(context).size.height *
                    0.72,
                decoration:
                const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const _SheetHandle(),
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        12,
                      ),
                      child: Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Text(
                          'City • ${country.name}',
                          style:
                          const TextStyle(
                            color: _text,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                        decoration:
                        _pickerDecoration(
                          'Search city...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: cities.isEmpty
                          ? const Center(
                        child: Text(
                          'No cities found.',
                          style: TextStyle(
                            color: _textMuted,
                          ),
                        ),
                      )
                          : ListView.separated(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                        itemCount: cities.length,
                        separatorBuilder:
                            (_, __) =>
                        const Divider(
                          height: 1,
                          color: _border,
                          indent: 20,
                          endIndent: 20,
                        ),
                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final city =
                          cities[index];

                          return ListTile(
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 20,
                            ),
                            title: Text(city),
                            onTap: () {
                              Navigator.pop(
                                context,
                                city,
                              );
                            },
                          );
                        },
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

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _city = selected;
    });
  }

  void _save() {
    if (_country.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Country is required.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      _EditableWorkRegion(
        country: _country.trim(),
        state:
        _stateController.text.trim(),
        city: _city.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
        MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration:
          const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag,
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Center(
                  child: _SheetHandle(),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.initial == null
                      ? 'Add Operating Region'
                      : 'Edit Operating Region',
                  style:
                  const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose the area where your company operates.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 18),
                _PickerField(
                  label: 'Country',
                  value: _country,
                  hint: 'Select country',
                  icon:
                  Icons.public_rounded,
                  onTap: _pickCountry,
                ),
                const SizedBox(height: 13),
                _FormField(
                  controller:
                  _stateController,
                  label: 'State / Region',
                  hint: 'Optional',
                  icon: Icons.map_outlined,
                  textCapitalization:
                  TextCapitalization.words,
                ),
                const SizedBox(height: 13),
                _PickerField(
                  label: 'City',
                  value: _city,
                  hint:
                  _country.trim().isEmpty
                      ? 'Select country first'
                      : 'Select city',
                  icon:
                  Icons.location_city_outlined,
                  onTap:
                  _country.trim().isEmpty
                      ? () {}
                      : _pickCity,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    style:
                    FilledButton.styleFrom(
                      backgroundColor:
                      _primaryDark,
                      foregroundColor:
                      Colors.white,
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                      widget.initial == null
                          ? 'Add Region'
                          : 'Save Region',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: _border,
        borderRadius:
        BorderRadius.circular(20),
      ),
    );
  }
}

class _EditableWorkRegion {
  const _EditableWorkRegion({
    this.country = '',
    this.state = '',
    this.city = '',
  });

  final String country;
  final String state;
  final String city;

  String get displayLabel {
    final parts = <String>[
      city,
      state,
      country,
    ].where(
          (value) =>
      value.trim().isNotEmpty,
    ).toList();

    return parts.isEmpty
        ? 'Region'
        : parts.join(', ');
  }
}

InputDecoration _pickerDecoration(
    String hint,
    ) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(
      Icons.search_rounded,
      color: _hint,
    ),
    filled: true,
    fillColor: _surfaceSoft,
    border: OutlineInputBorder(
      borderRadius:
      BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );
}

String _display(
    String value,
    ) {
  final clean = value.trim();

  return clean.isEmpty
      ? 'Not available'
      : clean;
}

String? _websiteValidator(
    String? value,
    ) {
  final clean =
      value?.trim() ?? '';

  if (clean.isEmpty) return null;

  final normalized =
  _normalizeWebsite(clean);

  if (normalized == null) {
    return null;
  }

  final uri =
  Uri.tryParse(normalized);

  if (uri == null ||
      !uri.hasScheme ||
      (uri.scheme != 'http' &&
          uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return 'Enter a valid website';
  }

  return null;
}

String? _normalizeWebsite(
    String value,
    ) {
  final clean = value.trim();

  if (clean.isEmpty) return null;

  if (clean.startsWith('http://') ||
      clean.startsWith('https://')) {
    return clean;
  }

  return 'https://$clean';
}

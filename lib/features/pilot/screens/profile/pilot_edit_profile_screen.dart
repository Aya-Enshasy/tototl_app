import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tototl_app/core/network/api_client.dart';

import 'package:tototl_app/features/auth/models/country_model.dart';
import 'package:tototl_app/features/auth/services/location_service.dart';

import 'package:tototl_app/features/pilot/controllers/pilot_profile_controller.dart';

import 'package:tototl_app/features/pilot/models/pilot_profile_model.dart';
import 'package:tototl_app/features/pilot/models/pilot_profile_update_model.dart';

import 'package:tototl_app/features/pilot/services/pilot_profile_service.dart';

// ============================================================================
// COLORS
// ============================================================================

const Color _primary =
Color(0xFF16C6C7);

const Color _primaryDark =
Color(0xFF0D8AA5);

const Color _navy =
Color(0xFF0B263C);

const Color _background =
Color(0xFFF7F9FB);

const Color _surface =
    Colors.white;

const Color _surfaceSoft =
Color(0xFFF8FAFC);

const Color _primarySoft =
Color(0xFFEAFBFB);

const Color _border =
Color(0xFFE6EDF2);

const Color _text =
Color(0xFF11283D);

const Color _textMuted =
Color(0xFF66788A);

const Color _hint =
Color(0xFF98A6B4);

const Color _danger =
Color(0xFFE45858);

// ============================================================================
// PILOT EDIT PROFILE SCREEN
// ============================================================================

class PilotEditProfileScreen
    extends StatefulWidget {
  const PilotEditProfileScreen({
    super.key,
  });

  @override
  State<PilotEditProfileScreen>
  createState() =>
      _PilotEditProfileScreenState();
}

class _PilotEditProfileScreenState
    extends State<PilotEditProfileScreen> {
  // ==========================================================================
  // FORMS
  // ==========================================================================

  final GlobalKey<FormState>
  _personalFormKey =
  GlobalKey<FormState>();

  final GlobalKey<FormState>
  _workFormKey =
  GlobalKey<FormState>();

  // ==========================================================================
  // CONTROLLER / SERVICE
  // ==========================================================================

  late final ApiClient _apiClient;

  late final PilotProfileService
  _profileService;

  late final PilotProfileController
  _profileController;

  final LocationService
  _locationService =
  LocationService();

  // ==========================================================================
  // ACCOUNT / PROFILE
  // ==========================================================================

  PilotAccountModel _account =
  const PilotAccountModel();

  PilotProfileModel _profile =
  const PilotProfileModel();

  // ==========================================================================
  // TEXT CONTROLLERS
  // ==========================================================================

  final TextEditingController
  _nationalityController =
  TextEditingController();

  final TextEditingController
  _dateController =
  TextEditingController();

  final TextEditingController
  _linkedinController =
  TextEditingController();

  final TextEditingController
  _previousCompanyController =
  TextEditingController();

  final TextEditingController
  _bioController =
  TextEditingController();

  final TextEditingController
  _currentCountryController =
  TextEditingController();

  final TextEditingController
  _currentStateController =
  TextEditingController();

  final TextEditingController
  _currentCityController =
  TextEditingController();

  // ==========================================================================
  // STATE
  // ==========================================================================

  int _currentStep = 0;

  bool _loading = true;

  bool _saving = false;

  DateTime? _dateOfBirth;

  int _experienceYears = 0;

  final Set<String> _languages =
  <String>{};

  final List<_EditableWorkRegion>
  _workRegions =
  <_EditableWorkRegion>[];

  List<CountryModel> _countries =
  <CountryModel>[];

  // ==========================================================================
  // OPTIONS
  // ==========================================================================

  static const List<String>
  _defaultLanguages = [
    'English',
    'Arabic',
    'French',
    'Spanish',
  ];

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

    _apiClient =
        ApiClient();

    _profileService =
        PilotProfileService(
          _apiClient,
        );

    _profileController =
        PilotProfileController(
          _profileService,
        );

    _loadData();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _nationalityController.dispose();

    _dateController.dispose();

    _linkedinController.dispose();

    _previousCompanyController
        .dispose();

    _bioController.dispose();

    _currentCountryController
        .dispose();

    _currentStateController.dispose();

    _currentCityController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // LOAD DATA
  // ==========================================================================

  Future<void> _loadData() async {
    final data =
    await _profileController
        .loadEditProfile();

    if (!mounted) return;

    if (data == null) {
      setState(() {
        _loading = false;
      });

      _showSnack(
        _profileController
            .errorMessage ??
            'Unable to load profile data.',
        isError: true,
      );

      return;
    }

    _account =
        data.account;

    _profile =
        data.profile;

    // ------------------------------------------------------------------------
    // PERSONAL
    // ------------------------------------------------------------------------

    _nationalityController.text =
        _profile.nationality;

    _dateOfBirth =
        _profile.dateOfBirth;

    _dateController.text =
        _formatDate(
          _dateOfBirth,
        );

    _linkedinController.text =
        _profile.linkedinUrl;

    // ------------------------------------------------------------------------
    // EXPERIENCE
    // ------------------------------------------------------------------------

    _experienceYears =
        _profile.experienceYears
            .clamp(
          0,
          40,
        )
            .toInt();

    _languages
      ..clear()
      ..addAll(
        _profile.languages,
      );

    // ------------------------------------------------------------------------
    // CURRENT LOCATION
    // ------------------------------------------------------------------------

    _currentCountryController.text =
        _profile.currentCountry;

    _currentStateController.text =
        _profile.currentState;

    _currentCityController.text =
        _profile.currentCity;

    // ------------------------------------------------------------------------
    // PROFESSIONAL
    // ------------------------------------------------------------------------

    _previousCompanyController.text =
        _profile.previousCompany;

    _bioController.text =
        _profile.bio;

    // ------------------------------------------------------------------------
    // WORK REGIONS
    // ------------------------------------------------------------------------

    _workRegions
      ..clear()
      ..addAll(
        _profile.workRegions.map(
              (
              region,
              ) {
            return _EditableWorkRegion(
              country:
              region.country,

              state:
              region.state,

              city:
              region.city,
            );
          },
        ),
      );

    // ------------------------------------------------------------------------
    // COUNTRY DATASET
    // ------------------------------------------------------------------------

    try {
      _countries =
      await _locationService
          .getCountries();
    } catch (_) {
      _countries =
      <CountryModel>[];
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  // ==========================================================================
  // CONTINUE
  // ==========================================================================

  void _continue() {
    FocusScope.of(context)
        .unfocus();

    if (_currentStep == 0) {
      final valid =
          _personalFormKey
              .currentState
              ?.validate() ??
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

  // ==========================================================================
  // BACK
  // ==========================================================================

  void _handleBack() {
    FocusScope.of(context)
        .unfocus();

    HapticFeedback.selectionClick();

    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
      });

      return;
    }

    Navigator.pop(
      context,
    );
  }

  // ==========================================================================
  // SAVE
  // ==========================================================================

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    FocusScope.of(context)
        .unfocus();

    final valid =
        _workFormKey
            .currentState
            ?.validate() ??
            false;

    if (!valid) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please check the highlighted fields.',
        isError: true,
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    // ------------------------------------------------------------------------
    // BUILD REQUEST MODEL
    // ------------------------------------------------------------------------

    final request =
    PilotProfileUpdateRequest(
      bio:
      _bioController.text,

      experienceYears:
      _experienceYears,

      nationality:
      _nationalityController.text,

      dateOfBirth:
      _dateOfBirth,

      linkedinUrl:
      _linkedinController.text,

      previousCompany:
      _previousCompanyController
          .text,

      languages:
      _languages.toList(),

      currentCountry:
      _currentCountryController
          .text,

      currentState:
      _currentStateController
          .text,

      currentCity:
      _currentCityController.text,

      workRegions:
      _workRegions.map(
            (
            region,
            ) {
          return PilotWorkRegionInput(
            country:
            region.country,

            state:
            region.state,

            city:
            region.city,
          );
        },
      ).toList(),
    );

    // ------------------------------------------------------------------------
    // CONTROLLER
    // ------------------------------------------------------------------------

    final updated =
    await _profileController
        .updateProfile(
      request,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    // ------------------------------------------------------------------------
    // ERROR
    // ------------------------------------------------------------------------

    if (updated == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        _profileController
            .errorMessage ??
            'Unable to update profile.',
        isError: true,
      );

      return;
    }

    // ------------------------------------------------------------------------
    // SUCCESS
    // ------------------------------------------------------------------------

    HapticFeedback.mediumImpact();

    _showSnack(
      'Profile updated successfully.',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 450,
      ),
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      true,
    );
  }

  // ==========================================================================
  // DATE
  // ==========================================================================

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();

    final now =
    DateTime.now();

    final selected =
    await showDatePicker(
      context: context,

      initialDate:
      _dateOfBirth ??
          DateTime(
            1995,
            1,
            1,
          ),

      firstDate:
      DateTime(
        1940,
        1,
        1,
      ),

      lastDate:
      now,

      builder:
          (
          context,
          child,
          ) {
        return Theme(
          data: Theme.of(context)
              .copyWith(
            colorScheme:
            const ColorScheme.light(
              primary:
              _primaryDark,

              onPrimary:
              Colors.white,
            ),
          ),

          child:
          child!,
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _dateOfBirth =
          selected;

      _dateController.text =
          _formatDate(
            selected,
          );
    });
  }

  // ==========================================================================
  // EXPERIENCE
  // ==========================================================================

  Future<void>
  _selectExperience() async {
    HapticFeedback.lightImpact();

    final selected =
    await showModalBottomSheet<
        int>(
      context: context,

      isScrollControlled:
      true,

      backgroundColor:
      Colors.transparent,

      builder: (context) {
        return SafeArea(
          child: Container(
            height:
            MediaQuery.of(context)
                .size
                .height *
                0.66,

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

            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),

                _SheetHandle(),

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
                      'Years of Experience',

                      style:
                      TextStyle(
                        color:
                        _text,

                        fontSize:
                        18,

                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child:
                  ListView.builder(
                    itemCount:
                    41,

                    itemBuilder:
                        (
                        context,
                        index,
                        ) {
                      final isSelected =
                          index ==
                              _experienceYears;

                      return ListTile(
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          20,
                        ),

                        leading:
                        Icon(
                          Icons
                              .workspace_premium_outlined,

                          color:
                          isSelected
                              ? _primaryDark
                              : _hint,
                        ),

                        title: Text(
                          _experienceLabel(
                            index,
                          ),

                          style:
                          TextStyle(
                            color:
                            isSelected
                                ? _primaryDark
                                : _text,

                            fontSize:
                            13,

                            fontWeight:
                            isSelected
                                ? FontWeight
                                .w700
                                : FontWeight
                                .w500,
                          ),
                        ),

                        trailing:
                        isSelected
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
                            index,
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

    if (selected == null) {
      return;
    }

    setState(() {
      _experienceYears =
          selected;
    });
  }

  // ==========================================================================
  // NATIONALITY
  // ==========================================================================

  Future<void>
  _selectNationality() async {
    final selected =
    await _showCountryPicker(
      title:
      'Select Nationality',

      selectedName:
      _nationalityController
          .text,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _nationalityController.text =
          selected.name;
    });
  }

  // ==========================================================================
  // CURRENT COUNTRY
  // ==========================================================================

  Future<void>
  _selectCurrentCountry() async {
    final selected =
    await _showCountryPicker(
      title:
      'Current Country',

      selectedName:
      _currentCountryController
          .text,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _currentCountryController.text =
          selected.name;

      _currentCityController
          .clear();
    });
  }

  // ==========================================================================
  // CURRENT CITY
  // ==========================================================================

  Future<void>
  _selectCurrentCity() async {
    final country =
    _findCountry(
      _currentCountryController.text,
    );

    if (country == null) {
      _showSnack(
        'Select your country first.',
        isError: true,
      );

      return;
    }

    final city =
    await _showCityPicker(
      country:
      country,

      selectedCity:
      _currentCityController.text,
    );

    if (city == null) {
      return;
    }

    setState(() {
      _currentCityController.text =
          city;
    });
  }

  // ==========================================================================
  // COUNTRY PICKER
  // ==========================================================================

  Future<CountryModel?>
  _showCountryPicker({
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

    final result =
    await showModalBottomSheet<
        CountryModel>(
      context: context,

      isScrollControlled:
      true,

      backgroundColor:
      Colors.transparent,

      builder: (context) {
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
                final q =
                query
                    .trim()
                    .toLowerCase();

                if (q.isEmpty) {
                  return true;
                }

                return country.name
                    .toLowerCase()
                    .contains(q);
              },
            ).toList();

            return SafeArea(
              child: Container(
                height:
                MediaQuery.of(context)
                    .size
                    .height *
                    0.78,

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

                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),

                    const _SheetHandle(),

                    Padding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
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
                                color:
                                _text,

                                fontSize:
                                18,

                                fontWeight:
                                FontWeight
                                    .w800,
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
                              Icons
                                  .close_rounded,

                              color:
                              _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 20,
                      ),

                      child: TextField(
                        onChanged:
                            (
                            value,
                            ) {
                          setSheetState(
                                () {
                              query =
                                  value;
                            },
                          );
                        },

                        decoration:
                        InputDecoration(
                          hintText:
                          'Search country...',

                          prefixIcon:
                          const Icon(
                            Icons
                                .search_rounded,

                            color:
                            _hint,
                          ),

                          filled:
                          true,

                          fillColor:
                          _surfaceSoft,

                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              15,
                            ),

                            borderSide:
                            BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Expanded(
                      child:
                      ListView.separated(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,

                        itemCount:
                        filtered.length,

                        separatorBuilder:
                            (
                            context,
                            index,
                            ) =>
                        const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: _border,
                        ),

                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          final country =
                          filtered[
                          index];

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
                              horizontal:
                              20,
                            ),

                            leading:
                            Container(
                              width: 38,
                              height: 38,

                              decoration:
                              BoxDecoration(
                                color:
                                selected
                                    ? _primarySoft
                                    : _surfaceSoft,

                                borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                              ),

                              child:
                              Icon(
                                Icons
                                    .public_rounded,

                                color:
                                selected
                                    ? _primaryDark
                                    : _hint,

                                size:
                                17,
                              ),
                            ),

                            title: Text(
                              country.name,

                              style:
                              TextStyle(
                                color:
                                selected
                                    ? _primaryDark
                                    : _text,

                                fontWeight:
                                selected
                                    ? FontWeight
                                    .w700
                                    : FontWeight
                                    .w500,

                                fontSize:
                                13,
                              ),
                            ),

                            trailing:
                            selected
                                ? const Icon(
                              Icons
                                  .check_circle_rounded,

                              color:
                              _primaryDark,

                              size:
                              19,
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

    return result;
  }

  // ==========================================================================
  // CITY PICKER
  // ==========================================================================

  Future<String?>
  _showCityPicker({
    required CountryModel country,
    String selectedCity = '',
  }) async {
    String query = '';

    final result =
    await showModalBottomSheet<
        String>(
      context: context,

      isScrollControlled:
      true,

      backgroundColor:
      Colors.transparent,

      builder: (context) {
        return StatefulBuilder(
          builder:
              (
              context,
              setSheetState,
              ) {
            final cities =
            country.cities.where(
                  (
                  city,
                  ) {
                final q =
                query
                    .trim()
                    .toLowerCase();

                if (q.isEmpty) {
                  return true;
                }

                return city
                    .toLowerCase()
                    .contains(q);
              },
            ).toList();

            return SafeArea(
              child: Container(
                height:
                MediaQuery.of(context)
                    .size
                    .height *
                    0.78,

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

                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),

                    const _SheetHandle(),

                    Padding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
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
                                    color:
                                    _text,

                                    fontSize:
                                    18,

                                    fontWeight:
                                    FontWeight
                                        .w800,
                                  ),
                                ),

                                Text(
                                  country.name,

                                  style:
                                  const TextStyle(
                                    color:
                                    _textMuted,

                                    fontSize:
                                    10.5,
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
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 20,
                      ),

                      child: TextField(
                        onChanged:
                            (
                            value,
                            ) {
                          setSheetState(
                                () {
                              query =
                                  value;
                            },
                          );
                        },

                        decoration:
                        InputDecoration(
                          hintText:
                          'Search city...',

                          prefixIcon:
                          const Icon(
                            Icons
                                .search_rounded,

                            color:
                            _hint,
                          ),

                          filled:
                          true,

                          fillColor:
                          _surfaceSoft,

                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              15,
                            ),

                            borderSide:
                            BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Expanded(
                      child:
                      ListView.separated(
                        itemCount:
                        cities.length,

                        separatorBuilder:
                            (
                            context,
                            index,
                            ) =>
                        const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: _border,
                        ),

                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          final city =
                          cities[
                          index];

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
                              horizontal:
                              20,
                            ),

                            leading:
                            Icon(
                              Icons
                                  .location_on_outlined,

                              color:
                              selected
                                  ? _primaryDark
                                  : _hint,
                            ),

                            title: Text(
                              city,

                              style:
                              TextStyle(
                                color:
                                selected
                                    ? _primaryDark
                                    : _text,

                                fontWeight:
                                selected
                                    ? FontWeight
                                    .w700
                                    : FontWeight
                                    .w500,

                                fontSize:
                                13,
                              ),
                            ),

                            trailing:
                            selected
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

    return result;
  }

  // ==========================================================================
  // LANGUAGE
  // ==========================================================================

  void _toggleLanguage(
      String language,
      ) {
    HapticFeedback.selectionClick();

    setState(() {
      if (_languages.contains(
        language,
      )) {
        _languages.remove(
          language,
        );
      } else {
        _languages.add(
          language,
        );
      }
    });
  }

  // ==========================================================================
  // CUSTOM LANGUAGE
  // ==========================================================================

  Future<void> _addLanguage() async {
    String languageValue = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              22,
            ),
          ),

          title: const Text(
            'Add Language',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),

          content: TextField(
            autofocus: true,
            textCapitalization:
            TextCapitalization.words,

            onChanged: (value) {
              languageValue = value;
            },

            decoration: InputDecoration(
              hintText: 'Language',

              filled: true,
              fillColor: _surfaceSoft,

              prefixIcon: const Icon(
                Icons.language_rounded,
                color: _primaryDark,
                size: 18,
              ),

              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                _primaryDark,
              ),
              onPressed: () {
                final value =
                languageValue.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text(
                'Add',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == null ||
        result.trim().isEmpty) {
      return;
    }

    setState(() {
      _languages.add(
        result.trim(),
      );
    });
  }
  // ==========================================================================
  // WORK REGION
  // ==========================================================================

  Future<void> _openWorkRegionEditor({
    int? index,
  }) async {
    final existing =
    index == null
        ? const _EditableWorkRegion()
        : _workRegions[index];

    String country =
        existing.country;

    String state =
        existing.state;

    String city =
        existing.city;

    final result =
    await showModalBottomSheet<
        _EditableWorkRegion>(
      context: context,

      isScrollControlled:
      true,

      backgroundColor:
      Colors.transparent,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder:
              (
              context,
              setSheetState,
              ) {
            return SafeArea(
              top: false,

              child: Container(
                padding:
                EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  22 +
                      MediaQuery.of(context)
                          .viewInsets
                          .bottom,
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
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      const Center(
                        child:
                        _SheetHandle(),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Text(
                        index == null
                            ? 'Add Work Region'
                            : 'Edit Work Region',

                        style:
                        const TextStyle(
                          color:
                          _text,

                          fontSize:
                          18,

                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Choose where you are available to accept missions.',

                        style:
                        TextStyle(
                          color:
                          _textMuted,

                          fontSize:
                          11,

                          height:
                          1.45,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      _SheetSelectField(
                        label:
                        'Country',

                        value:
                        country,

                        hint:
                        'Select country',

                        icon:
                        Icons.public_rounded,

                        onTap: () async {
                          final selected =
                          await _showCountryPicker(
                            title:
                            'Work Country',

                            selectedName:
                            country,
                          );

                          if (selected ==
                              null) {
                            return;
                          }

                          setSheetState(
                                () {
                              country =
                                  selected
                                      .name;

                              city =
                              '';
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height: 13,
                      ),

                      _RegionTextField(
                        label:
                        'State / Province / Region',

                        value:
                        state,

                        hint:
                        'Optional',

                        icon:
                        Icons.map_outlined,

                        onChanged:
                            (
                            value,
                            ) {
                          state =
                              value;
                        },
                      ),

                      const SizedBox(
                        height: 13,
                      ),

                      _SheetSelectField(
                        label:
                        'City',

                        value:
                        city,

                        hint:
                        country.isEmpty
                            ? 'Select country first'
                            : 'Select city',

                        icon:
                        Icons
                            .location_city_outlined,

                        onTap: () async {
                          final selectedCountry =
                          _findCountry(
                            country,
                          );

                          if (selectedCountry ==
                              null) {
                            return;
                          }

                          final selectedCity =
                          await _showCityPicker(
                            country:
                            selectedCountry,

                            selectedCity:
                            city,
                          );

                          if (selectedCity ==
                              null) {
                            return;
                          }

                          setSheetState(
                                () {
                              city =
                                  selectedCity;
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      SizedBox(
                        width:
                        double.infinity,

                        child:
                        FilledButton(
                          style:
                          FilledButton
                              .styleFrom(
                            backgroundColor:
                            _primaryDark,

                            foregroundColor:
                            Colors.white,

                            padding:
                            const EdgeInsets
                                .symmetric(
                              vertical:
                              14,
                            ),

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                16,
                              ),
                            ),
                          ),

                          onPressed: () {
                            if (country
                                .trim()
                                .isEmpty) {
                              return;
                            }

                            Navigator.pop(
                              sheetContext,

                              _EditableWorkRegion(
                                country:
                                country
                                    .trim(),

                                state:
                                state
                                    .trim(),

                                city:
                                city
                                    .trim(),
                              ),
                            );
                          },

                          child: Text(
                            index == null
                                ? 'Add Region'
                                : 'Save Region',

                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .w800,
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

    if (result == null) {
      return;
    }

    setState(() {
      if (index == null) {
        _workRegions.add(
          result,
        );
      } else {
        _workRegions[index] =
            result;
      }
    });
  }

  // ==========================================================================
  // COUNTRY FIND
  // ==========================================================================

  CountryModel? _findCountry(
      String name,
      ) {
    final target =
    name
        .trim()
        .toLowerCase();

    if (target.isEmpty) {
      return null;
    }

    for (final country
    in _countries) {
      if (country.name
          .trim()
          .toLowerCase() ==
          target) {
        return country;
      }
    }

    return null;
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _EditProfileLoading();
    }

    return Scaffold(
      backgroundColor:
      _background,

      body: SafeArea(
        child: Column(
          children: [
            // ================================================================
            // HEADER
            // ================================================================

            _TopBar(
              step:
              _currentStep,

              onBack:
              _handleBack,
            ),

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                7,
                18,
                13,
              ),

              child:
              _StepIndicator(
                currentStep:
                _currentStep,
              ),
            ),

            // ================================================================
            // FORM
            // ================================================================

            Expanded(
              child:
              AnimatedSwitcher(
                duration:
                const Duration(
                  milliseconds:
                  280,
                ),

                switchInCurve:
                Curves.easeOutCubic,

                transitionBuilder:
                    (
                    child,
                    animation,
                    ) {
                  return FadeTransition(
                    opacity:
                    animation,

                    child:
                    SlideTransition(
                      position:
                      Tween<Offset>(
                        begin:
                        const Offset(
                          0.04,
                          0,
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
                },

                child:
                _currentStep == 0
                    ? _personalStep()
                    : _workStep(),
              ),
            ),

            // ================================================================
            // BOTTOM
            // ================================================================

            _BottomBar(
              currentStep:
              _currentStep,

              saving:
              _saving,

              onBack: () {
                setState(() {
                  _currentStep = 0;
                });
              },

              onContinue:
              _continue,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // PERSONAL STEP
  // ==========================================================================

  Widget _personalStep() {
    return SingleChildScrollView(
      key:
      const ValueKey(
        'personal',
      ),

      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior
          .onDrag,

      padding:
      const EdgeInsets.fromLTRB(
        18,
        2,
        18,
        28,
      ),

      child: Form(
        key:
        _personalFormKey,

        child: Column(
          children: [
            // ================================================================
            // ACCOUNT HERO
            // ================================================================

            _AccountHero(
              account:
              _account,
            ),

            const SizedBox(
              height: 14,
            ),

            // ================================================================
            // LOCKED ACCOUNT
            // ================================================================

            _SectionCard(
              icon:
              Icons.lock_outline_rounded,

              title:
              'Account Information',

              subtitle:
              'Managed by your account and cannot be changed here',

              trailing:
              const _LockedPill(),

              child: Column(
                children: [
                  _LockedField(
                    icon:
                    Icons
                        .person_outline_rounded,

                    label:
                    'Full Name',

                    value:
                    _display(
                      _account.name,
                    ),
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  _LockedField(
                    icon:
                    Icons
                        .alternate_email_rounded,

                    label:
                    'Username',

                    value:
                    _display(
                      _account.username,
                    ),
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  _LockedField(
                    icon:
                    Icons
                        .mail_outline_rounded,

                    label:
                    'Email Address',

                    value:
                    _display(
                      _account.email,
                    ),
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  _LockedField(
                    icon:
                    Icons.phone_outlined,

                    label:
                    'Phone Number',

                    value:
                    _display(
                      _account.phone,
                    ),
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  _LockedField(
                    icon:
                    Icons
                        .verified_user_outlined,

                    label:
                    'Account Status',

                    value:
                    _statusText(
                      _account.status,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ================================================================
            // EDITABLE PERSONAL
            // ================================================================

            _SectionCard(
              icon:
              Icons
                  .edit,

              title:
              'Personal Details',

              subtitle:
              'Information displayed on your pilot profile',

              child: Column(
                children: [
                  _FormField(
                    controller:
                    _dateController,

                    label:
                    'Date of Birth',

                    hint:
                    'Select date',

                    icon:
                    Icons
                        .calendar_month_outlined,

                    readOnly:
                    true,

                    onTap:
                    _pickDate,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _FormField(
                    controller:
                    _nationalityController,

                    label:
                    'Nationality',

                    hint:
                    'Select nationality',

                    icon:
                    Icons.flag_outlined,

                    readOnly:
                    true,

                    onTap:
                    _selectNationality,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _FormField(
                    controller:
                    _linkedinController,

                    label:
                    'LinkedIn Profile',

                    hint:
                    'https://linkedin.com/in/...',

                    icon:
                    Icons.link_rounded,

                    keyboardType:
                    TextInputType.url,

                    validator:
                        (
                        value,
                        ) {
                      final text =
                          value
                              ?.trim() ??
                              '';

                      if (text.isEmpty) {
                        return null;
                      }

                      final uri =
                      Uri.tryParse(
                        text,
                      );

                      if (uri ==
                          null ||
                          !uri
                              .hasScheme ||
                          (uri.scheme !=
                              'http' &&
                              uri.scheme !=
                                  'https')) {
                        return 'Enter a valid link including https://';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // WORK STEP
  // ==========================================================================

  Widget _workStep() {
    final visibleLanguages =
    <String>{
      ..._defaultLanguages,
      ..._languages,
    }.toList();

    return SingleChildScrollView(
      key:
      const ValueKey(
        'work',
      ),

      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior
          .onDrag,

      padding:
      const EdgeInsets.fromLTRB(
        18,
        2,
        18,
        28,
      ),

      child: Form(
        key:
        _workFormKey,

        child: Column(
          children: [
            // ================================================================
            // EXPERIENCE / LANGUAGES
            // ================================================================

            _SectionCard(
              icon:
              Icons
                  .workspace_premium_outlined,

              title:
              'Experience & Languages',

              subtitle:
              'Your professional experience and communication skills',

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  _TapFormField(
                    label:
                    'Years of Experience',

                    value:
                    _experienceLabel(
                      _experienceYears,
                    ),

                    icon:
                    Icons
                        .military_tech_outlined,

                    onTap:
                    _selectExperience,
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Languages',

                    style:
                    TextStyle(
                      color:
                      _text,

                      fontSize:
                      11.5,

                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,

                    children: [
                      ...visibleLanguages.map(
                            (
                            language,
                            ) {
                          return _LanguageChip(
                            text:
                            language,

                            selected:
                            _languages
                                .contains(
                              language,
                            ),

                            onTap: () {
                              _toggleLanguage(
                                language,
                              );
                            },
                          );
                        },
                      ),

                      _AddChip(
                        text:
                        'Add language',

                        onTap:
                        _addLanguage,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ================================================================
            // CURRENT LOCATION
            // ================================================================

            _SectionCard(
              icon:
              Icons
                  .my_location_rounded,

              title:
              'Current Location',

              subtitle:
              'Where you are currently based',

              child: Column(
                children: [
                  _FormField(
                    controller:
                    _currentCountryController,

                    label:
                    'Country',

                    hint:
                    'Select country',

                    icon:
                    Icons.public_rounded,

                    readOnly:
                    true,

                    onTap:
                    _selectCurrentCountry,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _FormField(
                    controller:
                    _currentStateController,

                    label:
                    'State / Province / Region',

                    hint:
                    'Optional',

                    icon:
                    Icons.map_outlined,

                    textCapitalization:
                    TextCapitalization.words,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _FormField(
                    controller:
                    _currentCityController,

                    label:
                    'City',

                    hint:
                    'Select city',

                    icon:
                    Icons
                        .location_city_outlined,

                    readOnly:
                    true,

                    onTap:
                    _selectCurrentCity,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ================================================================
            // WORK REGIONS
            // ================================================================

            _SectionCard(
              icon:
              Icons
                  .travel_explore_rounded,

              title:
              'Work Availability',

              subtitle:
              'Regions where you are available for missions',

              trailing:
              _CountPill(
                count:
                _workRegions.length,
              ),

              child: Column(
                children: [
                  if (_workRegions.isEmpty)
                    const _EmptyRegions(),

                  ...List.generate(
                    _workRegions.length,
                        (
                        index,
                        ) {
                      return Padding(
                        padding:
                        EdgeInsets.only(
                          bottom:
                          index ==
                              _workRegions
                                  .length -
                                  1
                              ? 0
                              : 9,
                        ),

                        child:
                        _RegionTile(
                          region:
                          _workRegions[
                          index],

                          onEdit: () {
                            _openWorkRegionEditor(
                              index:
                              index,
                            );
                          },

                          onDelete: () {
                            setState(() {
                              _workRegions
                                  .removeAt(
                                index,
                              );
                            });
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  SizedBox(
                    width:
                    double.infinity,

                    child:
                    OutlinedButton.icon(
                      onPressed: () {
                        _openWorkRegionEditor();
                      },

                      icon:
                      const Icon(
                        Icons.add_rounded,

                        size: 18,
                      ),

                      label:
                      const Text(
                        'Add Work Region',
                      ),

                      style:
                      OutlinedButton
                          .styleFrom(
                        foregroundColor:
                        _primaryDark,

                        side:
                        const BorderSide(
                          color:
                          _primary,
                        ),

                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical:
                          13,
                        ),

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            16,
                          ),
                        ),

                        textStyle:
                        const TextStyle(
                          fontSize:
                          11.5,

                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ================================================================
            // PROFESSIONAL BACKGROUND
            // ================================================================

            _SectionCard(
              icon:
              Icons
                  .business_center_outlined,

              title:
              'Professional Background',

              subtitle:
              'Help companies understand your experience',

              child: Column(
                children: [
                  _FormField(
                    controller:
                    _previousCompanyController,

                    label:
                    'Previous Company',

                    hint:
                    'Optional',

                    icon:
                    Icons.business_outlined,

                    textCapitalization:
                    TextCapitalization.words,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _FormField(
                    controller:
                    _bioController,

                    label:
                    'Professional Summary',

                    hint:
                    'Tell companies about your experience, specialties and the type of missions you are interested in...',

                    icon:
                    Icons.notes_rounded,

                    maxLines:
                    5,

                    textCapitalization:
                    TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
        SnackBarBehavior.floating,

        backgroundColor:
        isError
            ? _danger
            : _navy,

        margin:
        const EdgeInsets.all(
          16,
        ),

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
        ),

        content: Row(
          children: [
            Icon(
              isError
                  ? Icons
                  .error_outline_rounded
                  : Icons
                  .check_circle_outline_rounded,

              color:
              Colors.white,

              size: 18,
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: Text(
                message,

                style:
                const TextStyle(
                  color:
                  Colors.white,

                  fontSize:
                  11.5,

                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(
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
              customBorder: const CircleBorder(),
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
                  Icons.arrow_back_ios_new_rounded,
                  color: _navy,
                  size: 17,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Pilot Profile',
                  style: TextStyle(
                    color: _text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  step == 0
                      ? 'Personal & account details'
                      : 'Experience & work preferences',
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 10.3,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(
                30,
              ),
            ),
            child: Text(
              '${step + 1} / 2',
              style: const TextStyle(
                color: _primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
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

class _StepIndicator
    extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      children: [
        Expanded(
          child:
          _StepItem(
            index:
            0,

            title:
            'Personal',

            currentStep:
            currentStep,
          ),
        ),

        Container(
          width: 24,
          height: 2,

          color:
          currentStep >= 1
              ? _primary
              : _border,
        ),

        Expanded(
          child:
          _StepItem(
            index:
            1,

            title:
            'Work',

            currentStep:
            currentStep,
          ),
        ),
      ],
    );
  }
}

class _StepItem
    extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.title,
    required this.currentStep,
  });

  final int index;
  final String title;
  final int currentStep;

  @override
  Widget build(
      BuildContext context,
      ) {
    final active =
        currentStep == index;

    final completed =
        currentStep > index;

    final highlighted =
        active || completed;

    return AnimatedContainer(
      duration:
      const Duration(
        milliseconds: 220,
      ),

      padding:
      const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 9,
      ),

      decoration:
      BoxDecoration(
        color:
        highlighted
            ? _primarySoft
            : Colors.white,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border:
        Border.all(
          color:
          highlighted
              ? _primary.withOpacity(
            0.35,
          )
              : _border,
        ),
      ),

      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [
          Container(
            width: 25,
            height: 25,

            alignment:
            Alignment.center,

            decoration:
            BoxDecoration(
              color:
              highlighted
                  ? _primaryDark
                  : _surfaceSoft,

              shape:
              BoxShape.circle,
            ),

            child:
            completed
                ? const Icon(
              Icons.check_rounded,

              color:
              Colors.white,

              size: 14,
            )
                : Text(
              '${index + 1}',

              style:
              TextStyle(
                color:
                active
                    ? Colors.white
                    : _textMuted,

                fontSize:
                10,

                fontWeight:
                FontWeight
                    .w800,
              ),
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            title,

            style:
            TextStyle(
              color:
              highlighted
                  ? _primaryDark
                  : _textMuted,

              fontSize:
              10.5,

              fontWeight:
              highlighted
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACCOUNT HERO
// ============================================================================

class _AccountHero
    extends StatelessWidget {
  const _AccountHero({
    required this.account,
  });

  final PilotAccountModel account;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.all(
        17,
      ),

      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          24,
        ),

        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,

          end:
          Alignment.bottomRight,

          colors: [
            Color(
              0xFF0C334A,
            ),
            Color(
              0xFF0D7184,
            ),
            Color(
              0xFF16C6C7,
            ),
          ],
        ),

        boxShadow: [
          BoxShadow(
            color:
            _primaryDark
                .withOpacity(
              0.14,
            ),

            blurRadius:
            24,

            offset:
            const Offset(
              0,
              10,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,

            padding:
            const EdgeInsets.all(
              3,
            ),

            decoration:
            const BoxDecoration(
              color:
              Colors.white,

              shape:
              BoxShape.circle,
            ),

            child: Container(
              alignment:
              Alignment.center,

              decoration:
              const BoxDecoration(
                color:
                _primarySoft,

                shape:
                BoxShape.circle,
              ),

              child: Text(
                _initials(
                  account.displayName,
                ),

                style:
                const TextStyle(
                  color:
                  _navy,

                  fontSize:
                  20,

                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  account.displayName,

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,

                    fontSize:
                    18,

                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                if (account
                    .displayUsername
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    account
                        .displayUsername,

                    style:
                    TextStyle(
                      color:
                      Colors.white
                          .withOpacity(
                        0.70,
                      ),

                      fontSize:
                      11,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 8,
                ),

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
                    color:
                    Colors.white
                        .withOpacity(
                      0.13,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),
                  ),

                  child:
                  const Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      Icon(
                        Icons
                            .lock_outline_rounded,

                        color:
                        Colors.white,

                        size:
                        11,
                      ),

                      SizedBox(
                        width:
                        5,
                      ),

                      Text(
                        'Account identity protected',

                        style:
                        TextStyle(
                          color:
                          Colors.white,

                          fontSize:
                          9,

                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ],
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
// SECTION CARD
// ============================================================================

class _SectionCard
    extends StatelessWidget {
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
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.all(
        16,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(
          23,
        ),

        border:
        Border.all(
          color:
          _border,
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.028,
            ),

            blurRadius:
            18,

            offset:
            const Offset(
              0,
              7,
            ),
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
                width: 40,
                height: 40,

                decoration:
                BoxDecoration(
                  color:
                  _primarySoft,

                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),

                child: Icon(
                  icon,

                  color:
                  _primaryDark,

                  size: 18,
                ),
              ),

              const SizedBox(
                width: 10,
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
                        color:
                        _text,

                        fontSize:
                        14.5,

                        fontWeight:
                        FontWeight.w800,
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
                        _hint,

                        fontSize:
                        9.7,

                        height:
                        1.3,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null)
                trailing!,
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          child,
        ],
      ),
    );
  }
}

// ============================================================================
// LOCKED FIELD
// ============================================================================

class _LockedField
    extends StatelessWidget {
  const _LockedField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF5F7F9,
        ),

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border:
        Border.all(
          color:
          _border,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,

            decoration:
            const BoxDecoration(
              color:
              Colors.white,

              shape:
              BoxShape.circle,
            ),

            child: Icon(
              icon,

              color:
              _hint,

              size: 16,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style:
                  const TextStyle(
                    color:
                    _hint,

                    fontSize: 9.2,

                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(
                    color:
                    _textMuted,

                    fontSize: 11.7,

                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.lock_outline_rounded,

            size: 15,

            color:
            _hint,
          ),
        ],
      ),
    );
  }
}

class _LockedPill
    extends StatelessWidget {
  const _LockedPill();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration:
      BoxDecoration(
        color:
        _surfaceSoft,

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
            Icons.lock_outline_rounded,

            size: 11,

            color:
            _hint,
          ),

          SizedBox(
            width: 4,
          ),

          Text(
            'Locked',

            style:
            TextStyle(
              color:
              _textMuted,

              fontSize:
              8.7,

              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORM FIELD
// ============================================================================

class _FormField
    extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.textCapitalization =
        TextCapitalization.none,
  });

  final TextEditingController
  controller;

  final String label;
  final String hint;

  final IconData icon;

  final TextInputType?
  keyboardType;

  final int maxLines;

  final bool readOnly;

  final VoidCallback? onTap;

  final String? Function(String?)?
  validator;

  final TextCapitalization
  textCapitalization;

  @override
  Widget build(
      BuildContext context,
      ) {
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
              color:
              _text,

              fontSize:
              11.4,

              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),

        TextFormField(
          controller:
          controller,

          readOnly:
          readOnly,

          onTap:
          onTap,

          maxLines:
          maxLines,

          keyboardType:
          keyboardType,

          validator:
          validator,

          textCapitalization:
          textCapitalization,

          style:
          const TextStyle(
            color:
            _text,

            fontSize:
            12.5,

            fontWeight:
            FontWeight.w600,
          ),

          decoration:
          InputDecoration(
            hintText:
            hint,

            hintStyle:
            const TextStyle(
              color:
              _hint,

              fontSize:
              11.5,
            ),

            prefixIcon:
            Icon(
              icon,

              color:
              _primaryDark,

              size:
              18,
            ),

            suffixIcon:
            readOnly
                ? const Icon(
              Icons
                  .keyboard_arrow_down_rounded,

              color:
              _hint,
            )
                : null,

            filled:
            true,

            fillColor:
            _surfaceSoft,

            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal:
              14,

              vertical:
              13,
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),

              borderSide:
              const BorderSide(
                color:
                _border,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),

              borderSide:
              const BorderSide(
                color:
                _primary,

                width:
                1.3,
              ),
            ),

            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),

              borderSide:
              const BorderSide(
                color:
                _danger,
              ),
            ),

            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),

              borderSide:
              const BorderSide(
                color:
                _danger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAP FORM FIELD
// ============================================================================

class _TapFormField
    extends StatelessWidget {
  const _TapFormField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
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
              color:
              _text,

              fontSize:
              11.4,

              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),

        Material(
          color:
          _surfaceSoft,

          borderRadius:
          BorderRadius.circular(
            16,
          ),

          child: InkWell(
            onTap:
            onTap,

            borderRadius:
            BorderRadius.circular(
              16,
            ),

            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal:
                13,

                vertical:
                12,
              ),

              decoration:
              BoxDecoration(
                border:
                Border.all(
                  color:
                  _border,
                ),

                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),

              child: Row(
                children: [
                  Icon(
                    icon,

                    size: 18,

                    color:
                    _primaryDark,
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child: Text(
                      value,

                      style:
                      const TextStyle(
                        color:
                        _text,

                        fontSize:
                        12.5,

                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,

                    color:
                    _hint,
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
// LANGUAGE CHIP
// ============================================================================

class _LanguageChip
    extends StatelessWidget {
  const _LanguageChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return InkWell(
      onTap:
      onTap,

      borderRadius:
      BorderRadius.circular(
        30,
      ),

      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 180,
        ),

        padding:
        const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),

        decoration:
        BoxDecoration(
          color:
          selected
              ? _primarySoft
              : _surfaceSoft,

          borderRadius:
          BorderRadius.circular(
            30,
          ),

          border:
          Border.all(
            color:
            selected
                ? _primary
                : _border,
          ),
        ),

        child: Row(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Icon(
              selected
                  ? Icons
                  .check_circle_rounded
                  : Icons
                  .language_rounded,

              size: 14,

              color:
              selected
                  ? _primaryDark
                  : _hint,
            ),

            const SizedBox(
              width: 5,
            ),

            Text(
              text,

              style:
              TextStyle(
                color:
                selected
                    ? _primaryDark
                    : _textMuted,

                fontSize:
                10.5,

                fontWeight:
                selected
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChip
    extends StatelessWidget {
  const _AddChip({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return InkWell(
      onTap:
      onTap,

      borderRadius:
      BorderRadius.circular(
        30,
      ),

      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),

        decoration:
        BoxDecoration(
          color:
          Colors.white,

          borderRadius:
          BorderRadius.circular(
            30,
          ),

          border:
          Border.all(
            color:
            _primary.withOpacity(
              0.5,
            ),
          ),
        ),

        child:
        const Row(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Icon(
              Icons.add_rounded,

              size: 14,

              color:
              _primaryDark,
            ),

            SizedBox(
              width: 5,
            ),

            Text(
              'Add language',

              style:
              TextStyle(
                color:
                _primaryDark,

                fontSize:
                10.5,

                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REGION TILE
// ============================================================================

class _RegionTile
    extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.onEdit,
    required this.onDelete,
  });

  final _EditableWorkRegion
  region;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        10,
        5,
        10,
      ),

      decoration:
      BoxDecoration(
        color:
        _primarySoft,

        borderRadius:
        BorderRadius.circular(
          17,
        ),

        border:
        Border.all(
          color:
          _primary.withOpacity(
            0.16,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,

            decoration:
            const BoxDecoration(
              color:
              Colors.white,

              shape:
              BoxShape.circle,
            ),

            child:
            const Icon(
              Icons.location_on_outlined,

              color:
              _primaryDark,

              size: 17,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  region.country,

                  style:
                  const TextStyle(
                    color:
                    _text,

                    fontSize: 11.8,

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  region.displayLabel,

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(
                    color:
                    _textMuted,

                    fontSize: 9.7,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed:
            onEdit,

            icon:
            const Icon(
              Icons.edit_outlined,

              color:
              _primaryDark,

              size: 17,
            ),
          ),

          IconButton(
            onPressed:
            onDelete,

            icon:
            const Icon(
              Icons
                  .delete_outline_rounded,

              color:
              _danger,

              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WORK REGION SHEET FIELDS
// ============================================================================

class _SheetSelectField
    extends StatelessWidget {
  const _SheetSelectField({
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
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style:
          const TextStyle(
            color:
            _text,

            fontSize:
            11.5,

            fontWeight:
            FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        InkWell(
          onTap:
          onTap,

          borderRadius:
          BorderRadius.circular(
            16,
          ),

          child: Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),

            decoration:
            BoxDecoration(
              color:
              _surfaceSoft,

              borderRadius:
              BorderRadius.circular(
                16,
              ),

              border:
              Border.all(
                color:
                _border,
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

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    value.trim().isEmpty
                        ? hint
                        : value,

                    style:
                    TextStyle(
                      color:
                      value
                          .trim()
                          .isEmpty
                          ? _hint
                          : _text,

                      fontSize:
                      12.5,

                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,

                  color:
                  _hint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RegionTextField
    extends StatelessWidget {
  const _RegionTextField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 2,
            bottom: 7,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _text,
              fontSize: 11.4,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),

        TextFormField(
          initialValue: value,

          onChanged: onChanged,

          textCapitalization:
          TextCapitalization.words,

          style: const TextStyle(
            color: _text,
            fontSize: 12.5,
            fontWeight:
            FontWeight.w600,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: const TextStyle(
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
              BorderRadius.circular(
                16,
              ),
              borderSide:
              const BorderSide(
                color: _border,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              borderSide:
              const BorderSide(
                color: _primary,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// ============================================================================
// EMPTY REGIONS / COUNT
// ============================================================================

class _EmptyRegions
    extends StatelessWidget {
  const _EmptyRegions();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),

      decoration:
      BoxDecoration(
        color:
        _surfaceSoft,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border:
        Border.all(
          color:
          _border,
        ),
      ),

      child:
      const Column(
        children: [
          Icon(
            Icons
                .travel_explore_outlined,

            color:
            _hint,

            size: 24,
          ),

          SizedBox(
            height: 6,
          ),

          Text(
            'No work regions selected',

            style:
            TextStyle(
              color:
              _textMuted,

              fontSize:
              10.5,

              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill
    extends StatelessWidget {
  const _CountPill({
    required this.count,
  });

  final int count;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
      BoxDecoration(
        color:
        _primarySoft,

        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),

      child: Text(
        '$count',

        style:
        const TextStyle(
          color:
          _primaryDark,

          fontSize:
          9.5,

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

class _BottomBar
    extends StatelessWidget {
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
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        11,
        18,
        12,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        border:
        const Border(
          top: BorderSide(
            color:
            _border,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.035,
            ),

            blurRadius:
            16,

            offset:
            const Offset(
              0,
              -5,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          if (currentStep == 1) ...[
            Expanded(
              child:
              OutlinedButton(
                onPressed:
                saving
                    ? null
                    : onBack,

                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  _text,

                  side:
                  const BorderSide(
                    color:
                    _border,
                  ),

                  padding:
                  const EdgeInsets.symmetric(
                    vertical:
                    14,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      17,
                    ),
                  ),
                ),

                child:
                const Text(
                  'Back',

                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),
          ],

          Expanded(
            flex:
            currentStep == 1
                ? 2
                : 1,

            child:
            FilledButton(
              onPressed:
              saving
                  ? null
                  : onContinue,

              style:
              FilledButton.styleFrom(
                backgroundColor:
                _primaryDark,

                foregroundColor:
                Colors.white,

                disabledBackgroundColor:
                _primaryDark
                    .withOpacity(
                  0.55,
                ),

                padding:
                const EdgeInsets.symmetric(
                  vertical:
                  14,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    17,
                  ),
                ),
              ),

              child:
              saving
                  ? const SizedBox(
                width: 20,
                height: 20,

                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2.2,

                  valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                    Colors.white,
                  ),
                ),
              )
                  : Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,

                children: [
                  Icon(
                    currentStep ==
                        0
                        ? Icons
                        .arrow_forward_rounded
                        : Icons
                        .check_rounded,

                    size: 17,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    currentStep ==
                        0
                        ? 'Continue'
                        : 'Save Changes',

                    style:
                    const TextStyle(
                      fontSize:
                      12,

                      fontWeight:
                      FontWeight
                          .w800,
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
// SHEET HANDLE
// ============================================================================

class _SheetHandle
    extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: 42,
      height: 4,

      decoration:
      BoxDecoration(
        color:
        _border,

        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _EditProfileLoading
    extends StatelessWidget {
  const _EditProfileLoading();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      _background,

      body:
      const SafeArea(
        child: Center(
          child:
          CircularProgressIndicator(
            color:
            _primaryDark,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOCAL WORK REGION MODEL
// ============================================================================

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
    final parts =
    <String>[
      city,
      state,
      country,
    ].where(
          (
          value,
          ) =>
      value.trim().isNotEmpty,
    ).toList();

    if (parts.isEmpty) {
      return 'Region';
    }

    return parts.join(
      ', ',
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

String _display(
    String value,
    ) {
  final text =
  value.trim();

  return text.isEmpty
      ? 'Not available'
      : text;
}

String _formatDate(
    DateTime? date,
    ) {
  if (date == null) {
    return '';
  }

  final day =
  date.day
      .toString()
      .padLeft(
    2,
    '0',
  );

  final month =
  date.month
      .toString()
      .padLeft(
    2,
    '0',
  );

  return '$day/$month/${date.year}';
}

String _experienceLabel(
    int years,
    ) {
  if (years <= 0) {
    return 'Less than 1 year';
  }

  if (years == 1) {
    return '1 year';
  }

  return '$years years';
}

String _statusText(
    String status,
    ) {
  final text =
  status.trim();

  if (text.isEmpty) {
    return 'Pilot';
  }

  return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
}

String _initials(
    String name,
    ) {
  final parts =
  name
      .trim()
      .split(
    RegExp(
      r'\s+',
    ),
  )
      .where(
        (
        part,
        ) =>
    part.isNotEmpty,
  )
      .toList();

  if (parts.isEmpty) {
    return 'P';
  }

  if (parts.length == 1) {
    final word =
        parts.first;

    return word
        .substring(
      0,
      word.length >= 2
          ? 2
          : 1,
    )
        .toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'
      .toUpperCase();
}

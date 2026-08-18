import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/auth/controllers/auth_controller.dart';
import 'package:tototl_app/features/auth/screens/register/pilot/pilot_register_step_tow_screen.dart';

import '../../../../../model/Country.dart';

class PilotRegisterStepOneScreen extends StatefulWidget {
  final AuthController authController;

  const PilotRegisterStepOneScreen({
    super.key,
    required this.authController,
  });

  @override
  State<PilotRegisterStepOneScreen> createState() =>
      _PilotRegisterStepOneScreenState();
}

class _PilotRegisterStepOneScreenState
    extends State<PilotRegisterStepOneScreen>
    with TickerProviderStateMixin {
  // ===========================================================================
  // FORM
  // ===========================================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController =
  TextEditingController();

  final TextEditingController _usernameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _dobController =
  TextEditingController();

  final TextEditingController _linkedinController =
  TextEditingController();

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isPickingImage = false;
  bool _isSubmitting = false;
  bool _registrationSuccess = false;

  bool _buttonPressed = false;

  File? _avatarImage;

  DateTime? _selectedDateOfBirth;

  String? _selectedNationality;

  final ImagePicker _picker = ImagePicker();

  List<Country> _countries = [];
  Country? _selectedCountry;

  // ===========================================================================
  // ANIMATION
  // ===========================================================================

  late final AnimationController _pageAnimationController;
  late final AnimationController _avatarAnimationController;

  late final Animation<double> _avatarFloatAnimation;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _avatarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _avatarFloatAnimation = Tween<double>(
      begin: -2.5,
      end: 2.5,
    ).animate(
      CurvedAnimation(
        parent: _avatarAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pageAnimationController.forward();

    _avatarAnimationController.repeat(
      reverse: true,
    );

    _loadCountries();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _linkedinController.dispose();

    _pageAnimationController.dispose();
    _avatarAnimationController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // ENTRANCE ANIMATION
  // ===========================================================================

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final start =
    (index * 0.065).clamp(0.0, 0.68).toDouble();

    final end =
    (start + 0.32).clamp(0.0, 1.0).toDouble();

    final animation = CurvedAnimation(
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
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ===========================================================================
  // PROFILE IMAGE
  // ===========================================================================

  Future<void> _pickImage(
      ImageSource source,
      ) async {
    if (_isPickingImage || _isSubmitting) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _isPickingImage = true;
    });

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (picked == null) {
        return;
      }

      final file = File(picked.path);

      if (!await file.exists()) {
        if (mounted) {
          _showSnack(
            'The selected image could not be found.',
            isError: true,
          );
        }

        return;
      }

      final size = await file.length();

      if (size > 10 * 1024 * 1024) {
        if (mounted) {
          _showSnack(
            'Profile photo must be smaller than 10 MB.',
            isError: true,
          );
        }

        return;
      }

      if (!mounted) return;

      setState(() {
        _avatarImage = file;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Could not open image. Please check app permissions.',
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

  void _showImageSourceActionSheet() {
    if (_isSubmitting) return;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              28,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.kBorder,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profile Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add a clear photo for your pilot profile.',
                      style: TextStyle(
                        color: AppColors.kTextMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildImageOption(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take a Photo',
                    subtitle: 'Use your device camera',
                    onTap: () {
                      Navigator.pop(context);

                      _pickImage(
                        ImageSource.camera,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildImageOption(
                    icon:
                    Icons.photo_library_rounded,
                    title: 'Choose from Gallery',
                    subtitle:
                    'Select an existing photo',
                    onTap: () {
                      Navigator.pop(context);

                      _pickImage(
                        ImageSource.gallery,
                      );
                    },
                  ),

                  if (_avatarImage != null) ...[
                    const SizedBox(height: 10),

                    _buildImageOption(
                      icon:
                      Icons.delete_outline_rounded,
                      title: 'Remove Photo',
                      subtitle:
                      'Choose another photo later',
                      destructive: true,
                      onTap: () {
                        Navigator.pop(context);

                        setState(() {
                          _avatarImage = null;
                        });
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

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive
        ? AppColors.kDanger
        : AppColors.kPrimary;

    return Material(
      color: destructive
          ? AppColors.kDanger.withOpacity(0.05)
          : AppColors.kSurfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive
                            ? color
                            : AppColors.kTextDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                        AppColors.kTextMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return AnimatedBuilder(
      animation: _avatarFloatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            _avatarFloatAnimation.value,
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _showImageSourceActionSheet,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end:
                      Alignment.bottomRight,
                      colors: [
                        AppColors.kPrimary
                            .withOpacity(0.25),
                        AppColors.kPrimary
                            .withOpacity(0.04),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kPrimary
                            .withOpacity(0.13),
                        blurRadius: 24,
                        offset:
                        const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding:
                  const EdgeInsets.all(4),
                  child: Container(
                    decoration:
                    const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding:
                    const EdgeInsets.all(3),
                    child: ClipOval(
                      child: AnimatedSwitcher(
                        duration:
                        const Duration(
                          milliseconds: 300,
                        ),
                        child: _isPickingImage
                            ? const Center(
                          key: ValueKey(
                            'loading',
                          ),
                          child: SizedBox(
                            width: 25,
                            height: 25,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2.3,
                              color: AppColors
                                  .kPrimary,
                            ),
                          ),
                        )
                            : _avatarImage != null
                            ? Image.file(
                          _avatarImage!,
                          key: ValueKey(
                            _avatarImage!
                                .path,
                          ),
                          fit:
                          BoxFit.cover,
                          width: 98,
                          height: 98,
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
                            Icons
                                .person_rounded,
                            size: 58,
                            color: Color(
                              0xFFB8C6CE,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: -1,
                  bottom: 3,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                      const LinearGradient(
                        colors: [
                          Color(0xFF0D8AA5),
                          AppColors.kPrimary,
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors
                              .kPrimary
                              .withOpacity(0.25),
                          blurRadius: 10,
                          offset:
                          const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Add profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.kPrimary,
              ),
            ),

            const SizedBox(height: 3),

            const Text(
              'Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.kTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DATE
  // ===========================================================================

  Future<void> _pickDate() async {
    if (_isSubmitting) return;

    HapticFeedback.selectionClick();

    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate:
      _selectedDateOfBirth ??
          DateTime(
            now.year - 25,
            now.month,
            now.day,
          ),
      firstDate: DateTime(
        now.year - 100,
      ),
      lastDate: DateTime(
        now.year - 18,
        now.month,
        now.day,
      ),
      builder: (
          context,
          child,
          ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
            const ColorScheme.light(
              primary: AppColors.kPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    HapticFeedback.selectionClick();

    setState(() {
      _selectedDateOfBirth = picked;

      _dobController.text =
          DateFormat('dd / MM / yyyy')
              .format(picked);
    });
  }

  // ===========================================================================
  // LOAD COUNTRIES
  // ===========================================================================

  Future<void> _loadCountries() async {
    try {
      final jsonString =
      await rootBundle.loadString(
        'assets/data/countries.json',
      );

      final List<dynamic> data =
      json.decode(jsonString);

      final countries = data
          .map(
            (item) =>
            Country.fromJson(item),
      )
          .toList();

      if (!mounted) return;

      Country? defaultCountry;

      for (final country in countries) {
        final name =
        country.name.toLowerCase();

        if (country.dialCode == '+970' ||
            name.contains('palestin')) {
          defaultCountry = country;
          break;
        }
      }

      setState(() {
        _countries = countries;

        if (_countries.isNotEmpty) {
          _selectedCountry =
              defaultCountry ??
                  _countries.first;
        }
      });

      debugPrint(
        'Countries loaded: ${_countries.length}',
      );

      debugPrint(
        'Default phone country: ${_selectedCountry?.name}',
      );
    } catch (e) {
      debugPrint(
        'Error loading countries: $e',
      );
    }
  }

  // ===========================================================================
  // COUNTRY CODE PICKER
  // ===========================================================================

  Future<void> _showCountryPicker() async {
    if (_countries.isEmpty ||
        _isSubmitting) {
      return;
    }

    HapticFeedback.lightImpact();

    String search = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            final filtered =
            _countries.where((country) {
              final query =
              search.trim().toLowerCase();

              if (query.isEmpty) {
                return true;
              }

              return country.name
                  .toLowerCase()
                  .contains(query) ||
                  country.dialCode
                      .toLowerCase()
                      .contains(query);
            }).toList();

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.78,
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
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                          AppColors.kBorder,
                          borderRadius:
                          BorderRadius
                              .circular(20),
                        ),
                      ),

                      const SizedBox(height: 18),

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
                                    'Country Code',
                                    style:
                                    TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight
                                          .w800,
                                      color:
                                      AppColors
                                          .kTextDark,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    'Select your calling code',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      11.5,
                                      color:
                                      AppColors
                                          .kTextMuted,
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
                              icon: const Icon(
                                Icons
                                    .close_rounded,
                                color:
                                AppColors.kHint,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setModalState(() {
                              search = value;
                            });
                          },
                          decoration:
                          InputDecoration(
                            hintText:
                            'Search country or code',
                            hintStyle:
                            const TextStyle(
                              color:
                              AppColors.kHint,
                              fontSize: 13,
                            ),
                            prefixIcon:
                            const Icon(
                              Icons
                                  .search_rounded,
                              color:
                              AppColors.kHint,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors
                                .kSurfaceSoft,
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 13,
                            ),
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

                      const SizedBox(height: 12),

                      const Divider(
                        height: 1,
                        color: AppColors.kBorder,
                      ),

                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                          child: Text(
                            'No countries found',
                            style:
                            TextStyle(
                              color: AppColors
                                  .kTextMuted,
                            ),
                          ),
                        )
                            : ListView.separated(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior
                              .onDrag,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 6,
                          ),
                          itemCount:
                          filtered.length,
                          separatorBuilder:
                              (_, __) =>
                          const Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                            color: AppColors
                                .kBorder,
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
                                _selectedCountry
                                    ?.name ==
                                    country
                                        .name &&
                                    _selectedCountry
                                        ?.dialCode ==
                                        country
                                            .dialCode;

                            return InkWell(
                              onTap: () {
                                HapticFeedback
                                    .selectionClick();

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
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  18,
                                  vertical:
                                  13,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child:
                                      Text(
                                        country
                                            .name,
                                        maxLines:
                                        1,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
                                        style:
                                        TextStyle(
                                          fontSize:
                                          13.5,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected
                                              ? AppColors.kPrimary
                                              : AppColors.kTextDark,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width:
                                      8,
                                    ),

                                    Text(
                                      country
                                          .dialCode,
                                      style:
                                      TextStyle(
                                        fontSize:
                                        13,
                                        fontWeight:
                                        FontWeight
                                            .w700,
                                        color: selected
                                            ? AppColors.kPrimary
                                            : AppColors.kTextMuted,
                                      ),
                                    ),

                                    const SizedBox(
                                      width:
                                      8,
                                    ),

                                    SizedBox(
                                      width:
                                      20,
                                      child:
                                      selected
                                          ? const Icon(
                                        Icons.check_circle_rounded,
                                        size: 19,
                                        color: AppColors.kPrimary,
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

  // ===========================================================================
  // NATIONALITY PICKER
  // ===========================================================================

  Future<void> _showNationalityPicker({
    required ValueChanged<String>
    onSelected,
  }) async {
    if (_countries.isEmpty ||
        _isSubmitting) {
      return;
    }

    HapticFeedback.lightImpact();

    String search = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            final filtered =
            _countries.where((country) {
              final query =
              search.trim().toLowerCase();

              if (query.isEmpty) {
                return true;
              }

              return country.name
                  .toLowerCase()
                  .contains(query);
            }).toList();

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.78,
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
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                          AppColors.kBorder,
                          borderRadius:
                          BorderRadius
                              .circular(20),
                        ),
                      ),

                      const SizedBox(height: 18),

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
                                    'Nationality',
                                    style:
                                    TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight
                                          .w800,
                                      color:
                                      AppColors
                                          .kTextDark,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    'Select your nationality',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      11.5,
                                      color:
                                      AppColors
                                          .kTextMuted,
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
                              icon: const Icon(
                                Icons
                                    .close_rounded,
                                color:
                                AppColors.kHint,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setModalState(() {
                              search = value;
                            });
                          },
                          decoration:
                          InputDecoration(
                            hintText:
                            'Search nationality',
                            hintStyle:
                            const TextStyle(
                              color:
                              AppColors.kHint,
                              fontSize: 13,
                            ),
                            prefixIcon:
                            const Icon(
                              Icons
                                  .search_rounded,
                              color:
                              AppColors.kHint,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors
                                .kSurfaceSoft,
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 13,
                            ),
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

                      const SizedBox(height: 12),

                      const Divider(
                        height: 1,
                        color: AppColors.kBorder,
                      ),

                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                          child: Text(
                            'No results found',
                            style:
                            TextStyle(
                              color: AppColors
                                  .kTextMuted,
                            ),
                          ),
                        )
                            : ListView.separated(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior
                              .onDrag,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 6,
                          ),
                          itemCount:
                          filtered.length,
                          separatorBuilder:
                              (_, __) =>
                          const Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                            color: AppColors
                                .kBorder,
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
                                _selectedNationality ==
                                    country
                                        .name;

                            return InkWell(
                              onTap: () {
                                HapticFeedback
                                    .selectionClick();

                                onSelected(
                                  country
                                      .name,
                                );

                                Navigator.pop(
                                  context,
                                );
                              },
                              child:
                              Padding(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  18,
                                  vertical:
                                  14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .flag_outlined,
                                      size:
                                      17,
                                      color: selected
                                          ? AppColors.kPrimary
                                          : AppColors.kHint,
                                    ),

                                    const SizedBox(
                                      width:
                                      11,
                                    ),

                                    Expanded(
                                      child:
                                      Text(
                                        country
                                            .name,
                                        maxLines:
                                        1,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,
                                        style:
                                        TextStyle(
                                          fontSize:
                                          13.5,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected
                                              ? AppColors.kPrimary
                                              : AppColors.kTextDark,
                                        ),
                                      ),
                                    ),

                                    if (selected)
                                      const Icon(
                                        Icons
                                            .check_circle_rounded,
                                        size:
                                        19,
                                        color:
                                        AppColors.kPrimary,
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

  // ===========================================================================
  // BACKEND REGISTER
  // ===========================================================================

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

    // Profile photo is required
    if (_avatarImage == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please add your profile photo.',
        isError: true,
      );

      return;
    }

    if (_selectedNationality == null ||
        _selectedNationality!
            .trim()
            .isEmpty) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select your nationality.',
        isError: true,
      );

      return;
    }

    if (_selectedDateOfBirth == null) {
      HapticFeedback.heavyImpact();

      _showSnack(
        'Please select your date of birth.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
      _registrationSuccess = false;
    });

    try {
      // ===============================================================
      // PHONE
      // ===============================================================

      final dialCode =
          _selectedCountry?.dialCode ??
              '+970';

      String phone =
      _phoneController.text.trim();

      phone = phone.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }

      final fullPhone =
          '$dialCode$phone';

      // ===============================================================
      // API
      // ===============================================================

      final response =
      await widget.authController
          .pilotRegister(
        name:
        _fullNameController.text.trim(),

        username:
        _usernameController.text.trim(),

        email:
        _emailController.text.trim(),

        password:
        _passwordController.text,

        passwordConfirmation:
        _confirmPasswordController.text,

        phone: fullPhone,

        dateOfBirth: DateFormat(
          'yyyy-MM-dd',
        ).format(
          _selectedDateOfBirth!,
        ),

        nationality:
        _selectedNationality!,

        // Only LinkedIn is optional
        linkedinUrl:
        _linkedinController.text
            .trim()
            .isEmpty
            ? null
            : _linkedinController.text
            .trim(),

        imagePath:
        _avatarImage!.path,
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

      setState(() {
        _registrationSuccess = true;
      });

      HapticFeedback.mediumImpact();

      _showSnack(
        'Pilot account created successfully!',
      );

      await Future.delayed(
        const Duration(milliseconds: 650),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
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
            return const PilotRegisterStepTwoScreen();
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
          _isSubmitting = false;
        });
      }
    }
  }

  // ===========================================================================
  // SNACK BAR
  // ===========================================================================

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
          margin:
          const EdgeInsets.all(18),
          elevation: 8,
          backgroundColor: isError
              ? const Color(0xFFE95C67)
              : const Color(0xFF168F8A),
          shape: RoundedRectangleBorder(
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
                    height: 1.3,
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

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor:
      const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          // ===============================================================
          // BACKGROUND DECORATION
          // ===============================================================

          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                  RadialGradient(
                    colors: [
                      AppColors.kPrimary
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
            top: 400,
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
                            // =============================================
                            // HEADER
                            // =============================================

                            _animatedEntry(
                              index: 0,
                              child:
                              _buildHeader(),
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            // =============================================
                            // SMALL BADGE
                            // =============================================

                            _animatedEntry(
                              index: 1,
                              child:
                              _buildPilotBadge(),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // =============================================
                            // TITLE
                            // =============================================

                            _animatedEntry(
                              index: 2,
                              child: const Text(
                                'Create Pilot Account',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color: AppColors
                                      .kTextDark,
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
                              child: const Text(
                                'Complete your basic information to create your pilot account.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color: AppColors
                                      .kTextMuted,
                                  fontWeight:
                                  FontWeight
                                      .w400,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 25,
                            ),

                            // =============================================
                            // PHOTO
                            // =============================================

                            _animatedEntry(
                              index: 4,
                              child: Center(
                                child:
                                _buildAvatarPicker(),
                              ),
                            ),

                            const SizedBox(
                              height: 32,
                            ),

                            // =============================================
                            // SECTION TITLE
                            // =============================================

                            _animatedEntry(
                              index: 5,
                              child:
                              _buildSectionHeader(),
                            ),

                            const SizedBox(
                              height: 17,
                            ),

                            // =============================================
                            // FORM - NO WHITE CARD
                            // =============================================

                            _animatedEntry(
                              index: 6,
                              child: Column(
                                children: [
                                  // Full Name
                                  _buildTextField(
                                    controller:
                                    _fullNameController,
                                    hintText:
                                    'Full Name',
                                    prefixIcon:
                                    Icons
                                        .person_outline_rounded,
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
                                        return 'Full Name is required';
                                      }

                                      if (value
                                          .trim()
                                          .length <
                                          2) {
                                        return 'Enter your full name';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // Username
                                  _buildTextField(
                                    controller:
                                    _usernameController,
                                    hintText:
                                    'Username',
                                    prefixIcon:
                                    Icons
                                        .alternate_email_rounded,
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
                                        return 'Username is required';
                                      }

                                      if (value
                                          .trim()
                                          .length <
                                          3) {
                                        return 'Username must be at least 3 characters';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // Email
                                  _buildTextField(
                                    controller:
                                    _emailController,
                                    hintText:
                                    'Email Address',
                                    prefixIcon:
                                    Icons
                                        .email_outlined,
                                    keyboardType:
                                    TextInputType
                                        .emailAddress,
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
                                        return 'Email is required';
                                      }

                                      final regex =
                                      RegExp(
                                        r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$',
                                      );

                                      if (!regex
                                          .hasMatch(
                                        value
                                            .trim(),
                                      )) {
                                        return 'Enter a valid email address';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // Password
                                  _buildTextField(
                                    controller:
                                    _passwordController,
                                    hintText:
                                    'Password',
                                    prefixIcon:
                                    Icons
                                        .lock_outline_rounded,
                                    obscureText:
                                    _obscurePassword,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    suffixIcon:
                                    IconButton(
                                      onPressed:
                                      _isSubmitting
                                          ? null
                                          : () {
                                        HapticFeedback
                                            .selectionClick();

                                        setState(
                                              () {
                                            _obscurePassword =
                                            !_obscurePassword;
                                          },
                                        );
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
                                          AppColors.kHint,
                                        ),
                                      ),
                                    ),
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .isEmpty) {
                                        return 'Password is required';
                                      }

                                      if (value
                                          .length <
                                          6) {
                                        return 'Password must be at least 6 characters';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // Confirm Password
                                  _buildTextField(
                                    controller:
                                    _confirmPasswordController,
                                    hintText:
                                    'Confirm Password',
                                    prefixIcon:
                                    Icons
                                        .lock_reset_rounded,
                                    obscureText:
                                    _obscureConfirmPassword,
                                    textInputAction:
                                    TextInputAction
                                        .next,
                                    suffixIcon:
                                    IconButton(
                                      onPressed:
                                      _isSubmitting
                                          ? null
                                          : () {
                                        HapticFeedback
                                            .selectionClick();

                                        setState(
                                              () {
                                            _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                          },
                                        );
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
                                          AppColors.kHint,
                                        ),
                                      ),
                                    ),
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .isEmpty) {
                                        return 'Confirm Password is required';
                                      }

                                      if (value !=
                                          _passwordController
                                              .text) {
                                        return 'Passwords do not match';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // Phone
                                  _buildPhoneField(),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // Birth Date
                                  _buildTextField(
                                    controller:
                                    _dobController,
                                    hintText:
                                    'Date of Birth',
                                    prefixIcon:
                                    Icons
                                        .calendar_month_outlined,
                                    readOnly:
                                    true,
                                    onTap:
                                    _pickDate,
                                    suffixIcon:
                                    const Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,
                                      color:
                                      AppColors.kHint,
                                      size:
                                      20,
                                    ),
                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Date of Birth is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // Nationality
                                  _buildNationalityField(),

                                  const SizedBox(
                                    height: 13,
                                  ),

                                  // LinkedIn - ONLY OPTIONAL FIELD
                                  _buildTextField(
                                    controller:
                                    _linkedinController,
                                    hintText:
                                    'LinkedIn Profile URL (optional)',
                                    prefixIcon:
                                    Icons
                                        .link_rounded,
                                    keyboardType:
                                    TextInputType
                                        .url,
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
                                        return null;
                                      }

                                      final uri =
                                      Uri.tryParse(
                                        value
                                            .trim(),
                                      );

                                      if (uri ==
                                          null ||
                                          !uri
                                              .hasScheme ||
                                          uri.host
                                              .isEmpty ||
                                          (uri.scheme !=
                                              'http' &&
                                              uri.scheme !=
                                                  'https')) {
                                        return 'Enter a valid URL including https://';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 28,
                            ),

                            // =============================================
                            // BUTTON
                            // =============================================

                            _animatedEntry(
                              index: 7,
                              child:
                              _buildPrimaryButton(
                                text:
                                'Continue',
                                isLoading:
                                _isSubmitting,
                                isSuccess:
                                _registrationSuccess,
                                onPressed:
                                _isSubmitting ||
                                    _registrationSuccess
                                    ? null
                                    : _handleNext,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _animatedEntry(
                              index: 8,
                              child:
                              _buildSecurityNote(),
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

  // ===========================================================================
  // HEADER
  // ===========================================================================

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
                  color: AppColors.kBorder,
                ),
              ),
              child: const Text(
                'STEP 1 OF 4',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  fontWeight:
                  FontWeight.w700,
                  color: AppColors.kTextMuted,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Responsive progress indicator
        Row(
          children: List.generate(
            4,
                (index) {
              final active =
                  index == 0;

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
                      milliseconds: 400,
                    ),
                    height: 4,
                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius
                          .circular(20),
                      color: active
                          ? AppColors
                          .kPrimary
                          : AppColors
                          .kBorder,
                      boxShadow: active
                          ? [
                        BoxShadow(
                          color: AppColors
                              .kPrimary
                              .withOpacity(
                            0.20,
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
            color: AppColors.kTextDark,
          ),
        ),
      ),
    );
  }

  Widget _buildPilotBadge() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
        AppColors.kPrimary.withOpacity(
          0.085,
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flight_takeoff_rounded,
            color: AppColors.kPrimary,
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            'PILOT ONBOARDING',
            style: TextStyle(
              color: AppColors.kPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.65,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color:
            AppColors.kPrimary.withOpacity(
              0.09,
            ),
            borderRadius:
            BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.kPrimary,
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
                'Personal Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.kTextDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Complete all required information',
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10.5,
                  color:
                  AppColors.kTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================

  Widget _buildTextField({
    required TextEditingController
    controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType keyboardType =
        TextInputType.text,
    TextInputAction? textInputAction,
    VoidCallback? onTap,
    String? Function(String?)?
    validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled:
      !_isSubmitting || readOnly,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction:
      textInputAction,
      onTap: onTap,
      validator: validator,
      autovalidateMode:
      AutovalidateMode
          .onUserInteraction,
      style: const TextStyle(
        fontSize: 13.5,
        color: AppColors.kTextDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(
          color: AppColors.kHint,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),

        prefixIcon: prefixIcon != null
            ? Icon(
          prefixIcon,
          size: 18,
          color: AppColors.kHint,
        )
            : null,

        suffixIcon: suffixIcon,

        filled: true,
        fillColor: Colors.white,

        errorStyle: const TextStyle(
          fontSize: 10.5,
          color: AppColors.kDanger,
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
          borderSide: const BorderSide(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kPrimary,
            width: 1.4,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kDanger,
            width: 1,
          ),
        ),

        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kDanger,
            width: 1.3,
          ),
        ),

        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PHONE FIELD
  // ===========================================================================

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      enabled: !_isSubmitting,
      keyboardType:
      TextInputType.phone,
      textInputAction:
      TextInputAction.next,
      autovalidateMode:
      AutovalidateMode
          .onUserInteraction,

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Phone Number is required';
        }

        final numbers =
        value.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

        if (numbers.length < 7) {
          return 'Enter a valid phone number';
        }

        return null;
      },

      style: const TextStyle(
        fontSize: 13.5,
        color: AppColors.kTextDark,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: 'Phone Number',

        hintStyle: const TextStyle(
          color: AppColors.kHint,
          fontSize: 13,
        ),

        prefixIconConstraints:
        const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),

        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 10,
            right: 5,
          ),
          child: Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              InkWell(
                borderRadius:
                BorderRadius.circular(8),
                onTap: _countries.isEmpty
                    ? null
                    : _showCountryPicker,
                child: Padding(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 3,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry
                            ?.dialCode ??
                            '+970',
                        style:
                        const TextStyle(
                          color: AppColors
                              .kTextDark,
                          fontSize: 12.5,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        width: 2,
                      ),

                      const Icon(
                        Icons
                            .keyboard_arrow_down_rounded,
                        color:
                        AppColors.kHint,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 20,
                margin:
                const EdgeInsets
                    .symmetric(
                  horizontal: 6,
                ),
                color: AppColors.kBorder,
              ),
            ],
          ),
        ),

        filled: true,
        fillColor: Colors.white,

        errorStyle: const TextStyle(
          fontSize: 10.5,
          color: AppColors.kDanger,
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kBorder,
            width: 0.8,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kPrimary,
            width: 1.4,
          ),
        ),

        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kDanger,
          ),
        ),

        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.kDanger,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // NATIONALITY FIELD
  // ===========================================================================

  Widget _buildNationalityField() {
    return FormField<String>(
      validator: (_) {
        if (_selectedNationality ==
            null ||
            _selectedNationality!
                .trim()
                .isEmpty) {
          return 'Nationality is required';
        }

        return null;
      },
      builder: (state) {
        final selected =
            _selectedNationality != null &&
                _selectedNationality!
                    .isNotEmpty;

        return InkWell(
          borderRadius:
          BorderRadius.circular(15),
          onTap: _isSubmitting
              ? null
              : () {
            _showNationalityPicker(
              onSelected: (value) {
                setState(() {
                  _selectedNationality =
                      value;
                });

                state.didChange(
                  value,
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
              BorderRadius.circular(15),
              border: Border.all(
                color: state.hasError
                    ? AppColors.kDanger
                    : AppColors.kBorder,
                width:
                state.hasError
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
                      Icons.flag_outlined,
                      size: 18,
                      color: selected
                          ? AppColors.kPrimary
                          : AppColors.kHint,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        _selectedNationality ??
                            'Nationality',
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors
                              .kTextDark
                              : AppColors
                              .kHint,
                          fontSize: 13.5,
                          fontWeight:
                          selected
                              ? FontWeight
                              .w600
                              : FontWeight
                              .w400,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color: AppColors.kHint,
                      size: 20,
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
                        color:
                        AppColors.kDanger,
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

  // ===========================================================================
  // BUTTON
  // ===========================================================================

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isSuccess = false,
  }) {
    return Listener(
      onPointerDown: (_) {
        if (onPressed != null &&
            !isLoading &&
            !isSuccess) {
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
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 300,
          ),
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(28),
            gradient: isSuccess
                ? const LinearGradient(
              colors: [
                Color(0xFF39C98A),
                Color(0xFF168F67),
              ],
            )
                : const LinearGradient(
              begin:
              Alignment.centerLeft,
              end:
              Alignment.centerRight,
              colors: [
                Color(0xFF0D8AA5),
                AppColors.kPrimary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: (isSuccess
                    ? const Color(
                  0xFF168F67,
                )
                    : AppColors
                    .kPrimary)
                    .withOpacity(0.28),
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
              transitionBuilder:
                  (
                  child,
                  animation,
                  ) {
                return FadeTransition(
                  opacity: animation,
                  child:
                  ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: isSuccess
                  ? const Row(
                key: ValueKey(
                  'success',
                ),
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                    Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Account Created!',
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        14.5,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                  ),
                ],
              )
                  : isLoading
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

  // ===========================================================================
  // SECURITY NOTE
  // ===========================================================================

  Widget _buildSecurityNote() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: AppColors.kTextMuted,
          ),

          const SizedBox(width: 5),

          Flexible(
            child: Text(
              'Your information is securely protected',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color:
                AppColors.kTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
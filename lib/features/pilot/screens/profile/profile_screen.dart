import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tototl_app/features/pilot/screens/profile/pilot_edit_profile_screen.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../shared/account_settings_screen.dart';
import '../../../shared/settings_detail_screens.dart';

import '../../controllers/pilot_profile_controller.dart';
import '../../models/pilot_profile_model.dart';
import '../../services/pilot_profile_service.dart';

// ============================================================================
// TOTOTL PREMIUM COLORS
// ============================================================================

const Color _turquoise = Color(0xFF16C6C7);
const Color _turquoiseDark = Color(0xFF0D8AA5);

const Color _deepNavy = Color(0xFF071C2F);
const Color _navy = Color(0xFF0C3048);

const Color _softTurquoise = Color(0xFFE9FAFA);
const Color _softTurquoise2 = Color(0xFFF2FCFC);

const Color _surface = Color(0xFFFFFFFF);
const Color _surfaceSoft = Color(0xFFF8FAFC);

const Color _textPrimary = Color(0xFF102638);
const Color _textSecondary = Color(0xFF64748B);
const Color _textLight = Color(0xFF94A3B8);

const Color _border = Color(0xFFE7EDF2);

const Color _success = Color(0xFF12A875);
const Color _warning = Color(0xFFE79A13);
const Color _danger = Color(0xFFE45252);

// ============================================================================
// PROFILE SCREEN
// ============================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================================================
  // DATA
  // ==========================================================================

  PilotProfileViewData? _data;

  bool _readingLocal = true;

  bool _backgroundRefreshFinished = false;

  final ImagePicker _imagePicker = ImagePicker();

  bool _uploadingPhoto = false;

  // ==========================================================================
  // API / CONTROLLER
  // ==========================================================================

  late final ApiClient _apiClient;

  late final PilotProfileService _profileService;

  late final PilotProfileController _profileController;

  // ==========================================================================
  // ENTRY ANIMATION
  // ==========================================================================

  late final AnimationController _entryController;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1050,
      ),
    );

    _apiClient = ApiClient();

    _profileService = PilotProfileService(
      _apiClient,
    );

    _profileController = PilotProfileController(
      _profileService,
    );

    _loadLocalFirst();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _entryController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // LOCAL FIRST
  // ==========================================================================

  Future<void> _loadLocalFirst() async {
    final local =
    await _profileController.loadLocalProfile();

    if (!mounted) return;

    setState(() {
      _data = local;

      _readingLocal = false;
    });

    if (_data != null) {
      _entryController.forward(
        from: 0,
      );
    }

    unawaited(
      _refreshSilently(),
    );
  }

  // ==========================================================================
  // SILENT REFRESH
  // ==========================================================================

  Future<void> _refreshSilently() async {
    final fresh =
    await _profileController.refreshSilently();

    if (!mounted) return;

    setState(() {
      if (fresh != null) {
        _data = fresh;
      }

      _backgroundRefreshFinished = true;
    });

    if (fresh != null &&
        _entryController.value == 0) {
      _entryController.forward();
    }
  }

  // ==========================================================================
  // MANUAL REFRESH
  // ==========================================================================

  Future<void> _manualRefresh() async {
    HapticFeedback.selectionClick();

    final fresh =
    await _profileController.refreshSilently();

    if (!mounted) return;

    if (fresh != null) {
      setState(() {
        _data = fresh;
      });
    }
  }

  // ==========================================================================
  // EDIT PROFILE
  // ==========================================================================

  Future<void> _openEditProfile() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const PilotEditProfileScreen(),
      ),
    );

    if (!mounted) return;

    await _refreshSilently();
  }

  // ==========================================================================
  // CHANGE PROFILE PHOTO
  // ==========================================================================

  Future<void> _changeProfilePhoto() async {
    if (_uploadingPhoto) {
      return;
    }

    HapticFeedback.selectionClick();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Profile Photo',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Choose a new professional photo',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PhotoSourceButton(
                        icon: Icons.camera_alt_outlined,
                        title: 'Camera',
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                            ImageSource.camera,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PhotoSourceButton(
                        icon: Icons.photo_library_outlined,
                        title: 'Gallery',
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                            ImageSource.gallery,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final selected = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 1800,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _uploadingPhoto = true;
    });

    final uploaded = await _profileController.uploadProfilePhoto(
      filePath: selected.path,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _uploadingPhoto = false;

      if (uploaded != null && _data != null) {
        _data = _data!.copyWith(
          profilePhotoUrl: uploaded.url,
        );
      }
    });

    if (uploaded == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          content: Text(
            _profileController.errorMessage ??
                'Unable to upload profile photo.',
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _deepNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        content: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Profile photo updated.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SETTINGS
  // ==========================================================================

  void _openSettings() {
    HapticFeedback.selectionClick();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const AccountSettingsScreen(
          isCompany: false,
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
    if (_readingLocal) {
      return const _ProfileSkeleton();
    }

    if (_data == null) {
      if (!_backgroundRefreshFinished) {
        return const _ProfileSkeleton();
      }

      return _NoProfileData(
        onRetry: _manualRefresh,
      );
    }

    final data = _data!;

    final profile = data.profile;

    final hasBio =
        profile.bio.trim().isNotEmpty;

    final hasProfessionalData =
    _hasProfessionalData(
      profile,
    );

    final hasWorkRegions =
        profile.workRegions.isNotEmpty;

    return Scaffold(
      backgroundColor:
      AppColors.bg,

      body: RefreshIndicator(
        color:
        _turquoiseDark,

        backgroundColor:
        Colors.white,

        onRefresh:
        _manualRefresh,

        child: CustomScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(
            parent:
            BouncingScrollPhysics(),
          ),

          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,

                child: Padding(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    18,
                    10,
                    18,
                    30,
                  ),

                  child: Column(
                    children: [
                      // ======================================================
                      // TOP BAR
                      // ======================================================

                      _AnimatedSection(
                        animation:
                        _entryController,

                        begin:
                        0.00,

                        end:
                        0.26,

                        offsetY:
                        12,

                        child:
                        _ProfileTopBar(
                          onSettings:
                          _openSettings,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ======================================================
                      // PREMIUM HERO
                      // ======================================================

                      _AnimatedSection(
                        animation:
                        _entryController,

                        begin:
                        0.06,

                        end:
                        0.48,

                        offsetY:
                        25,

                        child:
                        _PremiumPilotHero(
                          data:
                          data,

                          onEditProfile:
                          _openEditProfile,

                          onEditPhoto:
                          _changeProfilePhoto,

                          uploadingPhoto:
                          _uploadingPhoto,
                        ),
                      ),

                      // ======================================================
                      // BIO
                      // ======================================================

                      if (hasBio) ...[
                        const SizedBox(
                          height: 18,
                        ),

                        _AnimatedSection(
                          animation:
                          _entryController,

                          begin:
                          0.28,

                          end:
                          0.66,

                          offsetY:
                          22,

                          child:
                          _PremiumSectionCard(
                            icon:
                            Icons
                                .format_quote_rounded,

                            title:
                            'Professional Summary',

                            subtitle:
                            'A concise introduction to the pilot',

                            child:
                            _AboutSection(
                              bio:
                              profile.bio,
                            ),
                          ),
                        ),
                      ],

                      // ======================================================
                      // PROFESSIONAL DETAILS
                      // ======================================================

                      if (hasProfessionalData) ...[
                        const SizedBox(
                          height: 15,
                        ),

                        _AnimatedSection(
                          animation:
                          _entryController,

                          begin:
                          0.40,

                          end:
                          0.80,

                          offsetY:
                          22,

                          child:
                          _ProfessionalDetailsCard(
                            profile:
                            profile,
                          ),
                        ),
                      ],

                      // ======================================================
                      // WORK AVAILABILITY
                      // ======================================================

                      if (hasWorkRegions) ...[
                        const SizedBox(
                          height: 15,
                        ),

                        _AnimatedSection(
                          animation:
                          _entryController,

                          begin:
                          0.54,

                          end:
                          1.00,

                          offsetY:
                          22,

                          child:
                          _WorkAvailabilityCard(
                            profile:
                            profile,
                          ),
                        ),
                      ],

                      // ======================================================
                      // EMPTY OPTIONAL PROFILE
                      // ======================================================

                      if (!hasBio &&
                          !hasProfessionalData &&
                          !hasWorkRegions) ...[
                        const SizedBox(
                          height: 16,
                        ),

                        _AnimatedSection(
                          animation:
                          _entryController,

                          begin:
                          0.35,

                          end:
                          0.85,

                          offsetY:
                          20,

                          child:
                          _CompleteProfileCard(
                            onEdit:
                            _openEditProfile,
                          ),
                        ),
                      ],
                    ],
                  ),
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

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.onSettings,
  });

  final VoidCallback onSettings;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.center,

      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Text(
                'Pilot Profile',

                style:
                TextStyle(
                  color:
                  _textPrimary,

                  fontSize:
                  23,

                  fontWeight:
                  FontWeight.w900,

                  letterSpacing:
                  -0.55,
                ),
              ),

              SizedBox(
                height: 3,
              ),

              Text(
                'Professional identity and availability',

                style:
                TextStyle(
                  color:
                  _textSecondary,

                  fontSize:
                  11.5,

                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Material(
          color:
          Colors.white,

          borderRadius:
          BorderRadius.circular(
            17,
          ),

          child: InkWell(
            onTap:
            onSettings,

            borderRadius:
            BorderRadius.circular(
              17,
            ),

            child: Container(
              width: 46,
              height: 46,

              decoration:
              BoxDecoration(
                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(
                  17,
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
                      0.035,
                    ),

                    blurRadius:
                    16,

                    offset:
                    const Offset(
                      0,
                      6,
                    ),
                  ),
                ],
              ),

              child:
              const Icon(
                Icons
                    .settings_outlined,

                size: 20,

                color:
                _textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PREMIUM PILOT HERO
// ============================================================================

class _PremiumPilotHero extends StatelessWidget {
  const _PremiumPilotHero({
    required this.data,
    required this.onEditProfile,
    required this.onEditPhoto,
    required this.uploadingPhoto,
  });

  final PilotProfileViewData data;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPhoto;
  final bool uploadingPhoto;

  static const String _coverAsset =
      'assets/images/pilot_background.png';

  @override
  Widget build(BuildContext context) {
    final account = data.account;
    final profile = data.profile;
    final name = account.displayName;
    final username = account.displayUsername;
    final location = profile.currentLocationLabel.trim();
    final hasLocation =
        location.isNotEmpty && location != 'Not specified';
    final verified = _isVerified(account.status);

    return Column(
      children: [
        // Keep the avatar INSIDE the Stack hit-test bounds.
        // Previously it was painted with bottom: -50, so the camera button
        // was visible but the overflowing area could not receive taps.
        SizedBox(
          height: 274,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _deepNavy.withOpacity(0.24),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _coverAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return const _CoverImageFallback();
                          },
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: const [0.00, 0.50, 1.00],
                              colors: [
                                const Color(0xFF031525)
                                    .withOpacity(0.88),
                                const Color(0xFF071C2F)
                                    .withOpacity(0.30),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.45, 1.00],
                              colors: [
                                Colors.transparent,
                                const Color(0xFF03111D)
                                    .withOpacity(0.72),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.fromLTRB(18, 17, 18, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const _PilotCoverLabel(),
                                  const Spacer(),
                                  _HeroStatusBadge(
                                    status: account.status,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                'AERIAL OPERATIONS',
                                style: TextStyle(
                                  color: Color(0xFF8EF2E2),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.75,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const SizedBox(
                                width: 220,
                                child: Text(
                                  'Precision beyond every horizon.',
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    height: 1.08,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 23),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 170,
                child: Center(
                  child: _PremiumAvatar(
                    name: name,
                    photoUrl: data.profilePhotoUrl,
                    uploading: uploadingPhoto,
                    onEdit: onEditPhoto,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 25,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.75,
                ),
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 7),
              const Icon(
                Icons.verified_rounded,
                size: 20,
                color: _turquoiseDark,
              ),
            ],
          ],
        ),
        if (username.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (hasLocation) ...[
          const SizedBox(height: 11),
          _ProfileLocationPill(
            location: location,
          ),
        ],
        const SizedBox(height: 15),
        _ProfileEditButton(
          onTap: onEditProfile,
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _ProfileStatTile(
                  value: '${profile.experienceYears}',
                  suffix: ' yrs',
                  label: 'Experience',
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              const _ProfileStatDivider(),
              Expanded(
                child: _ProfileStatTile(
                  value: '${profile.languages.length}',
                  label: 'Languages',
                  icon: Icons.translate_rounded,
                ),
              ),
              const _ProfileStatDivider(),
              Expanded(
                child: _ProfileStatTile(
                  value: '${profile.workRegions.length}',
                  label: 'Work regions',
                  icon: Icons.public_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverImageFallback extends StatelessWidget {
  const _CoverImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _deepNavy,
            _navy,
            _turquoiseDark,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment(0.68, -0.10),
        child: Icon(
          Icons.flight_takeoff_rounded,
          size: 72,
          color: Color(0x26FFFFFF),
        ),
      ),
    );
  }
}

class _PilotCoverLabel extends StatelessWidget {
  const _PilotCoverLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF031525).withOpacity(0.34),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.17)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radar_rounded,
            size: 13,
            color: Color(0xFF8EF2E2),
          ),
          SizedBox(width: 6),
          Text(
            'TOTOTL PILOT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.7,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLocationPill extends StatelessWidget {
  const _ProfileLocationPill({
    required this.location,
  });

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _softTurquoise2,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _turquoise.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 14,
            color: _turquoiseDark,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditButton extends StatelessWidget {
  const _ProfileEditButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _deepNavy.withOpacity(0.055),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: _turquoiseDark,
              ),
              SizedBox(width: 6),
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.value,
    required this.label,
    required this.icon,
    this.suffix = '',
  });

  final String value;
  final String suffix;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Column(
        children: [
          Icon(
            icon,
            size: 17,
            color: _turquoiseDark,
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                text: value,
                children: [
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: suffix,
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: _border,
    );
  }
}

// ============================================================================
// PREMIUM AVATAR
// ============================================================================

class _PremiumAvatar extends StatelessWidget {
  const _PremiumAvatar({
    required this.name,
    required this.photoUrl,
    required this.uploading,
    required this.onEdit,
  });

  final String name;
  final String photoUrl;
  final bool uploading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: _BreathingAvatarGlow(),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: uploading ? null : onEdit,
          child: Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _AvatarInitials(
                          name: name,
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }

                        return _AvatarInitials(
                          name: name,
                        );
                      },
                    )
                  else
                    _AvatarInitials(
                      name: name,
                    ),
                  if (uploading)
                    Container(
                      color: _deepNavy.withOpacity(0.58),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Material(
            color: uploading ? _textLight : _turquoiseDark,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              onTap: uploading ? null : onEdit,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 33,
                height: 33,
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 14.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3FFFF),
            Color(0xFFD7F7F7),
            Color(0xFFBCEAEC),
          ],
        ),
      ),
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: _deepNavy,
          fontSize: 27,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.7,
        ),
      ),
    );
  }
}

// ============================================================================
// BREATHING AVATAR GLOW
// ============================================================================

class _BreathingAvatarGlow
    extends StatefulWidget {
  const _BreathingAvatarGlow();

  @override
  State<_BreathingAvatarGlow>
  createState() =>
      _BreathingAvatarGlowState();
}

class _BreathingAvatarGlowState
    extends State<_BreathingAvatarGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController
  _controller;

  late final Animation<double>
  _scale;

  late final Animation<double>
  _opacity;

  @override
  void initState() {
    super.initState();

    _controller =
    AnimationController(
      vsync:
      this,

      duration:
      const Duration(
        milliseconds:
        1900,
      ),
    )..repeat(
      reverse: true,
    );

    _scale =
        Tween<double>(
          begin:
          0.92,

          end:
          1.17,
        ).animate(
          CurvedAnimation(
            parent:
            _controller,

            curve:
            Curves.easeInOut,
          ),
        );

    _opacity =
        Tween<double>(
          begin:
          0.08,

          end:
          0.24,
        ).animate(
          CurvedAnimation(
            parent:
            _controller,

            curve:
            Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnimatedBuilder(
      animation:
      _controller,

      builder:
          (
          context,
          child,
          ) {
        return Transform.scale(
          scale:
          _scale.value,

          child:
          Opacity(
            opacity:
            _opacity.value,

            child:
            Container(
              decoration:
              const BoxDecoration(
                shape:
                BoxShape.circle,

                color:
                _turquoise,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// HERO STATUS
// ============================================================================

class _HeroStatusBadge
    extends StatelessWidget {
  const _HeroStatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(
      BuildContext context,
      ) {
    final normalized =
    status
        .trim()
        .toLowerCase();

    late final String label;

    late final Color color;

    late final IconData icon;

    if (normalized ==
        'active' ||
        normalized ==
            'approved') {
      label =
      'Verified';

      color =
      const Color(
        0xFF7AF3D3,
      );

      icon =
          Icons
              .verified_rounded;
    } else if (normalized ==
        'pending') {
      label =
      'Pending';

      color =
      const Color(
        0xFFF8CE69,
      );

      icon =
          Icons
              .schedule_rounded;
    } else if (normalized ==
        'rejected') {
      label =
      'Rejected';

      color =
      const Color(
        0xFFFFA3A3,
      );

      icon =
          Icons
              .cancel_outlined;
    } else if (normalized ==
        'suspended') {
      label =
      'Suspended';

      color =
      const Color(
        0xFFFFA3A3,
      );

      icon =
          Icons
              .block_rounded;
    } else {
      label =
      'Pilot';

      color =
          Colors.white;

      icon =
          Icons
              .person_outline_rounded;
    }

    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal:
        9,

        vertical:
        6,
      ),

      decoration:
      BoxDecoration(
        color:
        color.withOpacity(
          0.10,
        ),

        borderRadius:
        BorderRadius.circular(
          50,
        ),

        border:
        Border.all(
          color:
          color.withOpacity(
            0.19,
          ),
        ),
      ),

      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Icon(
            icon,

            size:
            12,

            color:
            color,
          ),

          const SizedBox(
            width:
            5,
          ),

          Text(
            label,

            style:
            TextStyle(
              color:
              color,

              fontSize:
              9.5,

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
// HERO METRIC
// ============================================================================

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
    this.suffix,
  });

  final String value;

  final String label;

  final IconData icon;

  final String? suffix;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal:
        5,
      ),

      child:
      Column(
        children: [
          Container(
            width:
            34,

            height:
            34,

            decoration:
            const BoxDecoration(
              color:
              _softTurquoise,

              shape:
              BoxShape.circle,
            ),

            child:
            Icon(
              icon,

              size:
              15.5,

              color:
              _turquoiseDark,
            ),
          ),

          const SizedBox(
            height:
            8,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.center,

            crossAxisAlignment:
            CrossAxisAlignment.end,

            children: [
              Text(
                value,

                style:
                const TextStyle(
                  color:
                  _textPrimary,

                  fontSize:
                  17,

                  height:
                  1,

                  fontWeight:
                  FontWeight.w900,

                  letterSpacing:
                  -0.4,
                ),
              ),

              if (suffix !=
                  null) ...[
                const SizedBox(
                  width:
                  2,
                ),

                Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom:
                    1,
                  ),

                  child:
                  Text(
                    suffix!,

                    style:
                    const TextStyle(
                      color:
                      _textLight,

                      fontSize:
                      8.5,

                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(
            height:
            4,
          ),

          Text(
            label,

            textAlign:
            TextAlign.center,

            maxLines:
            1,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(
              color:
              _textSecondary,

              fontSize:
              9.5,

              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HERO DIVIDER
// ============================================================================

class _HeroMetricDivider
    extends StatelessWidget {
  const _HeroMetricDivider();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      1,

      height:
      50,

      color:
      _border,
    );
  }
}

// ============================================================================
// SECTION CARD
// ============================================================================

class _PremiumSectionCard
    extends StatelessWidget {
  const _PremiumSectionCard({
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
        17,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(
          25,
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
              0.035,
            ),

            blurRadius:
            22,

            offset:
            const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width:
                42,

                height:
                42,

                decoration:
                BoxDecoration(
                  color:
                  _softTurquoise,

                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),

                  border:
                  Border.all(
                    color:
                    _turquoise
                        .withOpacity(
                      0.10,
                    ),
                  ),
                ),

                child:
                Icon(
                  icon,

                  size:
                  18,

                  color:
                  _turquoiseDark,
                ),
              ),

              const SizedBox(
                width:
                11,
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
                      const TextStyle(
                        color:
                        _textPrimary,

                        fontSize:
                        15,

                        fontWeight:
                        FontWeight.w800,

                        letterSpacing:
                        -0.2,
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
                        _textLight,

                        fontSize:
                        10.2,

                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing !=
                  null)
                trailing!,
            ],
          ),

          const SizedBox(
            height:
            17,
          ),

          child,
        ],
      ),
    );
  }
}

// ============================================================================
// ABOUT
// ============================================================================

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.bio,
  });

  final String bio;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Stack(
      children: [
        Positioned(
          left:
          -3,

          top:
          -14,

          child:
          Text(
            '“',

            style:
            TextStyle(
              color:
              _turquoise
                  .withOpacity(
                0.14,
              ),

              fontSize:
              72,

              fontWeight:
              FontWeight.w900,

              height:
              1,
            ),
          ),
        ),

        Padding(
          padding:
          const EdgeInsets.only(
            left:
            4,

            top:
            2,
          ),

          child:
          Text(
            bio.trim(),

            style:
            const TextStyle(
              color:
              _textSecondary,

              fontSize:
              13,

              height:
              1.68,

              fontWeight:
              FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PROFESSIONAL DETAILS
// ============================================================================

class _ProfessionalDetailsCard
    extends StatelessWidget {
  const _ProfessionalDetailsCard({
    required this.profile,
  });

  final PilotProfileModel profile;

  @override
  Widget build(
      BuildContext context,
      ) {
    final items =
    <Widget>[];

    void addItem({
      required IconData icon,
      required String title,
      required String value,
    }) {
      final clean =
      value.trim();

      if (clean.isEmpty) {
        return;
      }

      if (items.isNotEmpty) {
        items.add(
          const SizedBox(
            height:
            10,
          ),
        );
      }

      items.add(
        _ProfessionalTile(
          icon:
          icon,

          title:
          title,

          value:
          clean,
        ),
      );
    }

    addItem(
      icon:
      Icons
          .flag_outlined,

      title:
      'Nationality',

      value:
      profile.nationality,
    );

    addItem(
      icon:
      Icons
          .business_outlined,

      title:
      'Previous Company',

      value:
      profile.previousCompany,
    );

    addItem(
      icon:
      Icons
          .link_rounded,

      title:
      'LinkedIn',

      value:
      profile.linkedinUrl,
    );

    return _PremiumSectionCard(
      icon:
      Icons
          .badge_outlined,

      title:
      'Professional Details',

      subtitle:
      'Key background information',

      child:
      Column(
        children:
        items,
      ),
    );
  }
}

// ============================================================================
// PROFESSIONAL TILE
// ============================================================================

class _ProfessionalTile
    extends StatelessWidget {
  const _ProfessionalTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;

  final String title;

  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets
          .fromLTRB(
        13,
        12,
        13,
        12,
      ),

      decoration:
      BoxDecoration(
        color:
        _surfaceSoft,

        borderRadius:
        BorderRadius.circular(
          17,
        ),

        border:
        Border.all(
          color:
          _border,
        ),
      ),

      child:
      Row(
        children: [
          Container(
            width:
            36,

            height:
            36,

            decoration:
            BoxDecoration(
              color:
              Colors.white,

              borderRadius:
              BorderRadius.circular(
                11,
              ),

              border:
              Border.all(
                color:
                _border,
              ),
            ),

            child:
            Icon(
              icon,

              size:
              16,

              color:
              _turquoiseDark,
            ),
          ),

          const SizedBox(
            width:
            11,
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
                  const TextStyle(
                    color:
                    _textLight,

                    fontSize:
                    10,

                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height:
                  3,
                ),

                Text(
                  value,

                  maxLines:
                  2,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(
                    color:
                    _textPrimary,

                    fontSize:
                    12.3,

                    height:
                    1.35,

                    fontWeight:
                    FontWeight.w700,
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
// WORK AVAILABILITY
// ============================================================================

class _WorkAvailabilityCard
    extends StatelessWidget {
  const _WorkAvailabilityCard({
    required this.profile,
  });

  final PilotProfileModel profile;

  @override
  Widget build(
      BuildContext context,
      ) {
    final regions =
        profile.workRegions;

    final visible =
    regions
        .take(
      5,
    )
        .toList();

    return _PremiumSectionCard(
      icon:
      Icons
          .travel_explore_rounded,

      title:
      'Work Availability',

      subtitle:
      'Regions where this pilot is available',

      trailing:
      Container(
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
          color:
          _softTurquoise,

          borderRadius:
          BorderRadius.circular(
            30,
          ),
        ),

        child:
        Text(
          '${regions.length} region${regions.length == 1 ? '' : 's'}',

          style:
          const TextStyle(
            color:
            _turquoiseDark,

            fontSize:
            9.5,

            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),

      child:
      Wrap(
        spacing:
        8,

        runSpacing:
        8,

        children: [
          ...visible.map(
                (
                region,
                ) {
              return _RegionChip(
                label:
                region.displayLabel,
              );
            },
          ),

          if (regions.length >
              visible.length)
            _RegionChip(
              label:
              '+${regions.length - visible.length} more',

              muted:
              true,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// REGION CHIP
// ============================================================================

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    this.muted = false,
  });

  final String label;

  final bool muted;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      constraints:
      const BoxConstraints(
        maxWidth:
        255,
      ),

      padding:
      const EdgeInsets
          .symmetric(
        horizontal:
        11,

        vertical:
        8,
      ),

      decoration:
      BoxDecoration(
        color:
        muted
            ? _surfaceSoft
            : _softTurquoise2,

        borderRadius:
        BorderRadius.circular(
          30,
        ),

        border:
        Border.all(
          color:
          muted
              ? _border
              : _turquoise
              .withOpacity(
            0.16,
          ),
        ),
      ),

      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          if (!muted) ...[
            const Icon(
              Icons
                  .location_on_outlined,

              size:
              13,

              color:
              _turquoiseDark,
            ),

            const SizedBox(
              width:
              4,
            ),
          ],

          Flexible(
            child:
            Text(
              label,

              maxLines:
              1,

              overflow:
              TextOverflow.ellipsis,

              style:
              TextStyle(
                color:
                muted
                    ? _textSecondary
                    : _navy,

                fontSize:
                10.5,

                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPLETE PROFILE
// ============================================================================

class _CompleteProfileCard
    extends StatelessWidget {
  const _CompleteProfileCard({
    required this.onEdit,
  });

  final VoidCallback onEdit;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets
          .fromLTRB(
        21,
        25,
        21,
        22,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(
          26,
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
              0.035,
            ),

            blurRadius:
            20,

            offset:
            const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child:
      Column(
        children: [
          Container(
            width:
            62,

            height:
            62,

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
                  _softTurquoise,

                  _turquoise
                      .withOpacity(
                    0.20,
                  ),
                ],
              ),
            ),

            child:
            const Icon(
              Icons
                  .auto_awesome_rounded,

              color:
              _turquoiseDark,

              size:
              27,
            ),
          ),

          const SizedBox(
            height:
            14,
          ),

          const Text(
            'Complete your professional profile',

            textAlign:
            TextAlign.center,

            style:
            TextStyle(
              color:
              _textPrimary,

              fontSize:
              15.5,

              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
            6,
          ),

          const Text(
            'Add a professional summary, background details and work regions to strengthen your pilot profile.',

            textAlign:
            TextAlign.center,

            style:
            TextStyle(
              color:
              _textSecondary,

              fontSize:
              11.5,

              height:
              1.55,

              fontWeight:
              FontWeight.w500,
            ),
          ),

          const SizedBox(
            height:
            17,
          ),

          Material(
            color:
            _turquoiseDark,

            borderRadius:
            BorderRadius.circular(
              16,
            ),

            child:
            InkWell(
              onTap:
              onEdit,

              borderRadius:
              BorderRadius.circular(
                16,
              ),

              child:
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  horizontal:
                  17,

                  vertical:
                  11,
                ),

                child:
                Row(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [
                    Icon(
                      Icons
                          .edit_outlined,

                      size:
                      15,

                      color:
                      Colors.white,
                    ),

                    SizedBox(
                      width:
                      7,
                    ),

                    Text(
                      'Complete Profile',

                      style:
                      TextStyle(
                        color:
                        Colors.white,

                        fontSize:
                        11.5,

                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PHOTO SOURCE BUTTON
// ============================================================================

class _PhotoSourceButton extends StatelessWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: const BoxDecoration(
                  color: _softTurquoise,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _turquoiseDark,
                  size: 19,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ENTRY ANIMATION
// ============================================================================

class _AnimatedSection
    extends StatelessWidget {
  const _AnimatedSection({
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
    this.offsetY = 20,
  });

  final Animation<double> animation;

  final double begin;

  final double end;

  final double offsetY;

  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    final curved =
    CurvedAnimation(
      parent:
      animation,

      curve:
      Interval(
        begin,
        end,
        curve:
        Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity:
      curved,

      child:
      SlideTransition(
        position:
        Tween<Offset>(
          begin:
          Offset(
            0,
            offsetY /
                300,
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
  }
}

// ============================================================================
// SKELETON
// ============================================================================

class _ProfileSkeleton
    extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.bg,

      body:
      SafeArea(
        child:
        SingleChildScrollView(
          physics:
          const NeverScrollableScrollPhysics(),

          padding:
          const EdgeInsets
              .fromLTRB(
            18,
            12,
            18,
            28,
          ),

          child:
          Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        _SkeletonLine(
                          width:
                          130,
                        ),

                        SizedBox(
                          height:
                          8,
                        ),

                        _SkeletonLine(
                          width:
                          210,

                          height:
                          8,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width:
                    46,

                    height:
                    46,

                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius.circular(
                        17,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                18,
              ),

              Container(
                height:
                330,

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
                    _border,
                  ),
                ),

                child:
                Column(
                  children: [
                    Expanded(
                      child:
                      Container(
                        decoration:
                        const BoxDecoration(
                          borderRadius:
                          BorderRadius.vertical(
                            top:
                            Radius.circular(
                              29,
                            ),
                          ),

                          gradient:
                          LinearGradient(
                            begin:
                            Alignment.topLeft,

                            end:
                            Alignment.bottomRight,

                            colors: [
                              _deepNavy,
                              _navy,
                              _turquoiseDark,
                            ],
                          ),
                        ),

                        child:
                        Padding(
                          padding:
                          const EdgeInsets.all(
                            20,
                          ),

                          child:
                          Align(
                            alignment:
                            Alignment.centerLeft,

                            child:
                            Container(
                              width:
                              88,

                              height:
                              88,

                              decoration:
                              BoxDecoration(
                                color:
                                Colors.white
                                    .withOpacity(
                                  0.12,
                                ),

                                shape:
                                BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                      105,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                18,
              ),

              const _SkeletonCard(
                height:
                130,
              ),

              const SizedBox(
                height:
                15,
              ),

              const _SkeletonCard(
                height:
                165,
              ),

              const SizedBox(
                height:
                15,
              ),

              const _SkeletonCard(
                height:
                135,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SKELETON CARD
// ============================================================================

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.height,
  });

  final double height;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,

      height:
      height,

      padding:
      const EdgeInsets.all(
        18,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(
          25,
        ),

        border:
        Border.all(
          color:
          _border,
        ),
      ),

      child:
      const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          _SkeletonLine(
            width:
            150,
          ),

          SizedBox(
            height:
            16,
          ),

          _SkeletonLine(),

          SizedBox(
            height:
            9,
          ),

          _SkeletonLine(
            width:
            215,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SKELETON LINE
// ============================================================================

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    this.width = double.infinity,
    this.height = 10,
  });

  final double width;

  final double height;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      width,

      height:
      height,

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
// NO PROFILE DATA
// ============================================================================

class _NoProfileData extends StatelessWidget {
  const _NoProfileData({
    required this.onRetry,
  });

  final Future<void> Function() onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.bg,

      body:
      SafeArea(
        child:
        Center(
          child:
          Padding(
            padding:
            const EdgeInsets.all(
              28,
            ),

            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Container(
                  width:
                  82,

                  height:
                  82,

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
                        _softTurquoise,

                        _turquoise
                            .withOpacity(
                          0.22,
                        ),
                      ],
                    ),
                  ),

                  child:
                  const Icon(
                    Icons
                        .person_search_outlined,

                    size:
                    34,

                    color:
                    _turquoiseDark,
                  ),
                ),

                const SizedBox(
                  height:
                  18,
                ),

                const Text(
                  'Profile unavailable',

                  textAlign:
                  TextAlign.center,

                  style:
                  TextStyle(
                    color:
                    _textPrimary,

                    fontSize:
                    18,

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height:
                  7,
                ),

                const Text(
                  'We could not load your pilot profile. Check your connection and try again.',

                  textAlign:
                  TextAlign.center,

                  style:
                  TextStyle(
                    color:
                    _textSecondary,

                    fontSize:
                    12,

                    height:
                    1.55,

                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height:
                  19,
                ),

                Material(
                  color:
                  _turquoiseDark,

                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),

                  child:
                  InkWell(
                    onTap: () {
                      onRetry();
                    },

                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),

                    child:
                    const Padding(
                      padding:
                      EdgeInsets.symmetric(
                        horizontal:
                        18,

                        vertical:
                        11,
                      ),

                      child:
                      Row(
                        mainAxisSize:
                        MainAxisSize.min,

                        children: [
                          Icon(
                            Icons
                                .refresh_rounded,

                            size:
                            16,

                            color:
                            Colors.white,
                          ),

                          SizedBox(
                            width:
                            7,
                          ),

                          Text(
                            'Try Again',

                            style:
                            TextStyle(
                              color:
                              Colors.white,

                              fontSize:
                              11.5,

                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ],
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

bool _hasProfessionalData(
    PilotProfileModel profile,
    ) {
  return profile.nationality
      .trim()
      .isNotEmpty ||
      profile.previousCompany
          .trim()
          .isNotEmpty ||
      profile.linkedinUrl
          .trim()
          .isNotEmpty;
}

bool _isVerified(
    String status,
    ) {
  final normalized =
  status
      .trim()
      .toLowerCase();

  return normalized ==
      'approved' ||
      normalized ==
          'active';
}

String _initials(
    String name,
    ) {
  final words =
  name
      .trim()
      .split(
    RegExp(
      r'\s+',
    ),
  )
      .where(
        (
        item,
        ) =>
    item.isNotEmpty,
  )
      .toList();

  if (words.isEmpty) {
    return 'P';
  }

  if (words.length == 1) {
    final value =
        words.first;

    return value
        .substring(
      0,
      value.length >= 2
          ? 2
          : 1,
    )
        .toUpperCase();
  }

  return '${words.first[0]}${words.last[0]}'
      .toUpperCase();
}

String _capitalize(
    String value,
    ) {
  final text =
  value.trim();

  if (text.isEmpty) {
    return text;
  }

  return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
}

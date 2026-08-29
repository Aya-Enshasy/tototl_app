import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../shared/screens/profile/account_settings_screen.dart';

import '../../controllers/pilot_profile_controller.dart';
import '../../models/pilot_profile_model.dart';
import '../../services/pilot_profile_service.dart';


import '../drones/profile_drones_section.dart';
import 'pilot_edit_profile_screen.dart';

// ============================================================================
// COLORS
// ============================================================================

const Color _page = Color(0xFFF7F9FB);
const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF52657D);
const Color _muted2 = Color(0xFF8CA0B8);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE7ECF1);
const Color _danger = Color(0xFFE45252);

// ============================================================================
// PROFILE SCREEN
// ============================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PilotProfileViewData? _data;

  bool _loadingLocal = true;
  bool _backgroundRefreshFinished = false;
  bool _uploadingPhoto = false;

  late final ApiClient _apiClient;
  late final PilotProfileService _profileService;
  late final PilotProfileController _profileController;

  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

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
    _profileService = PilotProfileService(_apiClient);
    _profileController = PilotProfileController(_profileService);

    _loadLocalFirst();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // DATA
  // ==========================================================================

  Future<void> _loadLocalFirst() async {
    final local = await _profileController.loadLocalProfile();

    if (!mounted) return;

    setState(() {
      _data = local;
      _loadingLocal = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });

    unawaited(_refreshSilently());
  }

  Future<void> _refreshSilently() async {
    final fresh = await _profileController.refreshSilently();

    if (!mounted) return;

    setState(() {
      if (fresh != null) {
        _data = fresh;
      }
      _backgroundRefreshFinished = true;
    });
  }

  Future<void> _manualRefresh() async {
    HapticFeedback.selectionClick();

    final fresh = await _profileController.refreshSilently();

    if (!mounted) return;

    if (fresh != null) {
      setState(() {
        _data = fresh;
      });
    }
  }

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  Future<void> _openEditProfile() async {
    HapticFeedback.selectionClick();

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PilotEditProfileScreen(),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await _refreshSilently();
    }
  }

  Future<void> _openSettings() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccountSettingsScreen(
          isCompany: false,
        ),
      ),
    );
  }

  Future<void> _goBack() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).maybePop();
  }

  // ==========================================================================
  // PROFILE PHOTO
  // ==========================================================================

  Future<void> _changeProfilePhoto() async {
    if (_uploadingPhoto) return;

    HapticFeedback.selectionClick();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
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
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Choose a new professional photo',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
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

    if (source == null) return;

    final selected = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 1800,
    );

    if (selected == null || !mounted) return;

    setState(() {
      _uploadingPhoto = true;
    });

    final uploaded = await _profileController.uploadProfilePhoto(
      filePath: selected.path,
    );

    if (!mounted) return;

    setState(() {
      _uploadingPhoto = false;

      if (uploaded != null && _data != null) {
        _data = _data!.copyWith(
          profilePhotoUrl: uploaded.url,
        );
      }
    });

    if (uploaded == null) {
      _showSnack(
        _profileController.errorMessage ??
            'Unable to update profile photo.',
        isError: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _showSnack('Profile photo updated.');
  }

  // ==========================================================================
  // DRONE PLACEHOLDER
  // ==========================================================================

  void _showDroneMessage() {
    HapticFeedback.selectionClick();

    _showSnack(
      'Drone data is not linked to the profile response yet.',
    );
  }

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _danger : _ink,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Text(message),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    if (_loadingLocal) {
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
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ==================================================================
          // FULL-SCREEN BACKGROUND
          //
          // Your new 941x1672 image is already almost the same aspect ratio
          // as the reference design, so BoxFit.cover keeps the composition
          // stable on most phones.
          // ==================================================================

          Positioned.fill(
            child: RepaintBoundary(
              child: Image.asset(
                'assets/images/pilot_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) {
                  return const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFDDEEF7),
                          Color(0xFFEAF5F7),
                          Colors.white,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Extra white fade so the lower section stays clean on every device.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [
                      0.00,
                      0.34,
                      0.56,
                      0.78,
                      1.00,
                    ],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withOpacity(0.20),
                      Colors.white.withOpacity(0.84),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),

          RefreshIndicator(
            color: _teal,
            backgroundColor: Colors.white,
            onRefresh: _manualRefresh,
            edgeOffset: media.padding.top,
            child: SingleChildScrollView(
              key: const PageStorageKey<String>(
                'pilot-profile-full-background-v1',
              ),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final safeTop = media.padding.top;

                  final side = width < 360 ? 16.0 : 24.0;

                  final heroHeight = (
                      width * 0.62 + safeTop
                  ).clamp(
                    335.0,
                    410.0,
                  ).toDouble();

                  return Column(
                    children: [
                      SizedBox(
                        height: heroHeight,
                        child: _HeroContent(
                          data: data,
                          uploadingPhoto: _uploadingPhoto,
                          side: side,
                          safeTop: safeTop,
                          onBack: _goBack,
                          onSettings: _openSettings,
                          onPhoto: _changeProfilePhoto,
                        ),
                      ),

                      Transform.translate(
                        offset: const Offset(
                          0,
                          -18,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            side,
                            0,
                            side,
                            media.padding.bottom + 28,
                          ),
                          child: Column(
                            children: [
                              _ProfileDetailsCard(
                                data: data,
                                onEdit: _openEditProfile,
                              ),

                              const SizedBox(height: 14),

                              _StatsRow(
                                profile: data.profile,
                              ),

                              const SizedBox(height: 14),

                              const ProfileDronesSection(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HERO CONTENT
// ============================================================================

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.data,
    required this.uploadingPhoto,
    required this.side,
    required this.safeTop,
    required this.onBack,
    required this.onSettings,
    required this.onPhoto,
  });

  final PilotProfileViewData data;
  final bool uploadingPhoto;
  final double side;
  final double safeTop;

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 360;

        final avatarSize = (
            width * 0.21
        ).clamp(
          78.0,
          102.0,
        ).toDouble();

        final actionSize = compact ? 44.0 : 48.0;
        final nameSize = compact ? 23.0 : width < 410 ? 27.0 : 30.0;

        final name = data.account.displayName.trim().isEmpty
            ? 'Pilot'
            : data.account.displayName.trim();

        final status = _statusData(
          data.account.status,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: safeTop + 14,
              left: side,
              right: side,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeroAction(
                    size: actionSize,
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack,
                  ),
                  _HeroAction(
                    size: actionSize,
                    icon: Icons.settings_outlined,
                    onTap: onSettings,
                  ),
                ],
              ),
            ),

            Positioned(
              left: side + 8,
              right: side + 8,
              bottom: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(
                    size: avatarSize,
                    name: name,
                    photoUrl: data.profilePhotoUrl,
                    uploading: uploadingPhoto,
                    onEdit: onPhoto,
                  ),

                  SizedBox(
                    width: compact ? 14 : 18,
                  ),

                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink,
                            fontSize: nameSize,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.75,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _StatusPill(
                          label: status.label,
                          icon: status.icon,
                          color: status.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// TOP ROUND BUTTON
// ============================================================================

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.size,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.10),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: _ink,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AVATAR
// ============================================================================

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    required this.name,
    required this.photoUrl,
    required this.uploading,
    required this.onEdit,
  });

  final double size;
  final String name;
  final String photoUrl;
  final bool uploading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    final cameraSize = (
        size * 0.34
    ).clamp(
      29.0,
      36.0,
    ).toDouble();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: uploading ? null : onEdit,
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ink.withOpacity(0.20),
                  blurRadius: 20,
                  offset: const Offset(
                    0,
                    8,
                  ),
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
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) {
                        return _AvatarInitials(
                          name: name,
                        );
                      },
                      loadingBuilder: (
                          context,
                          child,
                          progress,
                          ) {
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
                      color: _ink.withOpacity(0.50),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: -2,
          bottom: 2,
          child: Material(
            color: uploading ? _muted2 : _teal,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              onTap: uploading ? null : onEdit,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: cameraSize,
                height: cameraSize,
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 15,
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
            Color(0xFFF7FFFF),
            Color(0xFFDFF6F7),
            Color(0xFFBFE7E9),
          ],
        ),
      ),
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: _ink,
          fontSize: 25,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ============================================================================
// STATUS
// ============================================================================

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 190,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
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
// PROFILE DETAILS CARD
// ============================================================================

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.data,
    required this.onEdit,
  });

  final PilotProfileViewData data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final account = data.account;
    final profile = data.profile;

    final localRegion = profile.currentLocationLabel.trim();

    final rows = <_DetailItem>[
      _DetailItem(
        icon: Icons.calendar_month_outlined,
        label: 'DOB',
        value: _formatDate(
          profile.dateOfBirth,
        ),
      ),
      _DetailItem(
        icon: Icons.flag_outlined,
        label: 'Nationality',
        value: profile.nationality,
      ),
      _DetailItem(
        icon: Icons.language_rounded,
        label: 'Languages',
        value: _languagesLabel(
          profile.languages,
        ),
      ),
      _DetailItem(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: account.phone,
      ),
      _DetailItem(
        icon: Icons.location_on_outlined,
        label: 'Local Region',
        value: localRegion == 'Not specified'
            ? ''
            : localRegion,
      ),
      _DetailItem(
        icon: Icons.work_outline_rounded,
        label: 'Willing to Work',
        value: _workRegionsLabel(
          profile.workRegions,
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.055),
            blurRadius: 24,
            offset: const Offset(
              0,
              9,
            ),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          rows.length,
              (index) {
            return Column(
              children: [
                _DetailRow(
                  item: rows[index],
                  onTap: onEdit,
                ),

                if (index != rows.length - 1)
                  const Divider(
                    height: 1,
                    indent: 22,
                    endIndent: 22,
                    color: _border,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailItem {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.item,
    required this.onTap,
  });

  final _DetailItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clean = item.value.trim();
    final hasValue = clean.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            18,
            15,
            16,
            15,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 31,
                child: Icon(
                  item.icon,
                  color: _teal,
                  size: 22,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                flex: 4,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                flex: 5,
                child: Text(
                  hasValue
                      ? clean
                      : 'Not specified',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: hasValue
                        ? _ink
                        : _muted2,
                    fontSize: 13,
                    fontWeight: hasValue
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right_rounded,
                color: _muted2,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STATS
// ============================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.profile,
  });

  final PilotProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final experience = profile.experienceYears <= 0
        ? '<1'
        : '${profile.experienceYears}+';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final gap = compact ? 7.0 : 10.0;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon:
                Icons.workspace_premium_rounded,
                value: experience,
                label: 'Years Exp',
                compact: compact,
              ),
            ),

            SizedBox(width: gap),

            Expanded(
              child: _StatCard(
                icon: Icons.flight_takeoff_rounded,
                value: '—',
                label: 'Missions',
                compact: compact,
              ),
            ),

            SizedBox(width: gap),

            Expanded(
              child: _StatCard(
                icon: Icons.track_changes_rounded,
                value: '—',
                label: 'Success Rate',
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    // The previous version overflowed because 132px height + vertical padding
    // left only ~104px for content. This version uses smaller spacing and
    // enough internal room, so it does not overflow on short/narrow phones.
    final height = compact ? 116.0 : 124.0;
    final iconBox = compact ? 34.0 : 38.0;
    final valueSize = compact ? 21.0 : 24.0;
    final labelSize = compact ? 9.0 : 10.0;

    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(
        compact ? 5 : 7,
        10,
        compact ? 5 : 7,
        9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: const BoxDecoration(
              color: _tealSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _teal,
              size: compact ? 18 : 20,
            ),
          ),

          SizedBox(
            height: compact ? 5 : 7,
          ),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: _ink,
                fontSize: valueSize,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: _muted,
                fontSize: labelSize,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(
            height: compact ? 5 : 7,
          ),

          Container(
            width: compact ? 24 : 28,
            height: 2,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MY DRONES
// ============================================================================

class _MyDronesSection extends StatelessWidget {
  const _MyDronesSection({
    required this.onTap,
    required this.onAdd,
  });

  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My Drones',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  foregroundColor: _tealDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 20,
                ),
                label: const Text(
                  'Add Drone',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 106,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: AspectRatio(
                          aspectRatio: 1.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _tealSoft,
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.flight_takeoff_rounded,
                                color: _tealDark,
                                size: 46,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          10,
                          12,
                          6,
                          12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Drone profile',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              'Not linked yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _tealDark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _tealSoft,
                                borderRadius: BorderRadius.circular(
                                  30,
                                ),
                              ),
                              child: const Text(
                                'Connect API',
                                style: TextStyle(
                                  color: _tealDark,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(
                        right: 9,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: _muted2,
                        size: 22,
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
// PHOTO SOURCE
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
      color: const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _tealSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _tealDark,
                  size: 19,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: const TextStyle(
                  color: _ink,
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
// SKELETON
// ============================================================================

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;

    final heroHeight = (
        width * 0.62 + media.padding.top
    ).clamp(
      335.0,
      410.0,
    ).toDouble();

    return Scaffold(
      backgroundColor: _page,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/pilot_profile_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) {
                return const ColoredBox(
                  color: Color(0xFFEAF4F7),
                );
              },
            ),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [
                    0.0,
                    0.50,
                    0.82,
                    1.0,
                  ],
                  colors: [
                    Colors.transparent,
                    Colors.white24,
                    Colors.white,
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(
                  height: heroHeight,
                ),

                Transform.translate(
                  offset: const Offset(
                    0,
                    -18,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 350,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.96,
                            ),
                            borderRadius: BorderRadius.circular(
                              24,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Row(
                          children: [
                            Expanded(
                              child: _SkeletonStat(),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _SkeletonStat(),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _SkeletonStat(),
                            ),
                          ],
                        ),
                      ],
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

class _SkeletonStat extends StatelessWidget {
  const _SkeletonStat();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

// ============================================================================
// NO DATA
// ============================================================================

class _NoProfileData extends StatelessWidget {
  const _NoProfileData({
    required this.onRetry,
  });

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: _tealSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: _tealDark,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Profile unavailable',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'We could not load your pilot profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                FilledButton.icon(
                  onPressed: () {
                    onRetry();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _tealDark,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Try Again',
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
// STATUS HELPERS
// ============================================================================

class _StatusData {
  const _StatusData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

_StatusData _statusData(
    String status,
    ) {
  final value = status.trim().toLowerCase();

  switch (value) {
    case 'active':
    case 'approved':
    case 'verified':
      return const _StatusData(
        label: 'Verified Pilot',
        icon: Icons.verified_rounded,
        color: _tealDark,
      );

    case 'pending':
      return const _StatusData(
        label: 'Pending Pilot',
        icon: Icons.schedule_rounded,
        color: Color(0xFFB67A00),
      );

    case 'rejected':
      return const _StatusData(
        label: 'Rejected Pilot',
        icon: Icons.cancel_outlined,
        color: _danger,
      );

    case 'suspended':
      return const _StatusData(
        label: 'Suspended Pilot',
        icon: Icons.block_rounded,
        color: _danger,
      );

    default:
      return const _StatusData(
        label: 'Pilot',
        icon: Icons.flight_takeoff_rounded,
        color: _tealDark,
      );
  }
}

// ============================================================================
// TEXT HELPERS
// ============================================================================

String _formatDate(
    DateTime? date,
    ) {
  if (date == null) return '';

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _languagesLabel(
    List<String> languages,
    ) {
  final values = languages
      .map(
        (item) => item.trim(),
  )
      .where(
        (item) => item.isNotEmpty,
  )
      .toList();

  if (values.isEmpty) return '';

  if (values.length <= 2) {
    return values.join(', ');
  }

  return '${values.take(2).join(', ')} +${values.length - 2}';
}

String _workRegionsLabel(
    List<PilotWorkRegionModel> regions,
    ) {
  final values = regions
      .map(
        (item) => item.displayLabel.trim(),
  )
      .where(
        (item) => item.isNotEmpty,
  )
      .toList();

  if (values.isEmpty) return '';

  if (values.length == 1) {
    return values.first;
  }

  if (values.length == 2) {
    return values.join(' · ');
  }

  return '${values.take(2).join(' · ')} +${values.length - 2}';
}

String _initials(
    String name,
    ) {
  final words = name
      .trim()
      .split(
    RegExp(r'\s+'),
  )
      .where(
        (word) => word.isNotEmpty,
  )
      .toList();

  if (words.isEmpty) {
    return 'P';
  }

  if (words.length == 1) {
    final word = words.first;

    return word
        .substring(
      0,
      word.length >= 2 ? 2 : 1,
    )
        .toUpperCase();
  }

  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
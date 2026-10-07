import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/localization/app_language.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../shared/screens/profile/account_settings_screen.dart';

import '../../controllers/pilot_profile_controller.dart';
import '../../models/pilot_profile_model.dart';
import '../../services/pilot_profile_service.dart';


import '../drones/profile_drones_section.dart';
import '../licenses/profile_licenses_section.dart';
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLanguage.text('Change Profile Photo'),
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(AppLanguage.text('Choose a new professional photo'),
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
                        title: AppLanguage.text('Camera'),
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
                        title: AppLanguage.text('Gallery'),
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
      backgroundColor: _page,
      body: RefreshIndicator(
        color: _teal,
        backgroundColor: Colors.white,
        onRefresh: _manualRefresh,
        edgeOffset: media.padding.top,
        child: SingleChildScrollView(
          key: const PageStorageKey<String>(
            'pilot-profile-premium-v3',
          ),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final safeTop = media.padding.top;
              final side = width < 360 ? 15.0 : 20.0;

              final heroShellHeight = (
                width * 0.55 + safeTop + 96
              ).clamp(
                344.0,
                392.0,
              ).toDouble();

              return Column(
                children: [
                  SizedBox(
                    height: heroShellHeight,
                    child: _PremiumHeroShell(
                      data: data,
                      uploadingPhoto: _uploadingPhoto,
                      side: side,
                      safeTop: safeTop,
                      onBack: _goBack,
                      onSettings: _openSettings,
                      onPhoto: _changeProfilePhoto,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      12,
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

                        const ProfileLicensesSection(),

                        const SizedBox(height: 14),

                        const ProfileDronesSection(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}



// ============================================================================
// HERO CONTENT
// ============================================================================

class _PremiumHeroShell extends StatelessWidget {
  const _PremiumHeroShell({
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
        final backgroundHeight = constraints.maxHeight - 74;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: backgroundHeight,
              child: const _PremiumProfileBackdrop(),
            ),

            Positioned(
              top: safeTop + 10,
              left: side,
              right: side,
              child: Row(
                children: [
                  _HeroAction(
                    size: 44,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack,
                  ),
                  const Spacer(),
                  _HeroAction(
                    size: 44,
                    icon: Icons.settings_outlined,
                    onTap: onSettings,
                  ),
                ],
              ),
            ),

            Positioned(
              top: safeTop + 72,
              left: side + 4,
              right: side + 4,
              child: const _HeroEyebrow(),
            ),

            Positioned(
              left: side,
              right: side,
              bottom: 0,
              child: _PilotIdentityCard(
                data: data,
                uploadingPhoto: uploadingPhoto,
                onPhoto: onPhoto,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PremiumProfileBackdrop extends StatelessWidget {
  const _PremiumProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _PremiumHeroClipper(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF041522),
                  Color(0xFF07394A),
                  Color(0xFF0A7F89),
                ],
                stops: [0.0, .58, 1.0],
              ),
            ),
          ),

          Positioned(
            top: -90,
            right: -55,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF69F0E4).withOpacity(.26),
                    const Color(0xFF25CFC7).withOpacity(.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, .52, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            left: -120,
            bottom: -118,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1A9FB0).withOpacity(.24),
                    const Color(0xFF1A9FB0).withOpacity(.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, .58, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            right: 36,
            top: 112,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(.06),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PremiumHeroPainter(),
              ),
            ),
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x08000000),
                  Color(0x35020B12),
                ],
                stops: [0.0, .58, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHeroClipper extends CustomClipper<Path> {
  const _PremiumHeroClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 34)
      ..quadraticBezierTo(
        size.width * .22,
        size.height + 10,
        size.width * .50,
        size.height - 16,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height - 46,
        size.width,
        size.height - 20,
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _PremiumHeroClipper oldClipper) => false;
}

class _PremiumHeroPainter extends CustomPainter {
  const _PremiumHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = Colors.white.withOpacity(.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final accentPaint = Paint()
      ..color = const Color(0xFF7BE7DE).withOpacity(.35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * .10, size.height * .60)
      ..cubicTo(
        size.width * .25,
        size.height * .44,
        size.width * .40,
        size.height * .58,
        size.width * .53,
        size.height * .44,
      )
      ..cubicTo(
        size.width * .66,
        size.height * .30,
        size.width * .78,
        size.height * .39,
        size.width * .90,
        size.height * .25,
      );

    canvas.drawPath(path, routePaint);

    for (final point in <Offset>[
      Offset(size.width * .10, size.height * .60),
      Offset(size.width * .53, size.height * .44),
      Offset(size.width * .90, size.height * .25),
    ]) {
      canvas.drawCircle(point, 3.2, accentPaint);
      canvas.drawCircle(
        point,
        8.2,
        Paint()
          ..color = const Color(0xFF7BE7DE).withOpacity(.07)
          ..style = PaintingStyle.fill,
      );
    }

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(.025)
      ..strokeWidth = 1;

    for (double y = 26; y < size.height; y += 34) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumHeroPainter oldDelegate) => false;
}

class _HeroEyebrow extends StatelessWidget {
  const _HeroEyebrow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(.12),
            ),
          ),
          child: const Icon(
            Icons.flight_takeoff_rounded,
            color: Color(0xFF83E8E1),
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLanguage.text('PILOT PROFILE'),
              style: TextStyle(
                color: Colors.white.withOpacity(.58),
                fontSize: 8.2,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLanguage.text('Professional flight identity'),
              style: TextStyle(
                color: Colors.white.withOpacity(.84),
                fontSize: 10.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PilotIdentityCard extends StatelessWidget {
  const _PilotIdentityCard({
    required this.data,
    required this.uploadingPhoto,
    required this.onPhoto,
  });

  final PilotProfileViewData data;
  final bool uploadingPhoto;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final name = data.account.displayName.trim().isEmpty
        ? 'Pilot'
        : data.account.displayName.trim();

    final status = _statusData(
      data.account.status,
    );

    final locationRaw =
        data.profile.currentLocationLabel.trim();
    final location = locationRaw.toLowerCase() == 'not specified'
        ? ''
        : locationRaw;

    final experience = data.profile.experienceYears <= 0
        ? '<1 year experience'
        : '${data.profile.experienceYears}+ years experience';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            14,
            14,
            14,
            14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.97),
                const Color(0xFFF3FCFC).withOpacity(.96),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(.98),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF061B2E).withOpacity(.13),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFF10AEBB).withOpacity(.08),
                blurRadius: 34,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              final avatarSize = compact ? 84.0 : 94.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(
                    size: avatarSize,
                    name: name,
                    photoUrl: data.profilePhotoUrl,
                    uploading: uploadingPhoto,
                    onEdit: onPhoto,
                  ),

                  SizedBox(width: compact ? 12 : 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink,
                            fontSize: compact ? 23 : 26,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.55,
                          ),
                        ),

                        const SizedBox(height: 8),

                        _StatusPill(
                          label: status.label,
                          icon: status.icon,
                          color: status.color,
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _HeroMetaPill(
                              icon: Icons.workspace_premium_outlined,
                              label: experience,
                            ),
                            if (location.isNotEmpty)
                              _HeroMetaPill(
                                icon: Icons.location_on_outlined,
                                label: location,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 170,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _tealSoft,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _teal.withOpacity(.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.circle,
            color: _teal,
            size: 5,
          ),
          const SizedBox(width: 5),
          Icon(
            icon,
            color: _tealDark,
            size: 11,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Material(
          color: Colors.white.withOpacity(.10),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(.16),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
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
      size * .31
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
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFB7F1EE),
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _teal.withOpacity(.20),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPhoto)
                      Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) =>
                            _AvatarInitials(name: name),
                        loadingBuilder: (
                          context,
                          child,
                          progress,
                        ) {
                          if (progress == null) {
                            return child;
                          }
                          return _AvatarInitials(name: name);
                        },
                      )
                    else
                      _AvatarInitials(name: name),

                    if (uploading)
                      Container(
                        color: _ink.withOpacity(.52),
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
        ),

        Positioned(
          right: -1,
          bottom: 3,
          child: Material(
            color: uploading ? _muted2 : _teal,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: _teal.withOpacity(.28),
            child: InkWell(
              onTap: uploading ? null : onEdit,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: cameraSize,
                height: cameraSize,
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 14,
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
          fontSize: 22,
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
        maxWidth: 180,
      ),
      padding: const EdgeInsets.fromLTRB(
        8,
        6,
        10,
        6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: color.withOpacity(.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 13,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PREMIUM PROFILE INFORMATION
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

    final localRegionRaw = profile.currentLocationLabel.trim();
    final localRegion = localRegionRaw.toLowerCase() == 'not specified'
        ? ''
        : localRegionRaw;

    final left = <_ProfileInfoItem>[
      _ProfileInfoItem(
        icon: Icons.calendar_month_outlined,
        label: AppLanguage.text('Date of Birth'),
        value: _formatDate(profile.dateOfBirth),
      ),
      _ProfileInfoItem(
        icon: Icons.public_rounded,
        label: AppLanguage.text('Nationality'),
        value: profile.nationality,
      ),
      _ProfileInfoItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: AppLanguage.text('Languages'),
        value: _languagesLabel(profile.languages),
      ),
    ];

    final right = <_ProfileInfoItem>[
      _ProfileInfoItem(
        icon: Icons.phone_outlined,
        label: AppLanguage.text('Phone'),
        value: account.phone,
      ),
      _ProfileInfoItem(
        icon: Icons.location_on_outlined,
        label: AppLanguage.text('Local Region'),
        value: localRegion,
      ),
      _ProfileInfoItem(
        icon: Icons.work_outline_rounded,
        label: AppLanguage.text('Willing to Work'),
        value: _workRegionsLabel(profile.workRegions),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.055),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLanguage.text('Pilot Information'),
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(AppLanguage.text('Professional details & working preferences'),
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: const Color(0xFFF7FCFD),
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _teal.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: _tealDark,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(AppLanguage.text('Edit'),
                          style: TextStyle(
                            color: _tealDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFE),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: _border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ProfileInfoColumn(items: left),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    color: _border,
                  ),
                  Expanded(
                    child: _ProfileInfoColumn(items: right),
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

class _ProfileInfoItem {
  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _ProfileInfoColumn extends StatelessWidget {
  const _ProfileInfoColumn({required this.items});

  final List<_ProfileInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        return Column(
          children: [
            _ProfileInfoCell(item: items[index]),
            if (index != items.length - 1)
              const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: _border,
              ),
          ],
        );
      }),
    );
  }
}

class _ProfileInfoCell extends StatelessWidget {
  const _ProfileInfoCell({required this.item});

  final _ProfileInfoItem item;

  @override
  Widget build(BuildContext context) {
    final clean = item.value.trim();
    final hasValue = clean.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: _tealSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: _tealDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? clean : 'Not specified',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasValue ? _ink : _muted2,
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: hasValue
                        ? FontWeight.w800
                        : FontWeight.w600,
                    letterSpacing: -0.12,
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
                label: AppLanguage.text('Years Exp'),
                compact: compact,
              ),
            ),

            SizedBox(width: gap),

            Expanded(
              child: _StatCard(
                icon: Icons.flight_takeoff_rounded,
                value: '—',
                label: AppLanguage.text('Missions'),
                compact: compact,
              ),
            ),

            SizedBox(width: gap),

            Expanded(
              child: _StatCard(
                icon: Icons.track_changes_rounded,
                value: '—',
                label: AppLanguage.text('Success Rate'),
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
              Expanded(
                child: Text(AppLanguage.text('My Drones'),
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
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
                label: Text(AppLanguage.text('Add Drone'),
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
                            Text(AppLanguage.text('Drone profile'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(AppLanguage.text('Not linked yet'),
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
                              child: Text(AppLanguage.text('Connect API'),
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

    final heroShellHeight = (
      width * 0.55 + media.padding.top + 96
    ).clamp(
      344.0,
      392.0,
    ).toDouble();

    return Scaffold(
      backgroundColor: _page,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(
              height: heroShellHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: heroShellHeight - 74,
                    child: const _PremiumProfileBackdrop(),
                  ),

                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 0,
                    child: Container(
                      height: 128,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withOpacity(.08),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: _tealSoft,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _teal.withOpacity(.10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SkeletonLine(
                                  width: 126,
                                  height: 22,
                                  light: false,
                                ),
                                SizedBox(height: 9),
                                _SkeletonLine(
                                  width: 112,
                                  height: 28,
                                  light: false,
                                ),
                                SizedBox(height: 9),
                                _SkeletonLine(
                                  width: 176,
                                  height: 24,
                                  light: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                28,
              ),
              child: Column(
                children: [
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Row(
                    children: [
                      Expanded(child: _SkeletonStat()),
                      SizedBox(width: 10),
                      Expanded(child: _SkeletonStat()),
                      SizedBox(width: 10),
                      Expanded(child: _SkeletonStat()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.light,
  });

  final double width;
  final double height;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withOpacity(.16)
            : const Color(0xFFE9EEF2),
        borderRadius: BorderRadius.circular(30),
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
        color: Colors.white,
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

                Text(AppLanguage.text('Profile unavailable'),
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(AppLanguage.text('We could not load your pilot profile.'),
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
                  label: Text(AppLanguage.text('Try Again'),
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
      return _StatusData(
        label: AppLanguage.text('Verified Pilot'),
        icon: Icons.verified_rounded,
        color: _tealDark,
      );

    case 'pending':
      return _StatusData(
        label: AppLanguage.text('Pending Pilot'),
        icon: Icons.schedule_rounded,
        color: Color(0xFFB67A00),
      );

    case 'rejected':
      return _StatusData(
        label: AppLanguage.text('Rejected Pilot'),
        icon: Icons.cancel_outlined,
        color: _danger,
      );

    case 'suspended':
      return _StatusData(
        label: AppLanguage.text('Suspended Pilot'),
        icon: Icons.block_rounded,
        color: _danger,
      );

    default:
      return _StatusData(
        label: AppLanguage.text('Pilot'),
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

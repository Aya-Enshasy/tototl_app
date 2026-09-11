import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/screens/profile/account_settings_screen.dart';
import '../../controllers/company_profile_controller.dart';
import '../../models/company_profile_model.dart';
import '../../services/company_profile_service.dart';
import 'company_edit_profile_screen.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  late final CompanyProfileController _controller;
  final ImagePicker _imagePicker = ImagePicker();

  CompanyProfileViewData? _data;
  bool _loading = true;
  bool _refreshing = false;
  bool _uploadingPhoto = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = CompanyProfileController(
      CompanyProfileService(ApiClient()),
    );
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final local = await _controller.loadLocalProfile();
    if (!mounted) return;

    if (local != null) {
      setState(() {
        _data = local;
        _loading = false;
        _errorMessage = null;
      });
      unawaited(_refreshInBackground());
      return;
    }

    final fresh = await _controller.loadFreshProfile();
    if (!mounted) return;

    setState(() {
      _data = fresh;
      _loading = false;
      _errorMessage =
      fresh == null ? _controller.errorMessage : null;
    });
  }

  Future<void> _refreshInBackground() async {
    if (_refreshing) return;
    _refreshing = true;

    final fresh = await _controller.refreshSilently();
    if (!mounted) return;

    _refreshing = false;
    if (fresh == null) return;

    setState(() {
      _data = fresh;
      _errorMessage = null;
    });
  }

  Future<void> _handleRefresh() async {
    final fresh = await _controller.refreshSilently();
    if (!mounted) return;
    if (fresh != null) {
      setState(() {
        _data = fresh;
        _errorMessage = null;
      });
    }
  }

  Future<void> _openEditProfile() async {
    HapticFeedback.selectionClick();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CompanyEditProfileScreen(),
      ),
    );

    if (!mounted || changed != true) return;

    final local = await _controller.loadLocalProfile();
    if (!mounted) return;
    if (local != null) setState(() => _data = local);
    unawaited(_refreshInBackground());
  }

  Future<void> _openSettings() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccountSettingsScreen(isCompany: true),
      ),
    );

    if (!mounted) return;
    final local = await _controller.loadLocalProfile();
    if (!mounted) return;
    if (local != null) setState(() => _data = local);
    unawaited(_refreshInBackground());
  }

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
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Company Photo',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Use a clear logo or company profile image.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PhotoSourceButton(
                        icon: Icons.camera_alt_outlined,
                        title: 'Camera',
                        onTap: () => Navigator.pop(
                          sheetContext,
                          ImageSource.camera,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoSourceButton(
                        icon: Icons.photo_library_outlined,
                        title: 'Gallery',
                        onTap: () => Navigator.pop(
                          sheetContext,
                          ImageSource.gallery,
                        ),
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

    if (source == null || !mounted) return;

    try {
      final selected = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (selected == null || !mounted) return;

      final oldUrl = _data?.profilePhotoUrl.trim() ?? '';
      if (oldUrl.isNotEmpty) {
        unawaited(NetworkImage(oldUrl).evict());
      }

      setState(() => _uploadingPhoto = true);

      final updated = await _controller.uploadProfilePhoto(
        filePath: selected.path,
      );

      if (!mounted) return;

      setState(() {
        _uploadingPhoto = false;
        if (updated != null) _data = updated;
      });

      if (updated == null) {
        _showSnack(
          _controller.errorMessage ?? 'Unable to update company photo.',
          isError: true,
        );
        return;
      }

      final newUrl = updated.profilePhotoUrl.trim();
      if (newUrl.isNotEmpty) {
        unawaited(NetworkImage(newUrl).evict());
      }

      HapticFeedback.mediumImpact();
      _showSnack('Company photo updated.');
    } on PlatformException {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        _showSnack(
          'Unable to open the image picker. Check app permissions.',
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        _showSnack('Unable to update company photo.', isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          content: Text(
            message,
            style: const TextStyle(fontSize: 12.5),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _CompanyProfileSkeleton();

    if (_data == null) {
      return _ErrorView(
        message: _errorMessage ?? 'Unable to load company profile.',
        onRetry: _loadProfile,
      );
    }

    final data = _data!;
    final profile = data.profile;
    final account = data.account;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.blue,
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                children: [
                  _TopBar(onSettings: _openSettings),
                  const SizedBox(height: 14),
                  _ProfileHero(
                    account: account,
                    profile: profile,
                    profilePhotoUrl: data.profilePhotoUrl,
                    uploadingPhoto: _uploadingPhoto,
                    onPhotoTap: _changeProfilePhoto,
                    onEditTap: _openEditProfile,
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    icon: Icons.notes_rounded,
                    title: 'About',
                    child: Text(
                      profile.description.trim().isEmpty
                          ? 'No company description added yet.'
                          : profile.description,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    icon: Icons.business_center_outlined,
                    title: 'Company Information',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.business_outlined,
                          label: 'Industry',
                          value: _display(profile.industryType),
                        ),
                        const _SoftDivider(),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: profile.locationLabel,
                        ),
                        const _SoftDivider(),
                        _InfoRow(
                          icon: Icons.home_work_outlined,
                          label: 'Address',
                          value: _display(profile.address),
                        ),
                        const _SoftDivider(),
                        _InfoRow(
                          icon: Icons.language_rounded,
                          label: 'Website',
                          value: _display(profile.website),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    icon: Icons.travel_explore_rounded,
                    title: 'Operating Regions',
                    child: profile.workRegions.isEmpty
                        ? const Text(
                      'No operating regions added yet.',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    )
                        : Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: profile.workRegions
                          .map(
                            (region) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(.065),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.blue.withOpacity(.13),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: AppColors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                region.displayLabel,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    icon: Icons.badge_outlined,
                    title: 'Account',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Account name',
                          value: _display(account.name),
                        ),
                        const _SoftDivider(),
                        _InfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Username',
                          value: _display(account.displayUsername),
                        ),
                        const _SoftDivider(),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _display(account.email),
                        ),
                        const _SoftDivider(),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _display(account.phone),
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
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Company Profile',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onSettings,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppColors.navy,
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.account,
    required this.profile,
    required this.profilePhotoUrl,
    required this.uploadingPhoto,
    required this.onPhotoTap,
    required this.onEditTap,
  });

  final CompanyAccountModel account;
  final CompanyProfileModel profile;
  final String profilePhotoUrl;
  final bool uploadingPhoto;
  final VoidCallback onPhotoTap;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final verified = account.isVerified;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(.025),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CompanyPhoto(
                url: profilePhotoUrl,
                verified: verified,
                uploading: uploadingPhoto,
                onTap: onPhotoTap,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayCompanyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.industryAndLocationLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(
                      verified: verified,
                      label: account.statusLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: OutlinedButton.icon(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text(
                'Edit Company Details',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: BorderSide(color: AppColors.blue.withOpacity(.25)),
                backgroundColor: AppColors.blue.withOpacity(.035),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyPhoto extends StatelessWidget {
  const _CompanyPhoto({
    required this.url,
    required this.verified,
    required this.uploading,
    required this.onTap,
  });

  final String url;
  final bool verified;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: uploading ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.blueBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.blue.withOpacity(.14),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url.trim().isNotEmpty)
                    Image.network(
                      url.trim(),
                      key: ValueKey(url.trim()),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _PhotoFallback(),
                    )
                  else
                    const _PhotoFallback(),
                  if (uploading)
                    Container(
                      color: AppColors.navy.withOpacity(.42),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
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
          right: -4,
          bottom: -4,
          child: GestureDetector(
            onTap: uploading ? null : onTap,
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(.12),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ),
        if (verified)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();
  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(
      Icons.apartment_rounded,
      color: AppColors.blue,
      size: 31,
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.verified, required this.label});
  final bool verified;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.green : const Color(0xFFC38315);
    final bg = verified ? AppColors.greenBg : const Color(0xFFFFF5DF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.schedule_rounded,
            color: color,
            size: 12.5,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(.018),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.blue, size: 16),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.blue, size: 15.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? 'Not specified' : value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 41,
    color: AppColors.cardBorder,
  );
}

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
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.blue, size: 21),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
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

class _CompanyProfileSkeleton extends StatefulWidget {
  const _CompanyProfileSkeleton();

  @override
  State<_CompanyProfileSkeleton> createState() => _CompanyProfileSkeletonState();
}

class _CompanyProfileSkeletonState extends State<_CompanyProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
      lowerBound: .45,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pulse,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              Row(
                children: [
                  const Expanded(child: _Bone(width: 126, height: 16)),
                  _Bone(width: 42, height: 42, radius: 13),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _skeletonCard(),
                child: const Row(
                  children: [
                    _Bone(width: 74, height: 74, radius: 20),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Bone(width: 160, height: 14),
                          SizedBox(height: 8),
                          _Bone(width: 200, height: 10),
                          SizedBox(height: 9),
                          _Bone(width: 82, height: 22, radius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                3,
                    (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: _skeletonCard(),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bone(width: 135, height: 13),
                        SizedBox(height: 15),
                        _Bone(width: double.infinity, height: 11),
                        SizedBox(height: 9),
                        _Bone(width: 230, height: 11),
                        SizedBox(height: 9),
                        _Bone(width: 180, height: 11),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _skeletonCard() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.cardBorder),
  );
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    this.radius = 7,
  });
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE9EDF2),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.blueBg,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.blue,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 12.5),
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

String _display(String value) {
  final clean = value.trim();
  return clean.isEmpty ? 'Not specified' : clean;
}

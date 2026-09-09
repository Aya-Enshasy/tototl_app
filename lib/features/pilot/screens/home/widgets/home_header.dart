import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.onNotificationsTap,
    this.unreadNotifications = 0,
  });

  final VoidCallback onNotificationsTap;
  final int unreadNotifications;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  static _HeaderData? _memoryData;

  late final AnimationController _shimmerController;

  bool _loading = true;
  String _name = 'Pilot';
  String _photoUrl = '';
  String _status = '';
  int? _experienceYears;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    final memory = _memoryData;
    if (memory != null) {
      _applyData(memory, notify: false);
      _loading = false;
    }

    // Even when memory exists, refresh it quietly from the persisted session so
    // profile/status edits are reflected without forcing a network request.
    _loadLocalProfile();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalProfile() async {
    // One secure-storage read only. The previous implementation called several
    // getters that each read the same session again.
    final session = await UserSessionStorage.getSession();

    final data = _HeaderData.fromSession(session);
    _memoryData = data;

    if (!mounted) return;

    setState(() {
      _applyData(data, notify: false);
      _loading = false;
    });
  }

  void _applyData(
      _HeaderData data, {
        required bool notify,
      }) {
    _name = data.name;
    _photoUrl = data.photoUrl;
    _status = data.status;
    _experienceYears = data.experienceYears;

    if (notify && mounted) {
      setState(() {});
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  bool get _isVerified {
    final value = _status.toLowerCase();
    return value == 'active' ||
        value == 'approved' ||
        value == 'verified';
  }

  String? get _experienceLabel {
    final years = _experienceYears;
    if (years == null) return null;
    if (years <= 0) return 'New pilot';
    if (years == 1) return '1 year experience';
    return '$years years experience';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _HeaderShimmer(
        controller: _shimmerController,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 4, 1, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(
            name: _name,
            photoUrl: _photoUrl,
            verified: _isVerified,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey.withOpacity(0.86),
                    fontSize: 11.7,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 20.5,
                    height: 1.04,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.55,
                  ),
                ),
                if (_experienceLabel != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        size: 12.5,
                        color: AppColors.logoTurquoiseDark.withOpacity(0.82),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _experienceLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.grey.withOpacity(0.92),
                            fontSize: 10.4,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _NotificationButton(
            unreadCount: widget.unreadNotifications,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onNotificationsTap();
            },
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.photoUrl,
    required this.verified,
  });

  final String name;
  final String photoUrl;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final cleanName = name.trim();
    final initial = cleanName.isEmpty ? 'P' : cleanName[0].toUpperCase();

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: Container(
              width: 59,
              height: 59,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF16C6C7),
                    Color(0xFF087F99),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E9BAA).withOpacity(0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: photoUrl.isEmpty
                      ? _AvatarFallback(initial: initial)
                      : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) =>
                        _AvatarFallback(initial: initial),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Tooltip(
              message: verified ? 'Verified pilot' : 'Verification pending',
              child: _VerificationBadge(
                verified: verified,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({
    required this.verified,
  });

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified
        ? AppColors.logoTurquoiseDark
        : const Color(0xFFAAB6C2);

    return Container(
      width: 23,
      height: 23,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(verified ? 0.22 : 0.12),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.verified_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return Semantics(
      button: true,
      label: hasUnread
          ? 'Notifications, $unreadCount unread'
          : 'Notifications',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.95),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.045),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.navy,
                    size: 21,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 9,
                        minHeight: 9,
                      ),
                      padding: unreadCount > 9
                          ? const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      )
                          : EdgeInsets.zero,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE95454),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.4,
                        ),
                      ),
                      child: unreadCount > 9
                          ? Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 6.8,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                          : null,
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

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initial,
  });

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAFBFB),
            Color(0xFFE9F2F7),
          ],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.logoTurquoiseDark,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer({
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;

        Widget glow({
          required double width,
          required double height,
          required double radius,
        }) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment(-1.8 + (3.6 * t), 0),
                end: Alignment(-0.8 + (3.6 * t), 0),
                colors: const [
                  Color(0xFFF0F4F6),
                  Color(0xFFF9FBFC),
                  Color(0xFFE7F0F3),
                  Color(0xFFF9FBFC),
                  Color(0xFFF0F4F6),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(1, 4, 1, 7),
          child: Row(
            children: [
              glow(
                width: 59,
                height: 59,
                radius: 30,
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    glow(
                      width: 92,
                      height: 9,
                      radius: 6,
                    ),
                    const SizedBox(height: 8),
                    glow(
                      width: 145,
                      height: 18,
                      radius: 7,
                    ),
                    const SizedBox(height: 7),
                    glow(
                      width: 104,
                      height: 9,
                      radius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              glow(
                width: 44,
                height: 44,
                radius: 15,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderData {
  const _HeaderData({
    required this.name,
    required this.photoUrl,
    required this.status,
    required this.experienceYears,
  });

  final String name;
  final String photoUrl;
  final String status;
  final int? experienceYears;

  factory _HeaderData.fromSession(Map<String, dynamic>? rawSession) {
    final session = rawSession ?? const <String, dynamic>{};

    final user = session['user'] is Map
        ? Map<String, dynamic>.from(session['user'] as Map)
        : <String, dynamic>{};

    final profile = session['profile'] is Map
        ? Map<String, dynamic>.from(session['profile'] as Map)
        : <String, dynamic>{};

    Map<String, dynamic> nestedPilotProfile = <String, dynamic>{};

    final directPilotProfile = session['pilot_profile'];
    if (directPilotProfile is Map) {
      nestedPilotProfile = Map<String, dynamic>.from(directPilotProfile);
    } else if (user['pilot_profile'] is Map) {
      nestedPilotProfile =
      Map<String, dynamic>.from(user['pilot_profile'] as Map);
    }

    final name = _clean(user['name']);
    final status = _clean(user['status']);

    final photo = _firstNonEmpty([
      session['profile_photo_url'],
      profile['profile_photo_url'],
      profile['profile_photo'],
      profile['photo_url'],
      user['profile_photo_url'],
    ]);

    final experience = _toInt(
      profile['experience_years'] ??
          nestedPilotProfile['experience_years'],
    );

    return _HeaderData(
      name: name.isEmpty ? 'Pilot' : name,
      photoUrl: photo,
      status: status,
      experienceYears: experience,
    );
  }

  static String _clean(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final clean = _clean(value);
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.verified,
    required this.onNotificationsTap,
    this.unreadNotifications = 0,
  });

  final String name;
  final String photoUrl;
  final bool verified;
  final VoidCallback onNotificationsTap;
  final int unreadNotifications;

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.center,
      children: [
        _PilotAvatar(
          name: name,
          photoUrl: photoUrl,
          verified: verified,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_greeting()},',
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7F8FA3),
                  fontSize: 10.2,
                  height: 1.05,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name.trim().isEmpty
                    ? 'Pilot'
                    : name.trim(),
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0A2D46),
                  fontSize: 16,
                  height: 1.05,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _NotificationButton(
          unreadCount:
          unreadNotifications,
          onTap: () {
            HapticFeedback
                .selectionClick();
            onNotificationsTap();
          },
        ),
      ],
    );
  }
}

class _PilotAvatar extends StatelessWidget {
  const _PilotAvatar({
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
    final initial = cleanName.isEmpty
        ? 'P'
        : cleanName[0].toUpperCase();

    return SizedBox(
      width: 63,
      height: 63,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: Container(
              width: 58,
              height: 58,
              padding:
              const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                const LinearGradient(
                  begin: Alignment.topLeft,
                  end:
                  Alignment.bottomRight,
                  colors: [
                    Color(0xFF15C1C3),
                    Color(0xFF087D98),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                    const Color(
                        0xFF0D98A8)
                        .withOpacity(.12),
                    blurRadius: 13,
                    offset:
                    const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding:
                const EdgeInsets.all(
                    2),
                decoration:
                const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: photoUrl
                      .trim()
                      .isNotEmpty
                      ? Image.network(
                    photoUrl.trim(),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality:
                    FilterQuality
                        .medium,
                    errorBuilder:
                        (_, __, ___) =>
                        _AvatarFallback(
                          initial:
                          initial,
                        ),
                  )
                      : _AvatarFallback(
                    initial: initial,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                    const Color(
                        0xFF0B91A8)
                        .withOpacity(.18),
                    blurRadius: 7,
                    offset:
                    const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 19,
                color: verified
                    ? const Color(
                    0xFF0799AC)
                    : const Color(
                    0xFFACBAC2),
              ),
            ),
          ),
        ],
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
      decoration:
      const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0FBFB),
            Color(0xFFEAF3F6),
          ],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.logoTurquoiseDark,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
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
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(14),
            border: Border.all(
              color:
              const Color(0xFFDDE7EB),
            ),
            boxShadow: [
              BoxShadow(
                color:
                const Color(0xFF0A2D46)
                    .withOpacity(.035),
                blurRadius: 13,
                offset:
                const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons
                      .notifications_none_rounded,
                  color:
                  Color(0xFF0A2D46),
                  size: 20,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                    const BoxDecoration(
                      color:
                      Color(0xFFE95656),
                      shape:
                      BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

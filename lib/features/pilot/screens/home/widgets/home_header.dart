import 'package:flutter/material.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/auth/controllers/user_session_storage.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  bool _loading = true;
  String _name = 'Pilot';
  String _photoUrl = '';
  String _status = '';

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _loadLocalProfile();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalProfile() async {
    final values = await Future.wait<dynamic>([
      UserSessionStorage.getName(),
      UserSessionStorage.getProfilePhotoUrl(),
      UserSessionStorage.getStatus(),
    ]);

    final name = values[0]?.toString().trim() ?? '';
    final photo = values[1]?.toString().trim() ?? '';
    final status = values[2]?.toString().trim() ?? '';

    if (!mounted) return;

    setState(() {
      _name = name.isEmpty ? 'Pilot' : name;
      _photoUrl = photo;
      _status = status;
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _HeaderShimmer(controller: _shimmerController);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(
            name: _name,
            photoUrl: _photoUrl,
            verified: _isVerified,
          ),
          const SizedBox(width: 15),
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
                    color: AppColors.grey.withOpacity(0.88),
                    fontSize: 12.8,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 21,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
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
    final initial = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();

    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(2.2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF16C6C7),
                    Color(0xFF0B7896),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E9BAA).withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
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
                    errorBuilder: (_, __, ___) =>
                        _AvatarFallback(initial: initial),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: 1,
            child: _VerificationBadge(verified: verified),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final badgeColor = verified
        ? AppColors.green
        : const Color(0xFFB8C2CB);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(verified ? 0.22 : 0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 12.5,
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

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
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer({required this.controller});

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
                  Color(0xFFEAF1F4),
                  Color(0xFFF9FBFC),
                  Color(0xFFF0F4F6),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              glow(width: 66, height: 66, radius: 33),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    glow(width: 96, height: 10, radius: 6),
                    const SizedBox(height: 9),
                    glow(width: 150, height: 20, radius: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

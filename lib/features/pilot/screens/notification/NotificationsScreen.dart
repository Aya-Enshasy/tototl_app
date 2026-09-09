import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

class PilotNotificationsScreen extends StatelessWidget {
  const PilotNotificationsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _BackgroundGlow(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  onBack: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                ),
                const Expanded(
                  child: _EmptyNotifications(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 20, 10),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.navy,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Updates that need your attention',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w500,
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

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 70),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 126,
                    height: 126,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF16C6C7).withOpacity(0.14),
                          const Color(0xFF16C6C7).withOpacity(0.035),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppColors.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(0.07),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.logoTurquoiseDark,
                      size: 34,
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 11,
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'You’re all caught up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Job matches, application decisions and important account updates will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey.withOpacity(0.92),
                  fontSize: 11.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                ),
                child: const Row(
                  children: [
                    _InfoIcon(
                      icon: Icons.work_outline_rounded,
                    ),
                    SizedBox(width: 10),
                    _InfoIcon(
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                    SizedBox(width: 10),
                    _InfoIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Job, application and message updates will stay organized here as activity happens.',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 10.2,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: AppColors.logoTurquoiseDark,
        size: 15,
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -160,
          right: -130,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16C6C7).withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -140,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

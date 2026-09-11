import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/chat/screens/chat_inbox_screen.dart';
import 'package:tototl_app/features/chat/screens/chat_screen.dart';

/// Messages entry point used in two ways:
///
/// 1. Bottom navigation -> const MessagesScreen()
///    Shows the authenticated user's Firebase conversation inbox.
///
/// 2. Accepted application -> MessagesScreen(companyUserId: ...)
///    Loads the CURRENT user identity from UserSessionStorage and opens a direct
///    chat with the real COMPANY USER ID passed from the application/job data.
///
/// No user ID or company ID is hardcoded here.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({
    super.key,
    this.companyUserId,
    this.companyName = '',
    this.companyPhotoUrl = '',
  });

  /// This must be the company's USER id used by Firebase chat.
  /// Do not pass company_profile_id here.
  final int? companyUserId;
  final String companyName;
  final String companyPhotoUrl;

  bool get _hasDirectCompanyTarget =>
      companyUserId != null && companyUserId! > 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasDirectCompanyTarget) {
      return const ChatInboxScreen();
    }

    return _DirectCompanyChatBridge(
      companyUserId: companyUserId!,
      companyName: companyName,
      companyPhotoUrl: companyPhotoUrl,
    );
  }
}

class _DirectCompanyChatBridge extends StatefulWidget {
  const _DirectCompanyChatBridge({
    required this.companyUserId,
    required this.companyName,
    required this.companyPhotoUrl,
  });

  final int companyUserId;
  final String companyName;
  final String companyPhotoUrl;

  @override
  State<_DirectCompanyChatBridge> createState() =>
      _DirectCompanyChatBridgeState();
}

class _DirectCompanyChatBridgeState extends State<_DirectCompanyChatBridge> {
  int? _currentUserId;
  String _currentUserName = '';
  String _currentUserPhotoUrl = '';

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final userId = await UserSessionStorage.getUserId();
      final userName = await UserSessionStorage.getName();
      final userPhoto = await UserSessionStorage.getProfilePhotoUrl();

      if (!mounted) return;

      if (userId == null || userId <= 0) {
        setState(() {
          _loading = false;
          _error = 'Your signed-in user ID could not be found.';
        });
        return;
      }

      if (userId == widget.companyUserId) {
        setState(() {
          _loading = false;
          _error = 'The chat recipient cannot be the current user.';
        });
        return;
      }

      setState(() {
        _currentUserId = userId;
        _currentUserName = userName?.trim().isNotEmpty == true
            ? userName!.trim()
            : 'User';
        _currentUserPhotoUrl = userPhoto?.trim() ?? '';
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Couldn’t read your account session.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _ChatBridgeShimmer();
    }

    if (_error != null || _currentUserId == null) {
      return _ChatBridgeError(
        message: _error ?? 'Unable to open this conversation.',
        onRetry: _loadSession,
      );
    }

    final partnerName = widget.companyName.trim().isNotEmpty
        ? widget.companyName.trim()
        : 'Company';

    return ChatScreen(
      currentUserId: _currentUserId!.toString(),
      currentUserName: _currentUserName,
      currentUserPhotoUrl: _currentUserPhotoUrl,
      partnerId: widget.companyUserId.toString(),
      partnerName: partnerName,
      partnerPhotoUrl: widget.companyPhotoUrl.trim(),
    );
  }
}

class _ChatBridgeShimmer extends StatefulWidget {
  const _ChatBridgeShimmer();

  @override
  State<_ChatBridgeShimmer> createState() => _ChatBridgeShimmerState();
}

class _ChatBridgeShimmerState extends State<_ChatBridgeShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            Widget glow({
              required double height,
              double? width,
              double radius = 14,
            }) {
              final t = _controller.value;

              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment(-1.8 + (3.6 * t), 0),
                    end: Alignment(-0.8 + (3.6 * t), 0),
                    colors: const [
                      Color(0xFFEAF0F4),
                      Color(0xFFF8FBFC),
                      Color(0xFFE5EDF2),
                      Color(0xFFF8FBFC),
                      Color(0xFFEAF0F4),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                  child: Row(
                    children: [
                      glow(height: 40, width: 40, radius: 20),
                      const SizedBox(width: 10),
                      glow(height: 44, width: 44, radius: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            glow(height: 12, width: 132, radius: 6),
                            const SizedBox(height: 7),
                            glow(height: 8, width: 82, radius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                Expanded(
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: glow(height: 54, width: 205, radius: 18),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: glow(height: 46, width: 170, radius: 18),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: glow(height: 64, width: 230, radius: 18),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: glow(height: 52, radius: 18),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatBridgeError extends StatelessWidget {
  const _ChatBridgeError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.navy,
                      size: 18,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.blueBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.forum_outlined,
                          color: AppColors.logoTurquoiseDark,
                          size: 29,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Couldn’t open chat',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.logoTurquoiseDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text(
                          'Try Again',
                          style: TextStyle(fontWeight: FontWeight.w800),
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
    );
  }
}

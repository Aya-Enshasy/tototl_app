import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tototl_app/core/localization/app_language.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';

import 'package:tototl_app/features/auth/controllers/auth_controller.dart';
import 'package:tototl_app/features/auth/screens/login/login_screen.dart';
import 'package:tototl_app/features/auth/services/auth_service.dart';

import 'package:tototl_app/features/company/screens/profile/company_edit_profile_screen.dart';
import 'package:tototl_app/features/pilot/screens/profile/pilot_edit_profile_screen.dart';

import '../../controllers/logout_controller.dart';
import '../../services/logout_service.dart';
import '../../settings_detail_screens.dart';

// ============================================================================
// ACCOUNT SETTINGS SCREEN
// ============================================================================

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({
    super.key,
    required this.isCompany,
  });

  final bool isCompany;

  @override
  State<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final ApiClient _apiClient;
  late final LogoutService _logoutService;
  late final LogoutController _logoutController;
  late final AuthService _authService;
  late final AuthController _authController;

  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient();

    _logoutService = LogoutService(
      _apiClient,
    );

    _logoutController = LogoutController(
      _logoutService,
    );

    _authService = AuthService(
      _apiClient,
    );

    _authController = AuthController(
      _authService,
    );
  }

  // ==========================================================================
  // UPDATE PROFILE
  // ==========================================================================

  Future<void> _openUpdateProfile() async {
    HapticFeedback.selectionClick();

    if (widget.isCompany) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CompanyEditProfileScreen(),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PilotEditProfileScreen(),
      ),
    );
  }

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  void _go(Widget screen) {
    HapticFeedback.selectionClick();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  // ==========================================================================
  // LOGOUT CONFIRMATION
  // ==========================================================================

  Future<void> _confirmLogout() async {
    if (_loggingOut) return;

    HapticFeedback.selectionClick();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFD94A4A),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _logoutTitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _logoutMessage(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                            false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _cancelLabel(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                            true,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD94A4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 17,
                        ),
                        label: Text(
                          _logoutLabel(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
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

    if (confirmed != true) return;

    await _logout();
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    final success = await _logoutController.logout();

    if (!mounted) return;

    if (!success) {
      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD94A4A),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Text(
            _logoutController.errorMessage ?? 'Unable to sign out.',
          ),
        ),
      );

      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authController: _authController,
        ),
      ),
          (route) => false,
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (_, locale, __) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: AppColors.bg,
                surfaceTintColor: AppColors.bg,
                elevation: 0,
                title: Text(
                  AppLanguage.t('settings'),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                leading: IconButton(
                  onPressed: _loggingOut
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                  ),
                ),
              ),
              body: SafeArea(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    34,
                  ),
                  children: [
                    _SettingsIntro(
                      isCompany: widget.isCompany,
                      locale: locale,
                    ),
                    const SizedBox(height: 18),

                    _SectionCard(
                      title: AppLanguage.t('profile'),
                      subtitle: _profileSectionSubtitle(locale),
                      child: _SettingsRow(
                        icon: widget.isCompany
                            ? Icons.apartment_rounded
                            : Icons.person_outline_rounded,
                        title: AppLanguage.t('updateProfile'),
                        subtitle: widget.isCompany
                            ? _companyProfileSubtitle(locale)
                            : _pilotProfileSubtitle(locale),
                        onTap: _openUpdateProfile,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _SectionCard(
                      title: _accountSecurityTitle(locale),
                      subtitle: _accountSecuritySubtitle(locale),
                      child: Column(
                        children: [
                          _SettingsRow(
                            icon: Icons.lock_outline_rounded,
                            title: AppLanguage.t('changePassword'),
                            subtitle: _passwordSubtitle(locale),
                            onTap: () => _go(
                              const ChangePasswordScreen(),
                            ),
                          ),
                          const _SoftDivider(),
                          _SettingsRow(
                            icon: Icons.language_rounded,
                            title: AppLanguage.t('language'),
                            subtitle: {
                              'ar': 'العربية',
                              'de': 'Deutsch',
                            }[locale.languageCode] ??
                                'English',
                            onTap: () => _go(
                              const LanguageScreen(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _SectionCard(
                      title: _legalSectionTitle(locale),
                      subtitle: _legalSectionSubtitle(locale),
                      child: _SettingsRow(
                        icon: Icons.gavel_rounded,
                        title: _termsPrivacyTitle(locale),
                        subtitle: _termsPrivacySubtitle(locale),
                        onTap: () => _go(
                          TermsPrivacyScreen(locale: locale),
                        ),
                        accentColor: const Color(0xFF0FA6B4),
                        accentBackground: const Color(0xFFEAF9FA),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _SectionCard(
                      title: AppLanguage.t('about'),
                      subtitle: _aboutSectionSubtitle(locale),
                      child: _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: AppLanguage.t('about'),
                        subtitle: 'TOTOTL INTGRX · 1.0.0',
                        onTap: () => _go(
                          const AboutScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _SectionCard(
                      title: _sessionLabel(locale),
                      subtitle: _sessionSectionSubtitle(locale),
                      child: _LogoutRow(
                        title: _logoutLabel(),
                        subtitle: _logoutSubtitle(locale),
                        onTap: _confirmLogout,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_loggingOut) ...[
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Color(0x22000000),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 170,
                        maxWidth: 230,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.cardBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF9FA),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              color: Color(0xFF078B98),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _signingOutLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _logoutLabel() {
    final code = AppLanguage.locale.value.languageCode;

    switch (code) {
      case 'ar':
        return 'تسجيل الخروج';
      case 'de':
        return 'Abmelden';
      default:
        return 'Log out';
    }
  }

  String _logoutTitle() {
    final code = AppLanguage.locale.value.languageCode;

    switch (code) {
      case 'ar':
        return 'تسجيل الخروج؟';
      case 'de':
        return 'Abmelden?';
      default:
        return 'Log out?';
    }
  }

  String _logoutMessage() {
    final code = AppLanguage.locale.value.languageCode;

    switch (code) {
      case 'ar':
        return 'سيتم إنهاء الجلسة الحالية وإعادتك إلى شاشة تسجيل الدخول.';
      case 'de':
        return 'Deine aktuelle Sitzung wird beendet und du wirst zur Anmeldung zurückgebracht.';
      default:
        return 'Your current session will end and you will return to the sign-in screen.';
    }
  }

  String _cancelLabel() {
    final code = AppLanguage.locale.value.languageCode;

    switch (code) {
      case 'ar':
        return 'إلغاء';
      case 'de':
        return 'Abbrechen';
      default:
        return 'Cancel';
    }
  }

  String _signingOutLabel() {
    final code = AppLanguage.locale.value.languageCode;

    switch (code) {
      case 'ar':
        return 'جارٍ تسجيل الخروج...';
      case 'de':
        return 'Abmeldung...';
      default:
        return 'Signing out...';
    }
  }
}

// ============================================================================
// TERMS & PRIVACY SCREEN
// ============================================================================

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({
    super.key,
    required this.locale,
  });

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final content = _legalContent(locale);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        title: Text(
          _termsPrivacyTitle(locale),
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071A35),
                    Color(0xFF0A3B5D),
                    Color(0xFF078B98),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF071A35).withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.heroTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          content.heroSubtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _LegalTextCard(
              icon: Icons.description_outlined,
              title: content.termsTitle,
              intro: content.termsIntro,
              items: content.termsItems,
            ),
            const SizedBox(height: 14),

            _LegalTextCard(
              icon: Icons.shield_outlined,
              title: content.privacyTitle,
              intro: content.privacyIntro,
              items: content.privacyItems,
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9FA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF0FA6B4).withOpacity(0.16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF078B98),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      content.footerNote,
                      style: const TextStyle(
                        color: Color(0xFF356475),
                        fontSize: 11.3,
                        height: 1.45,
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
    );
  }
}

// ============================================================================
// SETTINGS INTRO
// ============================================================================

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro({
    required this.isCompany,
    required this.locale,
  });

  final bool isCompany;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 15, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF7FCFD),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071A35).withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9FA),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF078B98),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settingsIntroTitle(locale),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _settingsIntroSubtitle(
                    locale,
                    isCompany: isCompany,
                  ),
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11.2,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              isCompany
                  ? _companyRoleLabel(locale)
                  : _pilotRoleLabel(locale),
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 9.5,
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
// SECTION CARD
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071A35).withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: AppColors.cardBorder,
          ),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// SETTINGS ROW
// ============================================================================

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.accentColor = AppColors.blue,
    this.accentBackground = const Color(0xFFF0F5FF),
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color accentColor;
  final Color accentBackground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 10.6,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.lightGrey,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 68,
      endIndent: 14,
      color: AppColors.cardBorder,
    );
  }
}

// ============================================================================
// LOGOUT ROW
// ============================================================================

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFD94A4A),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFD94A4A),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.6,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFE39A9A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LEGAL TEXT CARD
// ============================================================================

class _LegalTextCard extends StatelessWidget {
  const _LegalTextCard({
    required this.icon,
    required this.title,
    required this.intro,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String intro;
  final List<_LegalItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071A35).withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF9FA),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF078B98),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            intro,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 11.3,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 13),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F8),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: Color(0xFF078B98),
                          fontSize: 9.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 11.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 10.6,
                              height: 1.48,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    indent: 37,
                    color: AppColors.cardBorder,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// LEGAL CONTENT DATA
// ============================================================================

class _LegalItemData {
  const _LegalItemData({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class _LegalContentData {
  const _LegalContentData({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.termsTitle,
    required this.termsIntro,
    required this.termsItems,
    required this.privacyTitle,
    required this.privacyIntro,
    required this.privacyItems,
    required this.footerNote,
  });

  final String heroTitle;
  final String heroSubtitle;
  final String termsTitle;
  final String termsIntro;
  final List<_LegalItemData> termsItems;
  final String privacyTitle;
  final String privacyIntro;
  final List<_LegalItemData> privacyItems;
  final String footerNote;
}

_LegalContentData _legalContent(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return const _LegalContentData(
        heroTitle: 'شروط الاستخدام والخصوصية',
        heroSubtitle:
        'ملخص واضح لكيفية استخدام منصة TOTOTL INTGRX وكيف نتعامل مع بياناتك ونحميها.',
        termsTitle: 'شروط الاستخدام',
        termsIntro:
        'باستخدامك للمنصة أو إنشاء حساب، فإنك توافق على استخدام الخدمات بطريقة قانونية ومسؤولة ووفق القواعد الموضحة أدناه.',
        termsItems: [
          _LegalItemData(
            title: 'قبول الشروط',
            body:
            'إنشاء الحساب أو الاستمرار في استخدام المنصة يعني موافقتك على هذه الشروط وعلى السياسات المرتبطة بالخدمة.',
          ),
          _LegalItemData(
            title: 'دور المنصة',
            body:
            'TOTOTL INTGRX تربط الطيارين والشركات وتساعدهم في العثور على فرص العمل وإدارة الطلبات والتواصل، بينما تبقى مسؤولية تنفيذ المهمة والالتزام بالقوانين على الأطراف المعنية.',
          ),
          _LegalItemData(
            title: 'مسؤولية الحساب',
            body:
            'يجب تقديم معلومات صحيحة ومحدثة والمحافظة على سرية بيانات تسجيل الدخول وعدم استخدام حساب شخص آخر أو تقديم مستندات مضللة.',
          ),
          _LegalItemData(
            title: 'الوظائف والتعاقدات',
            body:
            'يلتزم المستخدمون بتوضيح نطاق العمل والمتطلبات والمواعيد وأي اشتراطات سلامة أو تراخيص قبل بدء المهمة.',
          ),
          _LegalItemData(
            title: 'المدفوعات والاشتراكات',
            body:
            'أي رسوم أو اشتراكات أو مدفوعات مستقبلية تخضع للشروط المعروضة وقت الشراء أو التعاقد وللقوانين المعمول بها.',
          ),
          _LegalItemData(
            title: 'تعليق أو إنهاء الحساب',
            body:
            'قد يتم تقييد أو تعليق الحساب عند إساءة استخدام المنصة أو الاحتيال أو مخالفة القوانين أو سياسات الخدمة.',
          ),
        ],
        privacyTitle: 'سياسة الخصوصية',
        privacyIntro:
        'نستخدم بياناتك فقط لتشغيل المنصة وتحسين التجربة وتوفير الوظائف الأساسية اللازمة للحسابات والطلبات والتواصل.',
        privacyItems: [
          _LegalItemData(
            title: 'البيانات التي نجمعها',
            body:
            'قد تشمل بيانات الحساب والملف الشخصي ومعلومات التواصل والمناطق والخبرة والتراخيص وبيانات الدرون والوظائف والطلبات المرتبطة باستخدامك للمنصة.',
          ),
          _LegalItemData(
            title: 'كيف نستخدم البيانات',
            body:
            'نستخدم البيانات لتشغيل الحساب، مطابقة الشركات والطيارين، عرض الملفات ذات الصلة، إدارة الطلبات، دعم الأمان وتحسين الخدمة.',
          ),
          _LegalItemData(
            title: 'مشاركة البيانات',
            body:
            'لا نشارك بياناتك إلا بالقدر اللازم لتقديم الخدمة، أو مع الأطراف التي تتعامل معها داخل المنصة، أو عندما يفرض القانون ذلك.',
          ),
          _LegalItemData(
            title: 'أمان البيانات',
            body:
            'نطبق وسائل حماية مناسبة ونقيد الوصول إلى البيانات الحساسة، مع ضرورة حفاظ المستخدم على أمان كلمة المرور والجهاز والحساب.',
          ),
          _LegalItemData(
            title: 'الاحتفاظ بالبيانات',
            body:
            'نحتفظ بالبيانات للمدة اللازمة لتشغيل الخدمة والالتزامات القانونية وحماية المنصة، ثم نحذفها أو نقلل ارتباطها بالمستخدم عندما يكون ذلك مناسبًا.',
          ),
          _LegalItemData(
            title: 'اختياراتك وحقوقك',
            body:
            'يمكنك تحديث معلومات حسابك والتواصل مع إدارة المنصة بشأن الاستفسارات المتعلقة بالخصوصية أو البيانات أو الحساب.',
          ),
        ],
        footerNote:
        'يفضل مراجعة الصياغة القانونية النهائية بواسطة مختص قبل إطلاق التطبيق تجاريًا في كل سوق مستهدف.',
      );

    case 'de':
      return const _LegalContentData(
        heroTitle: 'Nutzungsbedingungen & Datenschutz',
        heroSubtitle:
        'Eine klare Zusammenfassung darüber, wie TOTOTL INTGRX genutzt wird und wie wir mit deinen Daten umgehen.',
        termsTitle: 'Nutzungsbedingungen',
        termsIntro:
        'Mit der Erstellung eines Kontos oder der Nutzung der Plattform stimmst du zu, die Dienste rechtmäßig und verantwortungsvoll zu verwenden.',
        termsItems: [
          _LegalItemData(
            title: 'Annahme der Bedingungen',
            body:
            'Durch die Nutzung der Plattform stimmst du diesen Bedingungen und den zugehörigen Richtlinien zu.',
          ),
          _LegalItemData(
            title: 'Rolle der Plattform',
            body:
            'TOTOTL INTGRX verbindet Drohnenpiloten und Unternehmen. Die Parteien bleiben für die Durchführung von Aufträgen und die Einhaltung geltender Vorschriften verantwortlich.',
          ),
          _LegalItemData(
            title: 'Kontoverantwortung',
            body:
            'Kontoinformationen müssen korrekt und aktuell sein. Zugangsdaten dürfen nicht missbraucht oder mit unbefugten Personen geteilt werden.',
          ),
          _LegalItemData(
            title: 'Aufträge und Zusammenarbeit',
            body:
            'Leistungsumfang, Anforderungen, Zeitplan, Sicherheitsregeln und erforderliche Zertifikate sollten vor Beginn einer Mission eindeutig vereinbart werden.',
          ),
          _LegalItemData(
            title: 'Zahlungen und Abonnements',
            body:
            'Zukünftige Gebühren, Abonnements oder Zahlungen richten sich nach den beim Kauf angezeigten Bedingungen und dem anwendbaren Recht.',
          ),
          _LegalItemData(
            title: 'Sperrung oder Kündigung',
            body:
            'Konten können bei Missbrauch, Betrug, Rechtsverstößen oder Verstößen gegen Plattformrichtlinien eingeschränkt oder gesperrt werden.',
          ),
        ],
        privacyTitle: 'Datenschutzrichtlinie',
        privacyIntro:
        'Wir verwenden deine Daten, um die Plattform zu betreiben, die Nutzererfahrung zu verbessern und wesentliche Kontofunktionen bereitzustellen.',
        privacyItems: [
          _LegalItemData(
            title: 'Welche Daten wir erfassen',
            body:
            'Dazu können Konto-, Profil- und Kontaktdaten, Regionen, Erfahrung, Lizenzen, Drohnendaten, Aufträge und Bewerbungsdaten gehören.',
          ),
          _LegalItemData(
            title: 'Wie wir Daten verwenden',
            body:
            'Wir nutzen Daten für Kontofunktionen, Matching, relevante Profile, Bewerbungen, Sicherheit und Serviceverbesserungen.',
          ),
          _LegalItemData(
            title: 'Weitergabe von Daten',
            body:
            'Daten werden nur soweit erforderlich für die Bereitstellung der Plattform, für Interaktionen zwischen Nutzern oder aufgrund gesetzlicher Pflichten weitergegeben.',
          ),
          _LegalItemData(
            title: 'Datensicherheit',
            body:
            'Wir verwenden angemessene Schutzmaßnahmen und beschränken den Zugriff auf sensible Daten. Nutzer müssen ihre Zugangsdaten und Geräte ebenfalls schützen.',
          ),
          _LegalItemData(
            title: 'Speicherdauer',
            body:
            'Daten werden so lange gespeichert, wie es für den Dienst, gesetzliche Pflichten und den Schutz der Plattform erforderlich ist.',
          ),
          _LegalItemData(
            title: 'Deine Möglichkeiten',
            body:
            'Du kannst Kontoinformationen aktualisieren und dich bei Fragen zu Datenschutz, Daten oder deinem Konto an den Plattform-Support wenden.',
          ),
        ],
        footerNote:
        'Vor einem kommerziellen Start sollte die endgültige rechtliche Fassung für jeden Zielmarkt von einer qualifizierten Fachperson geprüft werden.',
      );

    default:
      return const _LegalContentData(
        heroTitle: 'Terms of Use & Privacy',
        heroSubtitle:
        'A clear summary of how TOTOTL INTGRX may be used and how your information is handled and protected.',
        termsTitle: 'Terms of Use',
        termsIntro:
        'By creating an account or using the platform, you agree to use the services lawfully, responsibly, and in accordance with the rules below.',
        termsItems: [
          _LegalItemData(
            title: 'Acceptance of Terms',
            body:
            'Creating an account or continuing to use the platform means you agree to these terms and the policies connected to the service.',
          ),
          _LegalItemData(
            title: 'Platform Role',
            body:
            'TOTOTL INTGRX connects drone pilots and companies and helps them discover work, manage applications, and communicate. The parties remain responsible for performing missions and complying with applicable laws.',
          ),
          _LegalItemData(
            title: 'Account Responsibility',
            body:
            'You must provide accurate, current information, protect your sign-in credentials, and avoid using another person’s account or submitting misleading documents.',
          ),
          _LegalItemData(
            title: 'Jobs & Engagements',
            body:
            'Users should clearly agree on scope, requirements, schedule, safety expectations, and required licenses or certifications before a mission begins.',
          ),
          _LegalItemData(
            title: 'Payments & Subscriptions',
            body:
            'Any future fees, subscriptions, or payments are subject to the terms shown at the time of purchase or engagement and to applicable law.',
          ),
          _LegalItemData(
            title: 'Suspension or Termination',
            body:
            'Accounts may be restricted or suspended for platform abuse, fraud, unlawful activity, or violations of service policies.',
          ),
        ],
        privacyTitle: 'Privacy Policy',
        privacyIntro:
        'We use your information to operate the platform, improve the experience, and provide the core account, application, and communication features you use.',
        privacyItems: [
          _LegalItemData(
            title: 'Information We Collect',
            body:
            'This may include account and profile details, contact information, regions, experience, licenses, drone information, jobs, and application data connected to your use of the platform.',
          ),
          _LegalItemData(
            title: 'How We Use Information',
            body:
            'We use information to operate accounts, match companies and pilots, show relevant profiles, manage applications, support security, and improve the service.',
          ),
          _LegalItemData(
            title: 'Information Sharing',
            body:
            'We share information only as needed to provide the service, support interactions with other users, work with necessary service providers, or comply with legal obligations.',
          ),
          _LegalItemData(
            title: 'Data Security',
            body:
            'We apply reasonable safeguards and limit access to sensitive information. Users should also protect their password, device, and account access.',
          ),
          _LegalItemData(
            title: 'Data Retention',
            body:
            'Information is kept for as long as needed to operate the service, meet legal obligations, and protect the platform, then deleted or de-identified when appropriate.',
          ),
          _LegalItemData(
            title: 'Your Choices',
            body:
            'You can update your account information and contact platform support with questions about privacy, your information, or your account.',
          ),
        ],
        footerNote:
        'Have the final legal wording reviewed by a qualified professional before commercial release in each target market.',
      );
  }
}

// ============================================================================
// LOCALIZED HELPERS
// ============================================================================

String _settingsIntroTitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'إعداداتك في مكان واحد';
    case 'de':
      return 'Deine Einstellungen an einem Ort';
    default:
      return 'Your settings, all in one place';
  }
}

String _settingsIntroSubtitle(
    Locale locale, {
      required bool isCompany,
    }) {
  switch (locale.languageCode) {
    case 'ar':
      return isCompany
          ? 'إدارة ملف الشركة والأمان واللغة والسياسات.'
          : 'إدارة ملف الطيار والأمان واللغة والسياسات.';
    case 'de':
      return isCompany
          ? 'Unternehmensprofil, Sicherheit, Sprache und Richtlinien verwalten.'
          : 'Pilotprofil, Sicherheit, Sprache und Richtlinien verwalten.';
    default:
      return isCompany
          ? 'Manage your company profile, security, language and policies.'
          : 'Manage your pilot profile, security, language and policies.';
  }
}

String _pilotRoleLabel(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'طيار';
    case 'de':
      return 'Pilot';
    default:
      return 'Pilot';
  }
}

String _companyRoleLabel(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'شركة';
    case 'de':
      return 'Unternehmen';
    default:
      return 'Company';
  }
}

String _profileSectionSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'حافظ على معلومات حسابك المهنية محدثة.';
    case 'de':
      return 'Halte deine professionellen Kontodaten aktuell.';
    default:
      return 'Keep your professional account information up to date.';
  }
}

String _accountSecurityTitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'الحساب والأمان';
    case 'de':
      return 'Konto & Sicherheit';
    default:
      return 'Account & Security';
  }
}

String _accountSecuritySubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'إدارة كلمة المرور ولغة التطبيق.';
    case 'de':
      return 'Passwort und App-Sprache verwalten.';
    default:
      return 'Manage your password and app language.';
  }
}

String _passwordSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'حدّث كلمة المرور للحفاظ على أمان الحساب.';
    case 'de':
      return 'Aktualisiere dein Passwort, um dein Konto zu schützen.';
    default:
      return 'Update your password to keep your account secure.';
  }
}

String _legalSectionTitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'الشروط والخصوصية';
    case 'de':
      return 'Rechtliches & Datenschutz';
    default:
      return 'Terms & Privacy';
  }
}

String _legalSectionSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'اطلع على قواعد استخدام المنصة وكيف نتعامل مع بياناتك.';
    case 'de':
      return 'Erfahre, wie die Plattform genutzt wird und wie Daten behandelt werden.';
    default:
      return 'Review platform rules and how your information is handled.';
  }
}

String _termsPrivacyTitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'شروط الاستخدام والخصوصية';
    case 'de':
      return 'Nutzungsbedingungen & Datenschutz';
    default:
      return 'Terms of Use & Privacy';
  }
}

String _termsPrivacySubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'شروط الاستخدام وسياسة الخصوصية في صفحة واحدة واضحة.';
    case 'de':
      return 'Nutzungsbedingungen und Datenschutzrichtlinie übersichtlich an einem Ort.';
    default:
      return 'Terms of use and privacy policy in one clear place.';
  }
}

String _aboutSectionSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'معلومات التطبيق والإصدار الحالي.';
    case 'de':
      return 'Informationen zur App und zur aktuellen Version.';
    default:
      return 'App information and current version details.';
  }
}

String _sessionLabel(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'الجلسة';
    case 'de':
      return 'Sitzung';
    default:
      return 'Session';
  }
}

String _sessionSectionSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'إدارة جلسة تسجيل الدخول الحالية.';
    case 'de':
      return 'Aktuelle Anmeldesitzung verwalten.';
    default:
      return 'Manage your current signed-in session.';
  }
}

String _logoutSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'إنهاء الجلسة الحالية بأمان';
    case 'de':
      return 'Aktuelle Sitzung sicher beenden';
    default:
      return 'Securely end your current session';
  }
}

String _pilotProfileSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'تعديل بيانات وخبرة الطيار';
    case 'de':
      return 'Pilotprofil und Erfahrung bearbeiten';
    default:
      return 'Edit pilot details and experience';
  }
}

String _companyProfileSubtitle(Locale locale) {
  switch (locale.languageCode) {
    case 'ar':
      return 'تعديل بيانات ومناطق عمل الشركة';
    case 'de':
      return 'Unternehmensdaten und Regionen bearbeiten';
    default:
      return 'Edit company details and operating regions';
  }
}

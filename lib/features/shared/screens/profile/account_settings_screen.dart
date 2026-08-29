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

class _AccountSettingsScreenState
    extends State<AccountSettingsScreen> {
  bool jobUpdates = true;
  bool applicationUpdates = true;
  bool emailUpdates = false;

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
          builder: (_) =>
          const CompanyEditProfileScreen(),
        ),
      );

      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const PilotEditProfileScreen(),
      ),
    );
  }

  // ==========================================================================
  // LOGOUT CONFIRMATION
  // ==========================================================================

  Future<void> _confirmLogout() async {
    if (_loggingOut) {
      return;
    }

    HapticFeedback.selectionClick();

    final confirmed =
    await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ),
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
                    color: AppColors.cardBorder,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius:
                    BorderRadius.circular(18),
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
                          foregroundColor:
                          AppColors.navy,
                          side: const BorderSide(
                            color:
                            AppColors.cardBorder,
                          ),
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _cancelLabel(),
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w700,
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
                          backgroundColor:
                          const Color(0xFFD94A4A),
                          foregroundColor:
                          Colors.white,
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 17,
                        ),
                        label: Text(
                          _logoutLabel(),
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w800,
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

    if (confirmed != true) {
      return;
    }

    await _logout();
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  Future<void> _logout() async {
    if (_loggingOut) {
      return;
    }

    setState(() {
      _loggingOut = true;
    });

    final success =
    await _logoutController.logout();

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          const Color(0xFFD94A4A),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(15),
          ),
          content: Text(
            _logoutController.errorMessage ??
                'Unable to sign out.',
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

  void _go(
      Widget screen,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (
          _,
          locale,
          __,
          ) {
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
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    32,
                  ),
                  children: [
                    _Card(
                      title: AppLanguage.t('profile'),
                      child: _Row(
                        icon: widget.isCompany
                            ? Icons.apartment_rounded
                            : Icons.person_outline_rounded,
                        title:
                        AppLanguage.t('updateProfile'),
                        subtitle: widget.isCompany
                            ? _companyProfileSubtitle(
                          locale,
                        )
                            : _pilotProfileSubtitle(
                          locale,
                        ),
                        onTap: _openUpdateProfile,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Card(
                      title:
                      AppLanguage.t('notifications'),
                      child: Column(
                        children: [
                          _Switch(
                            title: widget.isCompany
                                ? _jobActivityLabel(
                              locale,
                            )
                                : AppLanguage.t(
                              'jobUpdates',
                            ),
                            value: jobUpdates,
                            onChanged: (value) {
                              setState(() {
                                jobUpdates = value;
                              });
                            },
                          ),
                          const Divider(
                            color:
                            AppColors.cardBorder,
                          ),
                          _Switch(
                            title: AppLanguage.t(
                              'applicationUpdates',
                            ),
                            value:
                            applicationUpdates,
                            onChanged: (value) {
                              setState(() {
                                applicationUpdates =
                                    value;
                              });
                            },
                          ),
                          const Divider(
                            color:
                            AppColors.cardBorder,
                          ),
                          _Switch(
                            title: AppLanguage.t(
                              'emailUpdates',
                            ),
                            value: emailUpdates,
                            onChanged: (value) {
                              setState(() {
                                emailUpdates = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Card(
                      title: AppLanguage.t('account'),
                      child: Column(
                        children: [
                          _Row(
                            icon:
                            Icons.lock_outline_rounded,
                            title: AppLanguage.t(
                              'changePassword',
                            ),
                            onTap: () => _go(
                              const ChangePasswordScreen(),
                            ),
                          ),
                          const Divider(
                            color:
                            AppColors.cardBorder,
                          ),
                          _Row(
                            icon: Icons
                                .privacy_tip_outlined,
                            title:
                            AppLanguage.t('privacy'),
                            onTap: () => _go(
                              const PrivacyScreen(),
                            ),
                          ),
                          const Divider(
                            color:
                            AppColors.cardBorder,
                          ),
                          _Row(
                            icon:
                            Icons.language_rounded,
                            title:
                            AppLanguage.t('language'),
                            subtitle: {
                              'ar': 'العربية',
                              'de': 'Deutsch',
                            }[
                            locale.languageCode] ??
                                'English',
                            onTap: () => _go(
                              const LanguageScreen(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Card(
                      title: AppLanguage.t('about'),
                      child: _Row(
                        icon:
                        Icons.info_outline_rounded,
                        title:
                        AppLanguage.t('about'),
                        subtitle:
                        'TOTOTL INTGRX · 1.0.0',
                        onTap: () => _go(
                          const AboutScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Card(
                      title: _sessionLabel(locale),
                      child: _LogoutRow(
                        title: _logoutLabel(),
                        subtitle:
                        _logoutSubtitle(locale),
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
                            offset: const Offset(
                              0,
                              8,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.primary,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Flexible(
                            child: Text(
                              _signingOutLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.navy,

                                // مهم جدًا
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
    final code =
        AppLanguage.locale.value.languageCode;

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
    final code =
        AppLanguage.locale.value.languageCode;

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
    final code =
        AppLanguage.locale.value.languageCode;

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
    final code =
        AppLanguage.locale.value.languageCode;

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
    final code =
        AppLanguage.locale.value.languageCode;

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
// CARD
// ============================================================================

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// SWITCH
// ============================================================================

class _Switch extends StatelessWidget {
  const _Switch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(
      BuildContext context,
      ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}

// ============================================================================
// NORMAL ROW
// ============================================================================

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.lightGrey,
            ),
          ],
        ),
      ),
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
  Widget build(
      BuildContext context,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                const Color(0xFFFFEEEE),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD94A4A),
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color:
                      Color(0xFFD94A4A),
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFE39A9A),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LOCALIZED HELPERS
// ============================================================================

String _sessionLabel(
    Locale locale,
    ) {
  switch (locale.languageCode) {
    case 'ar':
      return 'الجلسة';
    case 'de':
      return 'Sitzung';
    default:
      return 'Session';
  }
}

String _logoutSubtitle(
    Locale locale,
    ) {
  switch (locale.languageCode) {
    case 'ar':
      return 'إنهاء الجلسة الحالية بأمان';
    case 'de':
      return 'Aktuelle Sitzung sicher beenden';
    default:
      return 'Securely end your current session';
  }
}

String _pilotProfileSubtitle(
    Locale locale,
    ) {
  switch (locale.languageCode) {
    case 'ar':
      return 'تعديل بيانات وخبرة الطيار';
    case 'de':
      return 'Pilotprofil und Erfahrung bearbeiten';
    default:
      return 'Edit pilot details and experience';
  }
}

String _companyProfileSubtitle(
    Locale locale,
    ) {
  switch (locale.languageCode) {
    case 'ar':
      return 'تعديل بيانات ومناطق عمل الشركة';
    case 'de':
      return 'Unternehmensdaten und Regionen bearbeiten';
    default:
      return 'Edit company details and operating regions';
  }
}

String _jobActivityLabel(
    Locale locale,
    ) {
  switch (locale.languageCode) {
    case 'ar':
      return 'نشاط الوظائف';
    case 'de':
      return 'Job-Aktivität';
    default:
      return 'Job activity';
  }
}

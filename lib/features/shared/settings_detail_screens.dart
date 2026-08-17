import 'package:flutter/material.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';

String tr(String key) => AppLanguage.t(key);

// ============================================================================
// SETTINGS PAGE
// ============================================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: child,
      ),
    );
  }
}

// ============================================================================
// UPDATE PROFILE SCREEN
// ============================================================================

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({
    super.key,
    required this.isCompany,
  });

  final bool isCompany;

  @override
  State<UpdateProfileScreen> createState() =>
      _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController name = TextEditingController(
    text: widget.isCompany
        ? 'SunTech Energy Ltd.'
        : 'Aya Inshasi',
  );

  final email = TextEditingController(
    text: 'aya@tototl.com',
  );

  final phone = TextEditingController(
    text: '+970 59 125 4567',
  );

  final location = TextEditingController(
    text: 'Gaza, Palestine',
  );

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: tr('updateProfile'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          30,
        ),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 43,
                  backgroundColor: AppColors.blueBg,
                  child: Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: AppColors.blue,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          _Card(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('personalInfo'),
                    style: _heading,
                  ),

                  const SizedBox(height: 18),

                  _field(
                    tr('fullName'),
                    name,
                    Icons.person_outline_rounded,
                  ),

                  _field(
                    tr('email'),
                    email,
                    Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),

                  _field(
                    tr('phone'),
                    phone,
                    Icons.phone_outlined,
                    type: TextInputType.phone,
                  ),

                  _field(
                    tr('location'),
                    location,
                    Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _SaveButton(
            label: tr('saveChanges'),
            onTap: () {
              if (_form.currentState!.validate()) {
                _message(
                  context,
                  tr('saved'),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType? type,
      }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _label,
          ),

          const SizedBox(height: 7),

          TextFormField(
            controller: controller,
            keyboardType: type,
            validator: (v) {
              if (v == null ||
                  v.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            },
            decoration: _decoration(icon),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHANGE PASSWORD SCREEN
// ============================================================================

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();

  final old = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool show = false;

  @override
  void dispose() {
    old.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: tr('changePassword'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          30,
        ),
        children: [
          _Card(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('security'),
                    style: _heading,
                  ),

                  const SizedBox(height: 9),

                  const Text(
                    'Use at least 8 characters to keep your account secure.',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _passwordField(
                    tr('currentPassword'),
                    old,
                  ),

                  _passwordField(
                    tr('newPassword'),
                    password,
                    isNew: true,
                  ),

                  _passwordField(
                    tr('confirmPassword'),
                    confirm,
                    isConfirm: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _SaveButton(
            label: tr('changePassword'),
            onTap: () {
              if (_form.currentState!.validate()) {
                _message(
                  context,
                  tr('passwordChanged'),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _passwordField(
      String label,
      TextEditingController controller, {
        bool isNew = false,
        bool isConfirm = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _label,
          ),

          const SizedBox(height: 7),

          TextFormField(
            controller: controller,
            obscureText: !show,
            validator: (v) {
              if (v == null ||
                  v.length < 8) {
                return 'Use at least 8 characters';
              }

              if (isConfirm &&
                  v != password.text) {
                return 'Passwords do not match';
              }

              return null;
            },
            decoration:
            _decoration(
              Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  show
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.grey,
                ),
                onPressed: () {
                  setState(() {
                    show = !show;
                  });
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
// LANGUAGE SCREEN
// ============================================================================

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (
          _,
          locale,
          __,
          ) {
        return SettingsPage(
          title: tr('language'),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Card(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('appLanguage'),
                      style: _heading,
                    ),

                    const SizedBox(height: 5),

                    Text(
                      tr('selectLanguage'),
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...const [
                      (
                      'en',
                      'English',
                      '🇬🇧',
                      ),
                      (
                      'ar',
                      'العربية',
                      '🇵🇸',
                      ),
                      (
                      'de',
                      'Deutsch',
                      '🇩🇪',
                      ),
                    ].map(
                          (item) {
                        return RadioListTile<String>(
                          contentPadding:
                          EdgeInsets.zero,
                          value: item.$1,
                          groupValue:
                          locale.languageCode,
                          onChanged: (value) {
                            if (value != null) {
                              AppLanguage.set(
                                value,
                              );
                            }
                          },
                          title: Text(
                            item.$2,
                            style: const TextStyle(
                              color:
                              AppColors.navy,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                          secondary: Text(
                            item.$3,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          activeColor:
                          AppColors.primary,
                        );
                      },
                    ),
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

// ============================================================================
// PRIVACY SCREEN
// ============================================================================

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({
    super.key,
  });

  @override
  State<PrivacyScreen> createState() =>
      _PrivacyScreenState();
}

class _PrivacyScreenState
    extends State<PrivacyScreen> {
  bool publicProfile = true;
  bool showEmail = false;

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: tr('privacy'),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  tr('privacyText'),
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 14),

                _switch(
                  tr('publicProfile'),
                  publicProfile,
                      (value) {
                    setState(() {
                      publicProfile =
                          value;
                    });
                  },
                ),

                const Divider(
                  color:
                  AppColors.cardBorder,
                ),

                _switch(
                  tr('showEmail'),
                  showEmail,
                      (value) {
                    setState(() {
                      showEmail = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(
      String text,
      bool value,
      ValueChanged<bool> change,
      ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        text,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: value,
      activeColor: AppColors.primary,
      onChanged: change,
    );
  }
}

// ============================================================================
// ABOUT SCREEN
// ============================================================================

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: tr('about'),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Card(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration:
                  const BoxDecoration(
                    color:
                    AppColors.blueBg,
                    shape:
                    BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flight_rounded,
                    color: AppColors.blue,
                    size: 35,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'TOTOTL',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 23,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const Text(
                  'I N T G R X',
                  style: TextStyle(
                    color:
                    AppColors.primary,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  tr('aboutText'),
                  textAlign:
                  TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),

                const Padding(
                  padding:
                  EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  child: Divider(
                    color:
                    AppColors.cardBorder,
                  ),
                ),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text(
                      tr('version'),
                      style: _label,
                    ),
                    const Text(
                      '1.0.0',
                      style: TextStyle(
                        color:
                        AppColors.navy,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ],
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
// SHARED STYLES
// ============================================================================

const _heading = TextStyle(
  color: AppColors.navy,
  fontSize: 16,
  fontWeight: FontWeight.w800,
);

const _label = TextStyle(
  color: AppColors.navy,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

InputDecoration _decoration(
    IconData icon,
    ) {
  return InputDecoration(
    prefixIcon: Icon(
      icon,
      color: AppColors.grey,
      size: 20,
    ),
    filled: true,
    fillColor: AppColors.background,
    contentPadding:
    const EdgeInsets.symmetric(
      vertical: 15,
      horizontal: 14,
    ),
    border: OutlineInputBorder(
      borderRadius:
      BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    ),
    enabledBorder:
    OutlineInputBorder(
      borderRadius:
      BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.border,
      ),
    ),
    focusedBorder:
    OutlineInputBorder(
      borderRadius:
      BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.primary,
      ),
    ),
  );
}

// ============================================================================
// CARD
// ============================================================================

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: child,
    );
  }
}

// ============================================================================
// SAVE BUTTON
// ============================================================================

class _SaveButton
    extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 53,
      child: ElevatedButton(
        onPressed: onTap,
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          AppColors.primary,
          foregroundColor:
          Colors.white,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              27,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight:
            FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE
// ============================================================================

void _message(
    BuildContext context,
    String text,
    ) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(text),
      behavior:
      SnackBarBehavior.floating,
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/user_session_storage.dart';
import '../../auth/screens/login/login_screen.dart';
import '../../auth/services/auth_service.dart';

import '../../shared/controllers/logout_controller.dart';
import '../../shared/services/logout_service.dart';
import '../models/admin_account_model.dart';
import '../widgets/admin_ui.dart';

class AdminSettingsScreen
    extends StatefulWidget {
  const AdminSettingsScreen({
    super.key,
  });

  @override
  State<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState
    extends State<AdminSettingsScreen> {
  late final ApiClient _apiClient;
  late final LogoutController
      _logoutController;

  AdminAccountModel _account =
      const AdminAccountModel();

  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    _apiClient =
        ApiClient();

    _logoutController =
        LogoutController(
      LogoutService(
        _apiClient,
      ),
    );

    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final userJson =
        await UserSessionStorage.getUser();

    if (!mounted ||
        userJson == null) {
      return;
    }

    setState(() {
      _account =
          AdminAccountModel.fromJson(
        userJson,
      );
    });
  }

  Future<void> _confirmLogout() async {
    if (_loggingOut) {
      return;
    }

    HapticFeedback.selectionClick();

    final confirmed =
        await showModalBottomSheet<bool>(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (
        sheetContext,
      ) {
        return SafeArea(
          top:
              false,
          child:
              Container(
            margin:
                const EdgeInsets.all(
              12,
            ),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                28,
              ),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width:
                      42,
                  height:
                      4,
                  decoration:
                      BoxDecoration(
                    color:
                        AdminPalette.border,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      20,
                ),

                Container(
                  width:
                      58,
                  height:
                      58,
                  decoration:
                      BoxDecoration(
                    color:
                        AdminPalette.dangerSoft,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.logout_rounded,
                    color:
                        AdminPalette.danger,
                    size:
                        25,
                  ),
                ),

                const SizedBox(
                  height:
                      14,
                ),

                const Text(
                  'Log out of Admin?',
                  style:
                      TextStyle(
                    color:
                        AdminPalette.ink,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height:
                      6,
                ),

                const Text(
                  'Your current admin session will be securely ended.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        AdminPalette.muted,
                    fontSize:
                        11.5,
                    height:
                        1.45,
                  ),
                ),

                const SizedBox(
                  height:
                      19,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton(
                        onPressed:
                            () => Navigator.pop(
                          sheetContext,
                          false,
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              AdminPalette.ink,
                          side:
                              const BorderSide(
                            color:
                                AdminPalette.border,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical:
                                14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'Cancel',
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                          10,
                    ),

                    Expanded(
                      child:
                          FilledButton(
                        onPressed:
                            () => Navigator.pop(
                          sheetContext,
                          true,
                        ),
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              AdminPalette.danger,
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical:
                                14,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'Log out',
                          style:
                              TextStyle(
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

  Future<void> _logout() async {
    if (_loggingOut) {
      return;
    }

    setState(() {
      _loggingOut =
          true;
    });

    final success =
        await _logoutController.logout();

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _loggingOut =
            false;
      });

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              AdminPalette.danger,
          margin:
              const EdgeInsets.all(
            16,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          content:
              Text(
            _logoutController.errorMessage ??
                'Unable to log out.',
          ),
        ),
      );

      return;
    }

    final authController =
        AuthController(
      AuthService(
        ApiClient(),
      ),
    );

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(
          authController:
              authController,
        ),
      ),
      (
        route,
      ) =>
          false,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      children: [
        ListView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            34,
          ),
          children: [
            const AdminPageHeader(
              title:
                  'Admin Settings',
              subtitle:
                  'Account, security and session controls',
            ),

            const SizedBox(
              height:
                  8,
            ),

            _AdminAccountCard(
              account:
                  _account,
            ),

            const SizedBox(
              height:
                  14,
            ),

            AdminSectionCard(
              icon:
                  Icons.security_rounded,
              title:
                  'Administrative Access',
              subtitle:
                  'Current workspace permissions',
              child:
                  const Column(
                children: [
                  AdminInfoRow(
                    label:
                        'Workspace',
                    value:
                        'TOTOTL Admin',
                    icon:
                        Icons.dashboard_customize_outlined,
                  ),
                  AdminInfoRow(
                    label:
                        'Review access',
                    value:
                        'Pilots & Companies',
                    icon:
                        Icons.fact_check_outlined,
                  ),
                  AdminInfoRow(
                    label:
                        'Session security',
                    value:
                        'Bearer token',
                    icon:
                        Icons.key_rounded,
                    last:
                        true,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height:
                  14,
            ),

            _LogoutCard(
              onTap:
                  _confirmLogout,
            ),
          ],
        ),

        if (_loggingOut)
          const Positioned.fill(
            child:
                _AdminLogoutLoading(),
          ),
      ],
    );
  }
}

class _AdminAccountCard
    extends StatelessWidget {
  const _AdminAccountCard({
    required this.account,
  });

  final AdminAccountModel account;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          27,
        ),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(
              0xFF092D43,
            ),
            Color(
              0xFF0A5969,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AdminPalette.navy
                    .withOpacity(
              0.16,
            ),
            blurRadius:
                26,
            offset:
                const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child:
          Row(
        children: [
          Container(
            width:
                64,
            height:
                64,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                21,
              ),
            ),
            child:
                Text(
              AdminFormat.initials(
                account.displayName,
                fallback:
                    'AD',
              ),
              style:
                  const TextStyle(
                color:
                    AdminPalette.tealDark,
                fontSize:
                    20,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(
            width:
                13,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height:
                      4,
                ),

                Text(
                  account.email.trim().isEmpty
                      ? account.displayUsername
                      : account.email,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        Colors.white.withOpacity(
                      0.68,
                    ),
                    fontSize:
                        10.5,
                  ),
                ),

                const SizedBox(
                  height:
                      9,
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        9,
                    vertical:
                        5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withOpacity(
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                  child:
                      const Text(
                    'ADMINISTRATOR',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFFB9F5F2,
                      ),
                      fontSize:
                          8.5,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing:
                          0.7,
                    ),
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

class _LogoutCard
    extends StatelessWidget {
  const _LogoutCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        child:
            Container(
          padding:
              const EdgeInsets.all(
            16,
          ),
          decoration:
              BoxDecoration(
            border:
                Border.all(
              color:
                  AdminPalette.border,
            ),
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),
          child:
              Row(
            children: [
              Container(
                width:
                    44,
                height:
                    44,
                decoration:
                    BoxDecoration(
                  color:
                      AdminPalette.dangerSoft,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  Icons.logout_rounded,
                  color:
                      AdminPalette.danger,
                  size:
                      20,
                ),
              ),

              const SizedBox(
                width:
                    12,
              ),

              const Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log out',
                      style:
                          TextStyle(
                        color:
                            AdminPalette.danger,
                        fontSize:
                            13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      'Securely end this admin session',
                      style:
                          TextStyle(
                        color:
                            AdminPalette.muted,
                        fontSize:
                            9.8,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color:
                    Color(
                  0xFFE5A0A0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminLogoutLoading
    extends StatelessWidget {
  const _AdminLogoutLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.black12,
      child:
          Center(
        child:
            Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                20,
            vertical:
                16,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          child:
              const Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              SizedBox(
                width:
                    20,
                height:
                    20,
                child:
                    CircularProgressIndicator(
                  strokeWidth:
                      2.2,
                  color:
                      AdminPalette.tealDark,
                ),
              ),
              SizedBox(
                width:
                    11,
              ),
              Text(
                'Signing out...',
                style:
                    TextStyle(
                  color:
                      AdminPalette.ink,
                  fontSize:
                      12,
                  fontWeight:
                      FontWeight.w700,
                  decoration:
                      TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

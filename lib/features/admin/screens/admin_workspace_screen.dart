import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';

import '../../auth/controllers/auth_controller.dart';
 import '../../auth/controllers/user_session_storage.dart';
import '../../auth/screens/login/login_screen.dart';
import '../../auth/services/auth_service.dart';

import '../../shared/controllers/logout_controller.dart';
import '../../shared/services/logout_service.dart';
import '../widgets/admin_design.dart';

class AdminWorkspaceScreen extends StatefulWidget {
  const AdminWorkspaceScreen({
    super.key,
  });

  @override
  State<AdminWorkspaceScreen> createState() =>
      _AdminWorkspaceScreenState();
}

class _AdminWorkspaceScreenState
    extends State<AdminWorkspaceScreen> {
  late final ApiClient _apiClient;
  late final LogoutController _logoutController;
  late final AuthController _authController;

  Map<String, dynamic>? _user;

  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient();

    _logoutController = LogoutController(
      LogoutService(
        _apiClient,
      ),
    );

    _authController = AuthController(
      AuthService(
        _apiClient,
      ),
    );

    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final user =
        await UserSessionStorage.getUser();

    if (!mounted) return;

    setState(() {
      _user =
          user;
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
      isScrollControlled:
          true,
      builder:
          (sheetContext) {
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
                        AdminColors.border,
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
                      60,
                  height:
                      60,
                  decoration:
                      BoxDecoration(
                    color:
                        AdminColors.dangerSoft,
                    borderRadius:
                        BorderRadius.circular(
                      19,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.logout_rounded,
                    color:
                        AdminColors.danger,
                    size:
                        26,
                  ),
                ),

                const SizedBox(
                  height:
                      14,
                ),

                const Text(
                  'Log out of Admin?',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        AdminColors.ink,
                    fontSize:
                        19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height:
                      7,
                ),

                const Text(
                  'Your current administrative session will end and you will return to the sign-in screen.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        AdminColors.muted,
                    fontSize:
                        11.5,
                    height:
                        1.5,
                  ),
                ),

                const SizedBox(
                  height:
                      20,
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
                              AdminColors.ink,
                          side:
                              const BorderSide(
                            color:
                                AdminColors.border,
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
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width:
                          10,
                    ),

                    Expanded(
                      child:
                          FilledButton.icon(
                        onPressed:
                            () => Navigator.pop(
                          sheetContext,
                          true,
                        ),
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              AdminColors.danger,
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
                        icon:
                            const Icon(
                          Icons.logout_rounded,
                          size:
                              17,
                        ),
                        label:
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
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
                SnackBarBehavior.floating,
            backgroundColor:
                AdminColors.danger,
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
                  'Unable to sign out.',
            ),
          ),
        );

      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(
          authController:
              _authController,
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
    final name =
        _user?['name']
                ?.toString()
                .trim() ??
            '';

    final email =
        _user?['email']
                ?.toString()
                .trim() ??
            '';

    final username =
        _user?['username']
                ?.toString()
                .trim() ??
            '';

    final phone =
        _user?['phone']
                ?.toString()
                .trim() ??
            '';

    final status =
        _user?['status']
                ?.toString()
                .trim() ??
            '';

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
            const AdminPageTitle(
              title:
                  'Workspace',
              subtitle:
                  'Admin account, access and session controls',
            ),

            const SizedBox(
              height:
                  8,
            ),

            _AdminHero(
              name:
                  name,
              email:
                  email,
              username:
                  username,
            ),

            const SizedBox(
              height:
                  14,
            ),

            AdminSectionCard(
              icon:
                  Icons.person_outline_rounded,
              title:
                  'Admin Account',
              subtitle:
                  'Current signed-in administrator',
              child:
                  Column(
                children: [
                  AdminInfoRow(
                    label:
                        'Name',
                    value:
                        name,
                    icon:
                        Icons.badge_outlined,
                  ),
                  AdminInfoRow(
                    label:
                        'Username',
                    value:
                        username,
                    icon:
                        Icons.alternate_email_rounded,
                  ),
                  AdminInfoRow(
                    label:
                        'Email',
                    value:
                        email,
                    icon:
                        Icons.mail_outline_rounded,
                  ),
                  AdminInfoRow(
                    label:
                        'Phone',
                    value:
                        phone,
                    icon:
                        Icons.phone_outlined,
                  ),
                  AdminInfoRow(
                    label:
                        'Status',
                    value:
                        status,
                    icon:
                        Icons.shield_outlined,
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

            const AdminSectionCard(
              icon:
                  Icons.admin_panel_settings_outlined,
              title:
                  'Administrative Access',
              subtitle:
                  'Connected platform capabilities',
              child:
                  Column(
                children: [
                  AdminInfoRow(
                    label:
                        'Review accounts',
                    value:
                        'Pilots & Companies',
                    icon:
                        Icons.fact_check_outlined,
                  ),
                  AdminInfoRow(
                    label:
                        'Verification',
                    value:
                        'Approve / Reject',
                    icon:
                        Icons.verified_user_outlined,
                  ),
                  AdminInfoRow(
                    label:
                        'Lifecycle',
                    value:
                        'Suspend / Reactivate',
                    icon:
                        Icons.autorenew_rounded,
                  ),
                  AdminInfoRow(
                    label:
                        'Audit trail',
                    value:
                        'Verification History',
                    icon:
                        Icons.history_rounded,
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

            _SecurityCard(
              onLogout:
                  _confirmLogout,
            ),
          ],
        ),

        if (_loggingOut)
          const Positioned.fill(
            child:
                _LogoutOverlay(),
          ),
      ],
    );
  }
}

class _AdminHero
    extends StatelessWidget {
  const _AdminHero({
    required this.name,
    required this.email,
    required this.username,
  });

  final String name;
  final String email;
  final String username;

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayName =
        name.isEmpty
            ? 'Administrator'
            : name;

    final secondary =
        email.isNotEmpty
            ? email
            : username;

    return Container(
      constraints:
          const BoxConstraints(
        minHeight:
            154,
      ),
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          29,
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
              0xFF0A6070,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AdminColors.navy
                    .withOpacity(
              0.18,
            ),
            blurRadius:
                28,
            offset:
                const Offset(
              0,
              11,
            ),
          ),
        ],
      ),
      child:
          Row(
        children: [
          Container(
            width:
                70,
            height:
                70,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                23,
              ),
            ),
            child:
                Text(
              adminInitials(
                displayName,
              ),
              style:
                  const TextStyle(
                color:
                    AdminColors.tealDark,
                fontSize:
                    21,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(
            width:
                14,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'ADMIN WORKSPACE',
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
                        0.8,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Text(
                  displayName,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height:
                      5,
                ),
                Text(
                  secondary.isEmpty
                      ? 'TOTOTL INTGRX Administrator'
                      : secondary,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        Colors.white
                            .withOpacity(
                      0.66,
                    ),
                    fontSize:
                        10.3,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width:
                44,
            height:
                44,
            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child:
                const Icon(
              Icons.shield_rounded,
              color:
                  Color(
                0xFF98EFEB,
              ),
              size:
                  21,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard
    extends StatelessWidget {
  const _SecurityCard({
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border:
            Border.all(
          color:
              AdminColors.border,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Session & Security',
            style:
                TextStyle(
              color:
                  AdminColors.ink,
              fontSize:
                  14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height:
                4,
          ),
          const Text(
            'Securely manage the current administrator session.',
            style:
                TextStyle(
              color:
                  AdminColors.muted,
              fontSize:
                  9.8,
            ),
          ),
          const SizedBox(
            height:
                14,
          ),
          Material(
            color:
                AdminColors.dangerSoft,
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            child:
                InkWell(
              onTap:
                  onLogout,
              borderRadius:
                  BorderRadius.circular(
                17,
              ),
              child:
                  const Padding(
                padding:
                    EdgeInsets.all(
                  14,
                ),
                child:
                    Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color:
                          AdminColors.danger,
                      size:
                          20,
                    ),
                    SizedBox(
                      width:
                          11,
                    ),
                    Expanded(
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
                                  AdminColors.danger,
                              fontSize:
                                  12.5,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          SizedBox(
                            height:
                                3,
                          ),
                          Text(
                            'End this admin session securely',
                            style:
                                TextStyle(
                              color:
                                  AdminColors.muted,
                              fontSize:
                                  9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color:
                          Color(
                        0xFFE9A4A4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutOverlay
    extends StatelessWidget {
  const _LogoutOverlay();

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
          constraints:
              const BoxConstraints(
            maxWidth:
                230,
          ),
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
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.08,
                ),
                blurRadius:
                    20,
                offset:
                    const Offset(
                  0,
                  8,
                ),
              ),
            ],
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
                      AdminColors.tealDark,
                ),
              ),
              SizedBox(
                width:
                    11,
              ),
              Flexible(
                child:
                    Text(
                  'Signing out...',
                  style:
                      TextStyle(
                    color:
                        AdminColors.ink,
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.w700,
                    decoration:
                        TextDecoration.none,
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

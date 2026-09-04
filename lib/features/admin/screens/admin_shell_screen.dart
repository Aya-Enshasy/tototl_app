import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';

import '../controllers/admin_controller.dart';
import '../services/admin_service.dart';
import '../widgets/admin_design.dart';

import 'admin_accounts_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_workspace_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({
    super.key,
  });

  @override
  State<AdminShellScreen> createState() =>
      _AdminShellScreenState();
}

class _AdminShellScreenState
    extends State<AdminShellScreen> {
  late final AdminController _controller;

  int _index = 0;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark,
        statusBarBrightness:
            Brightness.light,
      ),
    );

    _controller =
        AdminController(
      AdminService(
        ApiClient(),
      ),
    );

    _load();
  }

  Future<void> _load() async {
    await _controller.loadDashboard();

    if (!mounted) return;

    setState(() {
      _initialLoading =
          false;
    });
  }

  Future<void> _refresh() async {
    await _controller.refresh();

    if (!mounted) return;

    setState(() {});
  }

  void _select(
    int index,
  ) {
    if (_index == index) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _index =
          index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_initialLoading) {
      return const _AdminBootScreen();
    }

    final pages =
        <Widget>[
      AdminDashboardScreen(
        controller:
            _controller,
        onRefresh:
            _refresh,
        onReviews:
            () => _select(1),
        onAccounts:
            () => _select(2),
      ),

      AdminReviewsScreen(
        controller:
            _controller,
        onRefresh:
            _refresh,
      ),

      AdminAccountsScreen(
        controller:
            _controller,
        onRefresh:
            _refresh,
      ),

      const AdminWorkspaceScreen(),
    ];

    return Scaffold(
      backgroundColor:
          AdminColors.bg,
      body:
          SafeArea(
        bottom:
            false,
        child:
            IndexedStack(
          index:
              _index,
          children:
              pages,
        ),
      ),
      bottomNavigationBar:
          _AdminBottomBar(
        index:
            _index,
        pendingCount:
            _controller.totalPending,
        accountCount:
            _controller.knownAccounts.length,
        onSelected:
            _select,
      ),
    );
  }
}

class _AdminBottomBar
    extends StatelessWidget {
  const _AdminBottomBar({
    required this.index,
    required this.pendingCount,
    required this.accountCount,
    required this.onSelected,
  });

  final int index;
  final int pendingCount;
  final int accountCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      top:
          false,
      child:
          Container(
        margin:
            const EdgeInsets.fromLTRB(
          14,
          6,
          14,
          10,
        ),
        padding:
            const EdgeInsets.all(
          6,
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
          boxShadow: [
            BoxShadow(
              color:
                  AdminColors.ink
                      .withOpacity(
                0.08,
              ),
              blurRadius:
                  24,
              offset:
                  const Offset(
                0,
                9,
              ),
            ),
          ],
        ),
        child:
            Row(
          children: [
            Expanded(
              child:
                  _NavItem(
                icon:
                    Icons.home_rounded,
                label:
                    'Home',
                selected:
                    index == 0,
                onTap:
                    () => onSelected(0),
              ),
            ),

            Expanded(
              child:
                  _NavItem(
                icon:
                    Icons.fact_check_outlined,
                label:
                    'Reviews',
                badge:
                    pendingCount,
                selected:
                    index == 1,
                onTap:
                    () => onSelected(1),
              ),
            ),

            Expanded(
              child:
                  _NavItem(
                icon:
                    Icons.manage_accounts_rounded,
                label:
                    'Accounts',
                badge:
                    accountCount,
                selected:
                    index == 2,
                onTap:
                    () => onSelected(2),
              ),
            ),

            Expanded(
              child:
                  _NavItem(
                icon:
                    Icons.dashboard_customize_outlined,
                label:
                    'Workspace',
                selected:
                    index == 3,
                onTap:
                    () => onSelected(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem
    extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          selected
              ? AdminColors.tealSoft
              : Colors.transparent,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                9,
            horizontal:
                4,
          ),
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  Icon(
                    icon,
                    color:
                        selected
                            ? AdminColors.tealDark
                            : AdminColors.muted2,
                    size:
                        20,
                  ),
                  if (badge > 0)
                    Positioned(
                      right:
                          -9,
                      top:
                          -7,
                      child:
                          Container(
                        constraints:
                            const BoxConstraints(
                          minWidth:
                              17,
                          minHeight:
                              17,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              4,
                        ),
                        alignment:
                            Alignment.center,
                        decoration:
                            const BoxDecoration(
                          color:
                              AdminColors.danger,
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            Text(
                          badge > 99
                              ? '99+'
                              : '$badge',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                7.4,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height:
                    4,
              ),
              FittedBox(
                fit:
                    BoxFit.scaleDown,
                child:
                    Text(
                  label,
                  maxLines:
                      1,
                  style:
                      TextStyle(
                    color:
                        selected
                            ? AdminColors.tealDark
                            : AdminColors.muted,
                    fontSize:
                        8.7,
                    fontWeight:
                        selected
                            ? FontWeight.w900
                            : FontWeight.w600,
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

class _AdminBootScreen
    extends StatelessWidget {
  const _AdminBootScreen();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AdminColors.bg,
      body:
          SafeArea(
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),
          child:
              Column(
            children: [
              Container(
                height:
                    190,
                width:
                    double.infinity,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                  gradient:
                      const LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                    colors: [
                      Color(
                        0xFF071F34,
                      ),
                      Color(
                        0xFF0A6070,
                      ),
                    ],
                  ),
                ),
                child:
                    const Center(
                  child:
                      Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color:
                            Color(
                          0xFFB5F4F1,
                        ),
                        size:
                            40,
                      ),
                      SizedBox(
                        height:
                            11,
                      ),
                      Text(
                        'Admin Control Center',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      SizedBox(
                        height:
                            5,
                      ),
                      Text(
                        'Preparing your workspace...',
                        style:
                            TextStyle(
                          color:
                              Colors.white70,
                          fontSize:
                              10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(
                child:
                    Center(
                  child:
                      SizedBox(
                    width:
                        25,
                    height:
                        25,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2.4,
                      color:
                          AdminColors.tealDark,
                    ),
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

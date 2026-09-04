import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';
import '../services/admin_service.dart';
import '../widgets/admin_ui.dart';

import 'admin_dashboard_screen.dart';
import 'admin_settings_screen.dart';
import 'company_review_screen.dart';
import 'pending_companies_screen.dart';
import 'pending_pilots_screen.dart';
import 'pilot_review_screen.dart';

// ============================================================================
// ADMIN SHELL
// ============================================================================

class AdminShellScreen
    extends StatefulWidget {
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
        statusBarColor:
            Colors.transparent,
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
    await _controller.loadAll();

    if (!mounted) {
      return;
    }

    setState(() {
      _initialLoading =
          false;
    });
  }

  Future<void> _refresh() async {
    await _controller.refreshAll();

    if (!mounted) {
      return;
    }

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

  void _openPilot(
    AdminPendingPilotModel pilot,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PilotReviewScreen(
          pilot:
              pilot,
        ),
      ),
    );
  }

  void _openCompany(
    AdminPendingCompanyModel company,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CompanyReviewScreen(
          company:
              company,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_initialLoading) {
      return const _AdminStartupScreen();
    }

    final pages =
        <Widget>[
      AdminDashboardScreen(
        controller:
            _controller,
        onRefresh:
            _refresh,
        onOpenPilots:
            () => _select(1),
        onOpenCompanies:
            () => _select(2),
        onOpenPilot:
            _openPilot,
        onOpenCompany:
            _openCompany,
      ),

      PendingPilotsScreen(
        controller:
            _controller,
        onRefresh:
            _refresh,
      ),

      PendingCompaniesScreen(
        controller:
            _controller,
        onRefresh:
            _refresh,
      ),

      const AdminSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor:
          AdminPalette.bg,
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
        pilotCount:
            _controller.pendingPilotCount,
        companyCount:
            _controller.pendingCompanyCount,
        onSelected:
            _select,
      ),
    );
  }
}

// ============================================================================
// BOTTOM BAR
// ============================================================================

class _AdminBottomBar
    extends StatelessWidget {
  const _AdminBottomBar({
    required this.index,
    required this.pilotCount,
    required this.companyCount,
    required this.onSelected,
  });

  final int index;
  final int pilotCount;
  final int companyCount;
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
                AdminPalette.border,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AdminPalette.ink
                      .withOpacity(
                0.07,
              ),
              blurRadius:
                  22,
              offset:
                  const Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child:
            Row(
          children: [
            Expanded(
              child:
                  _BottomItem(
                icon:
                    Icons.dashboard_rounded,
                label:
                    'Overview',
                selected:
                    index == 0,
                onTap:
                    () => onSelected(0),
              ),
            ),

            Expanded(
              child:
                  _BottomItem(
                icon:
                    Icons.flight_takeoff_rounded,
                label:
                    'Pilots',
                badge:
                    pilotCount,
                selected:
                    index == 1,
                onTap:
                    () => onSelected(1),
              ),
            ),

            Expanded(
              child:
                  _BottomItem(
                icon:
                    Icons.apartment_rounded,
                label:
                    'Companies',
                badge:
                    companyCount,
                selected:
                    index == 2,
                onTap:
                    () => onSelected(2),
              ),
            ),

            Expanded(
              child:
                  _BottomItem(
                icon:
                    Icons.settings_outlined,
                label:
                    'Settings',
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

class _BottomItem
    extends StatelessWidget {
  const _BottomItem({
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
              ? AdminPalette.tealSoft
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
                            ? AdminPalette.tealDark
                            : AdminPalette.muted2,
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
                              AdminPalette.danger,
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
                                7.5,
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
                            ? AdminPalette.tealDark
                            : AdminPalette.muted,
                    fontSize:
                        8.8,
                    fontWeight:
                        selected
                            ? FontWeight.w800
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

// ============================================================================
// STARTUP
// ============================================================================

class _AdminStartupScreen
    extends StatelessWidget {
  const _AdminStartupScreen();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AdminPalette.bg,
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
                    180,
                width:
                    double.infinity,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    28,
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
                            38,
                      ),
                      SizedBox(
                        height:
                            10,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height:
                    18,
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
                          AdminPalette.tealDark,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/pilot/controllers/pilot_home_controller.dart';
import 'package:tototl_app/features/pilot/models/pilot_home_snapshot.dart';
import 'package:tototl_app/features/pilot/screens/applications/application_details_screen.dart';
import 'package:tototl_app/features/pilot/screens/applications/applications_screen.dart';
import 'package:tototl_app/features/pilot/screens/home/widgets/home_header.dart';
import 'package:tototl_app/features/pilot/screens/home/widgets/my_drone_card.dart';
import 'package:tototl_app/features/pilot/screens/home/widgets/recent_applications_section.dart';
import 'package:tototl_app/features/pilot/screens/jobs/jobs_screen.dart';
import 'package:tototl_app/features/pilot/services/pilot_application_service.dart';

import '../../../services/drone_service.dart';
import '../../drones/my_drones_screen.dart';
import '../../notification/NotificationsScreen.dart';
import '../../contract/pilot_contracts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PilotHomeController _controller;
  late final ApiClient _apiClient;
  late final AnimationController _entranceController;

  bool _initialHydrationComplete = false;
  bool _refreshing = false;

  String _pilotName = 'Pilot';
  String _pilotPhoto = '';
  bool _pilotVerified = false;

  _PilotDashboardSnapshot _dashboard =
  const _PilotDashboardSnapshot();
  String? _dashboardError;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient();

    _controller = PilotHomeController(
      applicationService: PilotApplicationService(_apiClient),
      droneService: DroneService(_apiClient),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );

    unawaited(_hydrateInitialHome());
  }

  @override
  void dispose() {
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _hydrateInitialHome() async {
    // Keep the real Home completely hidden until the first authoritative
    // hydration pass is done. This prevents header/fleet/applications/contracts
    // from "popping in" after the page is already visible.
    await Future.wait<void>([
      _loadPilotIdentity(notify: false),
      _controller.bootstrap(),
      _loadDashboard(notify: false),
    ]);

    // PilotHomeController is local-first: when cache exists bootstrap() starts
    // its network refresh in the background. Wait for that refresh too.
    await _waitForHomeControllerIdle();

    await _precacheInitialImages();

    if (!mounted) return;

    setState(() {
      _initialHydrationComplete = true;
    });

    _entranceController.forward(from: 0);
  }

  Future<void> _waitForHomeControllerIdle() async {
    final deadline = DateTime.now().add(
      const Duration(seconds: 12),
    );

    while (mounted &&
        DateTime.now().isBefore(deadline) &&
        (_controller.isRefreshing ||
            _controller.isDronesInitialLoading ||
            _controller.isApplicationsInitialLoading)) {
      await Future<void>.delayed(
        const Duration(milliseconds: 45),
      );
    }
  }

  Future<void> _loadPilotIdentity({
    required bool notify,
  }) async {
    try {
      final profile = await UserSessionStorage.getProfile();
      final status = await UserSessionStorage.getStatus();
      final storedPhoto =
      await UserSessionStorage.getProfilePhotoUrl();

      final name = profile?['name']?.toString().trim() ?? '';
      final directPhoto =
          profile?['profile_photo']?.toString().trim() ?? '';
      final alternatePhoto =
          profile?['profile_photo_url']?.toString().trim() ?? '';

      final normalizedStatus =
          status?.toString().trim().toLowerCase() ?? '';

      _pilotName = name.isEmpty ? 'Pilot' : name;
      _pilotPhoto = directPhoto.isNotEmpty
          ? directPhoto
          : (alternatePhoto.isNotEmpty
          ? alternatePhoto
          : (storedPhoto?.trim() ?? ''));

      _pilotVerified = normalizedStatus == 'active' ||
          normalizedStatus == 'approved' ||
          normalizedStatus == 'verified';

      if (notify && mounted) {
        setState(() {});
      }
    } catch (_) {
      // Session identity failure should not block the Home.
    }
  }

  Future<void> _loadDashboard({
    required bool notify,
  }) async {
    try {
      final response =
      await _apiClient.get('/dashboard');

      final raw = response.data;

      if (raw is! Map) {
        throw StateError(
          'Invalid dashboard response.',
        );
      }

      final body =
      Map<String, dynamic>.from(raw);

      if (body['success'] != true) {
        final message =
            body['message']?.toString().trim() ?? '';

        throw StateError(
          message.isEmpty
              ? 'Unable to load dashboard.'
              : message,
        );
      }

      final rawData = body['data'];

      if (rawData is! Map) {
        throw StateError(
          'Dashboard data is missing.',
        );
      }

      _dashboard =
          _PilotDashboardSnapshot.fromJson(
            Map<String, dynamic>.from(rawData),
          );

      _dashboardError = null;

      if (notify && mounted) {
        setState(() {});
      }
    } catch (e) {
      _dashboardError = e.toString();

      if (notify && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _precacheInitialImages() async {
    if (!mounted) return;

    final snapshot =
        _controller.snapshot ?? const PilotHomeSnapshot();

    final urls = <String>{
      if (_pilotPhoto.trim().isNotEmpty) _pilotPhoto.trim(),
      ...snapshot.drones
          .take(2)
          .map((item) => item.imageUrl.trim())
          .where((url) => url.isNotEmpty),
      ...snapshot.applications
          .take(3)
          .map((item) => item.companyPhoto.trim())
          .where((url) => url.isNotEmpty),
    };

    await Future.wait(
      urls.map((url) async {
        try {
          await precacheImage(
            NetworkImage(url),
            context,
          );
        } catch (_) {
          // Normal image fallbacks remain available.
        }
      }),
    );
  }

  Future<void> _refreshHome() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);

    try {
      await Future.wait<void>([
        _controller.forceRefresh(),
        _loadDashboard(notify: false),
        _loadPilotIdentity(notify: false),
      ]);

      await _waitForHomeControllerIdle();
      await _precacheInitialImages();
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Widget _entry({
    required int index,
    required Widget child,
  }) {
    final start =
    (index * .055).clamp(0.0, .32).toDouble();
    final end =
    (start + .48).clamp(0.0, 1.0).toDouble();

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .018),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Future<void> _openFleet() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MyDronesScreen(),
      ),
    );

    if (mounted) {
      unawaited(_refreshHome());
    }
  }

  Future<void> _openApplications() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ApplicationsScreen(),
      ),
    );

    if (mounted) {
      unawaited(_refreshHome());
    }
  }

  Future<void> _openJobs() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FindDroneJobsScreen(),
      ),
    );

    if (mounted) {
      unawaited(_refreshHome());
    }
  }

  Future<void> _openContracts() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PilotContractsScreen(),
      ),
    );

    if (mounted) {
      unawaited(_refreshHome());
    }
  }

  Future<void> _openApplication(
      PilotHomeApplicationItem application,
      ) async {
    final detailsFuture = _controller.applicationService
        .getApplicationDetailsResult(application.id);

    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicationDetailsScreen(
          applicationId: application.id,
          detailsFuture: detailsFuture,
        ),
      ),
    );

    if (mounted) {
      unawaited(_refreshHome());
    }
  }

  Future<void> _openNotifications() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PilotNotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      body: Stack(
        children: [
          const _PilotHomeBackground(),
          SafeArea(
            child: !_initialHydrationComplete
                ? const _PilotHomeInitialShimmer()
                : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final snapshot = _controller.snapshot ??
                    const PilotHomeSnapshot();

                return RefreshIndicator(
                  color:
                  _PilotHomePalette.teal,
                  onRefresh: _refreshHome,
                  child: ListView(
                    physics:
                    const AlwaysScrollableScrollPhysics(
                      parent:
                      BouncingScrollPhysics(),
                    ),
                    padding:
                    const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      110,
                    ),
                    children: [
                      _entry(
                        index: 0,
                        child: HomeHeader(
                          name: _pilotName,
                          photoUrl:
                          _pilotPhoto,
                          verified:
                          _pilotVerified,
                          onNotificationsTap:
                          _openNotifications,
                        ),
                      ),
                      const SizedBox(
                          height: 11),

                      if (_dashboard
                          .awaitingMyAction >
                          0) ...[
                        _entry(
                          index: 1,
                          child:
                          _PilotNextStepSummaryCard(
                            count: _dashboard
                                .awaitingMyAction,
                            onTap:
                            _openContracts,
                          ),
                        ),
                        const SizedBox(
                            height: 10),
                      ],

                      _entry(
                        index: 2,
                        child:
                        _ExploreJobsCard(
                          onTap: _openJobs,
                        ),
                      ),

                      const SizedBox(
                          height: 10),
                      _entry(
                        index: 3,
                        child:
                        _PilotMissionActivityCard(
                          dashboard:
                          _dashboard,
                          onTap:
                          _openContracts,
                        ),
                      ),

                      const SizedBox(
                          height: 10),
                      _entry(
                        index: 4,
                        child: MyDroneCard(
                          drones:
                          snapshot.drones,
                          loading: false,
                          errorMessage:
                          !_controller
                              .hasDronesSnapshot
                              ? _controller
                              .dronesError
                              : null,
                          onRetry:
                          _refreshHome,
                          onOpenFleet:
                          _openFleet,
                        ),
                      ),

                      const SizedBox(
                          height: 10),
                      _entry(
                        index: 5,
                        child:
                        RecentApplicationsSection(
                          applications:
                          snapshot
                              .applications,
                          loading: false,
                          errorMessage:
                          !_controller
                              .hasApplicationsSnapshot
                              ? _controller
                              .applicationsError
                              : null,
                          onRetry:
                          _refreshHome,
                          onSeeAll:
                          _openApplications,
                          onExploreJobs:
                          _openJobs,
                          onOpenApplication:
                          _openApplication,
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),
          ),
          if (_refreshing &&
              _initialHydrationComplete)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child:
              LinearProgressIndicator(
                minHeight: 1.5,
                color:
                _PilotHomePalette.teal,
                backgroundColor:
                Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}


class _PilotNextStepSummaryCard
    extends StatelessWidget {
  const _PilotNextStepSummaryCard({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        11,
        12,
        11,
      ),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBF1),
            Color(0xFFFFF7E8),
          ],
        ),
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          const Color(0xFFFFDDA3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                      0xFFFFF1CF),
                  borderRadius:
                  BorderRadius.circular(
                      11),
                ),
                child: const Icon(
                  Icons
                      .description_outlined,
                  color:
                  Color(0xFFF08A16),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next step',
                      style: TextStyle(
                        color:
                        Color(0xFFD9790D),
                        fontSize: 8.7,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Review contract',
                      style: TextStyle(
                        color:
                        _PilotHomePalette
                            .navy,
                        fontSize: 12.8,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                      0xFFE7F8F3),
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
                child: Text(
                  count == 1
                      ? '1 waiting'
                      : '$count waiting',
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF0A987E),
                    fontSize: 8.6,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: FilledButton(
              onPressed: onTap,
              style:
              FilledButton.styleFrom(
                elevation: 0,
                backgroundColor:
                _PilotHomePalette.teal,
                foregroundColor:
                Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                      10),
                ),
              ),
              child: const Text(
                'Review contract',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PilotMissionActivityCard
    extends StatelessWidget {
  const _PilotMissionActivityCard({
    required this.dashboard,
    required this.onTap,
  });

  final _PilotDashboardSnapshot dashboard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeCount =
        dashboard.activeMissionCount;

    final hasActive =
        activeCount > 0;

    final title = hasActive
        ? 'Active mission'
        : 'Mission activity';

    final primaryText = hasActive
        ? activeCount == 1
        ? '1 mission is active'
        : '$activeCount missions are active'
        : 'No active mission right now';

    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(17),
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(
            11,
            10,
            10,
            11,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(17),
            border: Border.all(
              color:
              _PilotHomePalette.border,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration:
                    BoxDecoration(
                      color:
                      _PilotHomePalette
                          .tealSoft,
                      borderRadius:
                      BorderRadius.circular(
                          9),
                    ),
                    child: Icon(
                      hasActive
                          ? Icons
                          .flight_takeoff_rounded
                          : Icons
                          .task_alt_rounded,
                      color:
                      _PilotHomePalette
                          .tealDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style:
                      const TextStyle(
                        color:
                        _PilotHomePalette
                            .navy,
                        fontSize: 11.5,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                  const Text(
                    'View all',
                    style: TextStyle(
                      color:
                      _PilotHomePalette
                          .tealDark,
                      fontSize: 8.9,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.fromLTRB(
                  10,
                  9,
                  9,
                  9,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                      0xFFF6FAFB),
                  borderRadius:
                  BorderRadius.circular(
                      11),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            primaryText,
                            style:
                            const TextStyle(
                              color:
                              _PilotHomePalette
                                  .navy,
                              fontSize: 10.4,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                          const SizedBox(
                              height: 3),
                          Text(
                            _secondaryMissionText(
                              dashboard,
                            ),
                            style:
                            const TextStyle(
                              color:
                              _PilotHomePalette
                                  .muted,
                              fontSize: 8.8,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration:
                      const BoxDecoration(
                        color:
                        _PilotHomePalette
                            .tealSoft,
                        shape:
                        BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .chevron_right_rounded,
                        color:
                        _PilotHomePalette
                            .tealDark,
                        size: 18,
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

  String _secondaryMissionText(
      _PilotDashboardSnapshot dashboard,
      ) {
    final parts = <String>[];

    if (dashboard.completed > 0) {
      parts.add(
        dashboard.completed == 1
            ? '1 completed mission'
            : '${dashboard.completed} completed missions',
      );
    }

    if (dashboard.pendingReleaseTotal > 0) {
      parts.add(
        '${_compactNumber(dashboard.pendingReleaseTotal)} pending release',
      );
    }

    if (parts.isEmpty) {
      return 'Contracts and mission progress will appear here.';
    }

    return parts.join('  ·  ');
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.contract,
    required this.application,
    required this.onTap,
  });

  final _HomeContractSnapshot contract;
  final PilotHomeApplicationItem? application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final jobTitle =
        application?.jobTitle.trim() ?? '';
    final company =
        application?.company.trim() ?? '';
    final location =
        application?.location.trim() ?? '';
    final applicationStatusLabel =
        application?.statusLabel.trim() ?? '';

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        12,
        11,
        12,
        11,
      ),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBF1),
            Color(0xFFFFF7E8),
          ],
        ),
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          const Color(0xFFFFDDA3),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFFFF1CF),
                  borderRadius:
                  BorderRadius.circular(
                      11),
                ),
                child: const Icon(
                  Icons
                      .description_outlined,
                  color:
                  Color(0xFFF08A16),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                                0xFFFFEBC3),
                            borderRadius:
                            BorderRadius
                                .circular(20),
                          ),
                          child:
                          const Text(
                            'Next step',
                            style:
                            TextStyle(
                              color:
                              Color(
                                  0xFFD9790D),
                              fontSize: 8.7,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                                0xFFE7F8F3),
                            borderRadius:
                            BorderRadius
                                .circular(20),
                          ),
                          child: Text(
                            applicationStatusLabel.isNotEmpty
                                ? applicationStatusLabel
                                : 'Pending',
                            style:
                            const TextStyle(
                              color:
                              Color(
                                  0xFF0A987E),
                              fontSize: 8.6,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review contract',
                      style: TextStyle(
                        color:
                        _PilotHomePalette
                            .navy,
                        fontSize: 13,
                        height: 1.05,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    if (jobTitle.isNotEmpty ||
                        company.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (jobTitle
                              .isNotEmpty)
                            jobTitle,
                          if (company
                              .isNotEmpty)
                            company,
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          color:
                          _PilotHomePalette
                              .muted,
                          fontSize: 9.7,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (location.isNotEmpty ||
              contract.startDate !=
                  null) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                if (location
                    .isNotEmpty) ...[
                  const Icon(
                    Icons
                        .location_on_outlined,
                    size: 13,
                    color:
                    _PilotHomePalette
                        .muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        _PilotHomePalette
                            .muted,
                        fontSize: 9.3,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (contract.startDate !=
                    null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons
                        .calendar_today_outlined,
                    size: 12,
                    color:
                    _PilotHomePalette
                        .muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _shortDate(
                      contract.startDate!,
                    ),
                    style:
                    const TextStyle(
                      color:
                      _PilotHomePalette
                          .muted,
                      fontSize: 9.2,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: onTap,
              style:
              FilledButton.styleFrom(
                elevation: 0,
                backgroundColor:
                _PilotHomePalette.teal,
                foregroundColor:
                Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                      10),
                ),
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 12,
                ),
              ),
              child: const Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Text(
                    'Review contract',
                    style: TextStyle(
                      fontSize: 10.7,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 7),
                  Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreJobsCard extends StatelessWidget {
  const _ExploreJobsCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(16),
        child: Container(
          height: 61,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color:
              _PilotHomePalette.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration:
                BoxDecoration(
                  gradient:
                  const LinearGradient(
                    begin:
                    Alignment.topLeft,
                    end: Alignment
                        .bottomRight,
                    colors: [
                      Color(0xFF12BFC4),
                      Color(0xFF0794AE),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(
                      11),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore jobs',
                      style: TextStyle(
                        color:
                        _PilotHomePalette
                            .navy,
                        fontSize: 11.7,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Find new drone opportunities',
                      style: TextStyle(
                        color:
                        _PilotHomePalette
                            .muted,
                        fontSize: 9.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 29,
                height: 29,
                decoration:
                const BoxDecoration(
                  color:
                  _PilotHomePalette
                      .tealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                  _PilotHomePalette
                      .tealDark,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveMissionCard extends StatelessWidget {
  const _ActiveMissionCard({
    required this.contract,
    required this.application,
    required this.onTap,
    required this.onViewAll,
  });

  final _HomeContractSnapshot contract;
  final PilotHomeApplicationItem? application;
  final VoidCallback onTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final jobTitle =
        application?.jobTitle.trim() ?? '';
    final company =
        application?.company.trim() ?? '';
    final location =
        application?.location.trim() ?? '';
    final companyPhoto =
        application?.companyPhoto.trim() ?? '';

    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(17),
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(
            11,
            10,
            10,
            11,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(17),
            border: Border.all(
              color:
              _PilotHomePalette.border,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration:
                    BoxDecoration(
                      color:
                      _PilotHomePalette
                          .tealSoft,
                      borderRadius:
                      BorderRadius.circular(
                          9),
                    ),
                    child: const Icon(
                      Icons
                          .flight_takeoff_rounded,
                      color:
                      _PilotHomePalette
                          .tealDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Active mission',
                      style: TextStyle(
                        color:
                        _PilotHomePalette
                            .navy,
                        fontSize: 11.5,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onViewAll,
                    child: const Padding(
                      padding:
                      EdgeInsets.all(4),
                      child: Text(
                        'View all',
                        style: TextStyle(
                          color:
                          _PilotHomePalette
                              .tealDark,
                          fontSize: 9.2,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 60,
                    clipBehavior: Clip.antiAlias,
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                          0xFFF1F7F8),
                      borderRadius:
                      BorderRadius.circular(
                          10),
                      border: Border.all(
                        color:
                        _PilotHomePalette.border,
                      ),
                    ),
                    child: companyPhoto.isNotEmpty
                        ? Image.network(
                      companyPhoto,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      filterQuality:
                      FilterQuality.high,
                      errorBuilder:
                          (_, __, ___) =>
                      const Icon(
                        Icons
                            .business_outlined,
                        color:
                        _PilotHomePalette
                            .tealDark,
                        size: 23,
                      ),
                    )
                        : const Icon(
                      Icons.business_outlined,
                      color:
                      _PilotHomePalette
                          .tealDark,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          jobTitle.isEmpty
                              ? 'Drone mission'
                              : jobTitle,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            color:
                            _PilotHomePalette
                                .navy,
                            fontSize: 11.2,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                        if (company
                            .isNotEmpty) ...[
                          const SizedBox(
                              height: 2),
                          Text(
                            'With $company',
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color:
                              _PilotHomePalette
                                  .muted,
                              fontSize: 8.9,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child:
                              ClipRRect(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                    20),
                                child:
                                LinearProgressIndicator(
                                  minHeight: 5,
                                  value: contract
                                      .workflowProgress,
                                  backgroundColor:
                                  const Color(
                                      0xFFE5ECEF),
                                  valueColor:
                                  const AlwaysStoppedAnimation<
                                      Color>(
                                    _PilotHomePalette
                                        .teal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 7),
                            Text(
                              contract
                                  .statusLabel,
                              style:
                              const TextStyle(
                                color:
                                _PilotHomePalette
                                    .muted,
                                fontSize: 8.6,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (location
                                .isNotEmpty) ...[
                              const Icon(
                                Icons
                                    .location_on_outlined,
                                size: 11,
                                color:
                                _PilotHomePalette
                                    .muted,
                              ),
                              const SizedBox(
                                  width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  const TextStyle(
                                    color:
                                    _PilotHomePalette
                                        .muted,
                                    fontSize: 8.4,
                                  ),
                                ),
                              ),
                            ] else
                              const Spacer(),
                            if (contract
                                .daysLeftLabel
                                .isNotEmpty) ...[
                              const SizedBox(
                                  width: 6),
                              const Icon(
                                Icons
                                    .calendar_today_outlined,
                                size: 10,
                                color:
                                _PilotHomePalette
                                    .muted,
                              ),
                              const SizedBox(
                                  width: 3),
                              Text(
                                contract
                                    .daysLeftLabel,
                                style:
                                const TextStyle(
                                  color:
                                  _PilotHomePalette
                                      .muted,
                                  fontSize: 8.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineHomeNotice extends StatelessWidget {
  const _InlineHomeNotice({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        11,
        9,
        8,
        9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          _PilotHomePalette.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color:
            _PilotHomePalette.muted,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color:
                _PilotHomePalette.muted,
                fontSize: 9.3,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                unawaited(onRetry()),
            style: TextButton.styleFrom(
              foregroundColor:
              _PilotHomePalette
                  .tealDark,
              visualDensity:
              VisualDensity.compact,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 9.3,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PilotHomeInitialShimmer extends StatefulWidget {
  const _PilotHomeInitialShimmer();

  @override
  State<_PilotHomeInitialShimmer> createState() =>
      _PilotHomeInitialShimmerState();
}

class _PilotHomeInitialShimmerState
    extends State<_PilotHomeInitialShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
      const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    required double height,
    double? width,
    double radius = 16,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: .52,
        end: .94,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      ),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color:
          const Color(0xFFE9F0F2),
          borderRadius:
          BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics:
      const NeverScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        110,
      ),
      children: [
        Row(
          children: [
            _box(
              width: 59,
              height: 59,
              radius: 30,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _box(
                    width: 93,
                    height: 9,
                    radius: 5,
                  ),
                  const SizedBox(height: 7),
                  _box(
                    width: 112,
                    height: 17,
                    radius: 6,
                  ),
                ],
              ),
            ),
            _box(
              width: 44,
              height: 44,
              radius: 15,
            ),
          ],
        ),
        const SizedBox(height: 15),
        _box(height: 175, radius: 17),
        const SizedBox(height: 10),
        _box(height: 61, radius: 16),
        const SizedBox(height: 10),
        _box(height: 122, radius: 17),
        const SizedBox(height: 10),
        _box(height: 112, radius: 17),
        const SizedBox(height: 10),
        _box(height: 103, radius: 17),
      ],
    );
  }
}

class _PilotHomeBackground extends StatelessWidget {
  const _PilotHomeBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -170,
          right: -130,
          child: IgnorePointer(
            child: Container(
              width: 330,
              height: 330,
              decoration:
              BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                RadialGradient(
                  colors: [
                    const Color(
                        0xFF16C6C7)
                        .withOpacity(.075),
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


class _PilotDashboardSnapshot {
  const _PilotDashboardSnapshot({
    this.pending = 0,
    this.accepted = 0,
    this.active = 0,
    this.inProgress = 0,
    this.submitted = 0,
    this.completed = 0,
    this.awaitingMyAction = 0,
    this.pendingReleaseTotal = 0,
  });

  final int pending;
  final int accepted;
  final int active;
  final int inProgress;
  final int submitted;
  final int completed;
  final int awaitingMyAction;
  final double pendingReleaseTotal;

  int get activeMissionCount =>
      active + inProgress + submitted;

  factory _PilotDashboardSnapshot.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawContracts =
    json['contracts_by_status'];

    final contracts =
    rawContracts is Map
        ? Map<String, dynamic>.from(
      rawContracts,
    )
        : const <String, dynamic>{};

    final rawPayments =
    json['payment_summary'];

    final payments =
    rawPayments is Map
        ? Map<String, dynamic>.from(
      rawPayments,
    )
        : const <String, dynamic>{};

    return _PilotDashboardSnapshot(
      pending:
      _dashboardInt(
        contracts['pending'],
      ),
      accepted:
      _dashboardInt(
        contracts['accepted'],
      ),
      active:
      _dashboardInt(
        contracts['active'],
      ),
      inProgress:
      _dashboardInt(
        contracts['in_progress'],
      ),
      submitted:
      _dashboardInt(
        contracts['submitted'],
      ),
      completed:
      _dashboardInt(
        contracts['completed'],
      ),
      awaitingMyAction:
      _dashboardInt(
        json[
        'contracts_awaiting_my_action_count'],
      ),
      pendingReleaseTotal:
      _dashboardDouble(
        payments[
        'pending_release_total'],
      ),
    );
  }
}

int _dashboardInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(
    value?.toString() ?? '',
  ) ??
      0;
}

double _dashboardDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value?.toString() ?? '',
  ) ??
      0;
}

String _compactNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(
    RegExp(r'\.?0+$'),
    '',
  );
}

class _HomeContractSnapshot {
  const _HomeContractSnapshot({
    required this.id,
    required this.jobApplicationId,
    required this.jobPostingId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int jobApplicationId;
  final int jobPostingId;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory _HomeContractSnapshot.fromJson(
      Map<String, dynamic> json,
      ) {
    return _HomeContractSnapshot(
      id: _asHomeInt(json['id']),
      jobApplicationId: _asHomeInt(
        json['job_application_id'],
      ),
      jobPostingId: _asHomeInt(
        json['job_posting_id'],
      ),
      status: json['status']
          ?.toString()
          .trim()
          .toLowerCase() ??
          '',
      startDate:
      _asHomeDate(json['start_date']),
      endDate:
      _asHomeDate(json['end_date']),
      createdAt:
      _asHomeDate(json['created_at']),
      updatedAt:
      _asHomeDate(json['updated_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'active':
        return 'Funded';
      case 'in_progress':
        return 'Working';
      case 'submitted':
        return 'Submitted';
      case 'completed':
        return 'Complete';
      default:
        return status
            .split('_')
            .where((part) => part.isNotEmpty)
            .map(
              (part) =>
          '${part[0].toUpperCase()}'
              '${part.substring(1)}',
        )
            .join(' ');
    }
  }

  double get workflowProgress {
    switch (status) {
      case 'pending':
        return .18;
      case 'accepted':
        return .34;
      case 'active':
        return .50;
      case 'in_progress':
        return .70;
      case 'submitted':
        return .86;
      case 'completed':
        return 1;
      default:
        return .12;
    }
  }

  String get daysLeftLabel {
    final end = endDate;
    if (end == null) return '';

    final now = DateTime.now();
    final today =
    DateTime(now.year, now.month, now.day);
    final endDay =
    DateTime(end.year, end.month, end.day);

    final days =
        endDay.difference(today).inDays;

    if (days < 0) return 'Ended';
    if (days == 0) return 'Today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }
}

int _asHomeInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(
    value?.toString() ?? '',
  ) ??
      0;
}

DateTime? _asHomeDate(dynamic value) {
  final text =
      value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

String _shortDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} '
      '${value.day}, ${value.year}';
}

class _PilotHomePalette {
  static const navy =
  Color(0xFF0A2D46);
  static const muted =
  Color(0xFF7F91A0);
  static const border =
  Color(0xFFDDE8EC);
  static const teal =
  Color(0xFF10AEBB);
  static const tealDark =
  Color(0xFF078FA5);
  static const tealSoft =
  Color(0xFFE8F8F8);
}

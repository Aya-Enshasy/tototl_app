import 'package:flutter/material.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/pilot/services/pilot_application_service.dart';
import 'package:tototl_app/features/pilot/controllers/pilot_home_controller.dart';
import 'package:tototl_app/features/pilot/models/pilot_availability_preference.dart';
import 'package:tototl_app/features/pilot/models/pilot_home_snapshot.dart';
import 'package:tototl_app/features/pilot/services/pilot_availability_local_store.dart';
import 'package:tototl_app/features/pilot/screens/applications/application_details_screen.dart';
import 'package:tototl_app/features/pilot/screens/applications/applications_screen.dart';
import 'package:tototl_app/features/pilot/screens/jobs/find_drone_jobs.dart';
import 'package:tototl_app/features/pilot/screens/home/widgets/availability_card.dart';
import 'package:tototl_app/features/pilot/screens/home/widgets/home_header.dart';
import 'package:tototl_app/features/pilot/screens/home/widgets/my_drone_card.dart';
import 'package:tototl_app/features/pilot/screens/home/widgets/recent_applications_section.dart';

import '../../../services/drone_service.dart';
import '../../drones/my_drones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PilotHomeController _controller;
  late final AnimationController _entranceController;

  PilotAvailabilityPreference _availability =
      const PilotAvailabilityPreference();

  @override
  void initState() {
    super.initState();

    _controller = PilotHomeController(
      applicationService: PilotApplicationService(ApiClient()),
      droneService: DroneService(ApiClient()),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final availability = await PilotAvailabilityLocalStore.read();

    if (mounted) {
      setState(() => _availability = availability);
    }

    await _controller.bootstrap();

    if (mounted) {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Widget _entry({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.075).clamp(0.0, 0.48).toDouble();
    final end = (start + 0.42).clamp(0.0, 1.0).toDouble();

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
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Future<void> _openFleet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MyDronesScreen(),
      ),
    );

    if (mounted) {
      await _controller.forceRefresh();
    }
  }

  Future<void> _openApplications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ApplicationsScreen(),
      ),
    );

    if (mounted) {
      await _controller.forceRefresh();
    }
  }

  Future<void> _openJobs() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FindDroneJobsScreen(),
      ),
    );

    if (mounted) {
      await _controller.forceRefresh();
    }
  }

  Future<void> _openApplication(
    PilotHomeApplicationItem application,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicationDetailsScreen(
          applicationId: application.id,
        ),
      ),
    );

    if (mounted) {
      await _controller.forceRefresh();
    }
  }

  Future<void> _editAvailability() async {
    final result = await showModalBottomSheet<PilotAvailabilityPreference>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.34),
      builder: (_) => AvailabilityEditorSheet(
        initial: _availability,
      ),
    );

    if (result == null || !mounted) return;

    await PilotAvailabilityLocalStore.write(result);

    if (!mounted) return;
    setState(() => _availability = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final snapshot =
                    _controller.snapshot ?? const PilotHomeSnapshot();
                final firstLoad =
                    _controller.isInitialLoading && _controller.snapshot == null;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 17, 20, 112),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _entry(
                            index: 0,
                            child: const HomeHeader(),
                          ),
                          const SizedBox(height: 13),
                          if (_controller.errorMessage != null &&
                              _controller.snapshot == null) ...[
                            _HomeErrorCard(
                              message: _controller.errorMessage!,
                              onRetry: _controller.forceRefresh,
                            ),
                            const SizedBox(height: 24),
                          ],
                          _entry(
                            index: 1,
                            child: MyDroneCard(
                              drones: snapshot.drones,
                              loading: firstLoad,
                              errorMessage: _controller.snapshot == null
                                  ? _controller.dronesError
                                  : null,
                              onRetry: _controller.forceRefresh,
                              onOpenFleet: _openFleet,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _entry(
                            index: 2,
                            child: RecentApplicationsSection(
                              applications: snapshot.applications,
                              loading: firstLoad,
                              errorMessage: _controller.snapshot == null
                                  ? _controller.applicationsError
                                  : null,
                              onRetry: _controller.forceRefresh,
                              onSeeAll: _openApplications,
                              onExploreJobs: _openJobs,
                              onOpenApplication: _openApplication,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _entry(
                            index: 3,
                            child: AvailabilityCard(
                              preference: _availability,
                              onTap: _editAvailability,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -185,
          right: -145,
          child: IgnorePointer(
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF17C6C7).withOpacity(0.10),
                    const Color(0xFF17C6C7).withOpacity(0.025),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 245,
          left: -170,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withOpacity(0.045),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          right: -185,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16C6C7).withOpacity(0.035),
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

class _HomeErrorCard extends StatelessWidget {
  const _HomeErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 11, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.6,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

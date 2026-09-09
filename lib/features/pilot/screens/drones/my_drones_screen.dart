import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';

import '../../controllers/drone_controller.dart';
import '../../models/drone_model.dart';
import '../../services/drone_service.dart';

import 'drone_details_screen.dart';
import 'drone_form_screen.dart';

// ============================================================================
// COLORS
// ============================================================================

const Color _bg = Color(0xFFF6F8FA);
const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF63748A);
const Color _muted2 = Color(0xFF93A2B5);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE5EAF0);
const Color _danger = Color(0xFFE45252);

// ============================================================================
// MY DRONES SCREEN
// ============================================================================

class MyDronesScreen extends StatefulWidget {
  const MyDronesScreen({
    super.key,
  });

  @override
  State<MyDronesScreen> createState() =>
      _MyDronesScreenState();
}

class _MyDronesScreenState
    extends State<MyDronesScreen> {
  late final DroneController _controller;

  @override
  void initState() {
    super.initState();

    _controller = DroneController(
      DroneService(
        ApiClient(),
      ),
    );

    _controller.addListener(
      _onControllerChanged,
    );

    // Local snapshot first. The controller starts a silent API refresh after
    // cached data is visible.
    unawaited(
      _controller.bootstrap(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ==========================================================================
  // REFRESH
  // ==========================================================================

  Future<void> _refresh() async {
    final success = await _controller.refresh();

    if (!mounted || success) {
      return;
    }

    _showSnack(
      _controller.lastRefreshError ??
          _controller.errorMessage ??
          'Unable to refresh drones.',
      isError: true,
    );
  }

  // ==========================================================================
  // ADD
  // ==========================================================================

  Future<void> _add() async {
    HapticFeedback.selectionClick();

    final created =
    await Navigator.of(context).push<DroneModel>(
      MaterialPageRoute(
        builder: (_) =>
        const DroneFormScreen(),
      ),
    );

    if (!mounted ||
        created == null) {
      return;
    }

    // The create endpoint already returned the authoritative new drone and
    // DroneService stores it in the shared local cache. Update this screen
    // immediately without wasting another blocking list request.
    _controller.upsertLocal(
      created,
    );
  }

  // ==========================================================================
  // DETAILS
  // ==========================================================================

  Future<void> _openDrone(
      DroneModel drone,
      ) async {
    HapticFeedback.selectionClick();

    final deleted =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DroneDetailsScreen(
              drone: drone,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (deleted == true) {
      // Delete returns true from DroneDetailsScreen. Remove the card instantly;
      // the service also updates the persistent cache.
      _controller.removeLocal(
        drone.id,
      );
      return;
    }

    // An edit may have happened. Keep the current content visible and ask for
    // the newest list in the background only.
    unawaited(
      _controller.refresh(
        silent: true,
      ),
    );
  }

  // ==========================================================================
  // SNACK
  // ==========================================================================

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
        SnackBarBehavior.floating,
        backgroundColor:
        isError ? _danger : _ink,
        margin:
        const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
        content:
        Text(message),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final firstLoad =
        _controller.isInitialLoading &&
            !_controller.hasSnapshot;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () {
                Navigator.pop(context);
              },
              onAdd: _add,
            ),

            Expanded(
              child: firstLoad
                  ? const _LoadingState()
                  : RefreshIndicator(
                color: _tealDark,
                onRefresh: _refresh,
                child: _controller.drones.isEmpty
                    ? _EmptyState(
                  onAdd: _add,
                )
                    : CustomScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(
                    parent:
                    BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        18,
                        4,
                        18,
                        12,
                      ),
                      sliver:
                      SliverToBoxAdapter(
                        child:
                        _FleetSummary(
                          count:
                          _controller.drones.length,
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding:
                      const EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        32,
                      ),
                      sliver:
                      SliverList.separated(
                        itemCount:
                        _controller.drones.length,
                        separatorBuilder:
                            (_, __) =>
                        const SizedBox(
                          height: 16,
                        ),
                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          final drone =
                          _controller.drones[index];

                          return _PremiumDroneCard(
                            drone: drone,
                            index: index,
                            onTap: () =>
                                _openDrone(
                                  drone,
                                ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TOP BAR
// ============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onAdd,
  });

  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        8,
      ),
      child: Row(
        children: [
          _RoundButton(
            icon:
            Icons.arrow_back_ios_new_rounded,
            onTap:
            onBack,
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'My Drones',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage your aircraft fleet',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          FilledButton.icon(
            onPressed:
            onAdd,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              _tealDark,
              foregroundColor:
              Colors.white,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              visualDensity:
              VisualDensity.compact,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(15),
              ),
            ),
            icon:
            const Icon(
              Icons.add_rounded,
              size: 17,
            ),
            label:
            const Text(
              'Add',
              style: TextStyle(
                fontSize: 11.5,
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
// SUMMARY
// ============================================================================

class _FleetSummary extends StatelessWidget {
  const _FleetSummary({
    required this.count,
  });

  final int count;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        17,
        16,
        17,
        16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF092D43),
            Color(0xFF0A5265),
          ],
        ),
        borderRadius:
        BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
            _ink.withOpacity(0.10),
            blurRadius: 24,
            offset:
            const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration:
            BoxDecoration(
              color:
              Colors.white.withOpacity(0.12),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child:
            const Icon(
              Icons.flight_takeoff_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'aircraft' : 'aircraft'}',
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  count == 1
                      ? 'Your registered drone'
                      : 'Your registered fleet',
                  style:
                  TextStyle(
                    color:
                    Colors.white.withOpacity(0.70),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white.withOpacity(0.12),
              borderRadius:
              BorderRadius.circular(30),
            ),
            child:
            const Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF7EE8E5),
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  'Pilot fleet',
                  style: TextStyle(
                    color: Color(0xFFB7F4F2),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
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

// ============================================================================
// PREMIUM DRONE CARD
// ============================================================================

class _PremiumDroneCard extends StatelessWidget {
  const _PremiumDroneCard({
    required this.drone,
    required this.index,
    required this.onTap,
  });

  final DroneModel drone;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(26),
      child: InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(26),
        child: Container(
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            BorderRadius.circular(26),
            border:
            Border.all(
              color:
              _border,
            ),
            boxShadow: [
              BoxShadow(
                color:
                _ink.withOpacity(0.045),
                blurRadius:
                22,
                offset:
                const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior:
          Clip.antiAlias,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==============================================================
              // IMAGE
              // ==============================================================

              AspectRatio(
                aspectRatio: 16 / 8.8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _DroneImage(
                      url:
                      drone.imageUrl,
                    ),

                    const Positioned.fill(
                      child:
                      DecoratedBox(
                        decoration:
                        BoxDecoration(
                          gradient:
                          LinearGradient(
                            begin:
                            Alignment.topCenter,
                            end:
                            Alignment.bottomCenter,
                            stops: [
                              0.45,
                              1.0,
                            ],
                            colors: [
                              Colors.transparent,
                              Color(0x99071A35),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      child:
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.white.withOpacity(0.92),
                          borderRadius:
                          BorderRadius.circular(30),
                        ),
                        child:
                        Text(
                          'Drone ${index + 1}',
                          style:
                          const TextStyle(
                            color: _ink,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 15,
                      right: 15,
                      bottom: 13,
                      child:
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drone.title,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (drone.yearLabel.isNotEmpty)
                                      _ImagePill(
                                        icon:
                                        Icons.calendar_today_outlined,
                                        text:
                                        drone.yearLabel,
                                      ),

                                    if (drone.weightLabel !=
                                        'Not specified')
                                      _ImagePill(
                                        icon:
                                        Icons.scale_outlined,
                                        text:
                                        drone.weightLabel,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 38,
                            height: 38,
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.white.withOpacity(0.92),
                              shape:
                              BoxShape.circle,
                            ),
                            child:
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================================================
              // BODY
              // ==============================================================

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  15,
                  14,
                  15,
                  15,
                ),
                child:
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                          _Metric(
                            icon:
                            Icons.timer_outlined,
                            label:
                            'Flight time',
                            value:
                            drone.flightTimeLabel,
                          ),
                        ),

                        const _VerticalDivider(),

                        Expanded(
                          child:
                          _Metric(
                            icon:
                            Icons.battery_std_rounded,
                            label:
                            'Batteries',
                            value:
                            drone.batteriesLabel,
                          ),
                        ),

                        const _VerticalDivider(),

                        Expanded(
                          child:
                          _Metric(
                            icon:
                            Icons.payments_outlined,
                            label:
                            'Hourly',
                            value:
                            drone.hourlyRateLabel,
                          ),
                        ),
                      ],
                    ),

                    if (drone.capabilities.isNotEmpty) ...[
                      const SizedBox(height: 14),

                      Align(
                        alignment:
                        Alignment.centerLeft,
                        child:
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children:
                          drone.capabilities
                              .take(4)
                              .map(
                                (item) =>
                                _CapabilityChip(
                                  text:
                                  _pretty(item),
                                ),
                          )
                              .toList()
                            ..addAll(
                              drone.capabilities.length > 4
                                  ? [
                                _CapabilityChip(
                                  text:
                                  '+${drone.capabilities.length - 4}',
                                  muted:
                                  true,
                                ),
                              ]
                                  : [],
                            ),
                        ),
                      ),
                    ],
                  ],
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
// DRONE NETWORK IMAGE
// ============================================================================

class _DroneImage extends StatelessWidget {
  const _DroneImage({
    required this.url,
  });

  final String url;

  @override
  Widget build(
      BuildContext context,
      ) {
    final clean =
    url.trim();

    if (clean.isEmpty) {
      return const _ImageFallback();
    }

    return Image.network(
      clean,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,

      // This is harmless for public image URLs and makes intent explicit.
      headers: const {
        'Accept': 'image/*',
      },

      loadingBuilder: (
          context,
          child,
          progress,
          ) {
        if (progress == null) {
          return child;
        }

        return const _ImageLoading();
      },

      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        debugPrint(
          'DRONE IMAGE FAILED: $clean',
        );

        debugPrint(
          'DRONE IMAGE ERROR: $error',
        );

        return const _ImageFallback(
          failed: true,
        );
      },
    );
  }
}

class _ImageLoading extends StatefulWidget {
  const _ImageLoading();

  @override
  State<_ImageLoading> createState() =>
      _ImageLoadingState();
}

class _ImageLoadingState extends State<_ImageLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _ShimmerSurface(
          value: _controller.value,
          radius: 0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const SizedBox.expand(),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.42),
                    ),
                  ),
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    color: _tealDark.withOpacity(0.38),
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({
    this.failed = false,
  });

  final bool failed;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      decoration:
      const BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xFFEAF7F7),
            Color(0xFFD9EEF2),
          ],
        ),
      ),
      child:
      Center(
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.flight_takeoff_rounded,
              color:
              Color(0x88078B98),
              size: 52,
            ),
            if (failed) ...[
              const SizedBox(height: 7),
              const Text(
                'Image unavailable',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SMALL COMPONENTS
// ============================================================================

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: _tealDark,
          size: 17,
        ),

        const SizedBox(height: 6),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style:
          const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style:
          const TextStyle(
            color: _muted2,
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider
    extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: 1,
      height: 42,
      margin:
      const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      color: _border,
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.text,
    this.muted = false,
  });

  final String text;
  final bool muted;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        muted
            ? const Color(0xFFF2F5F7)
            : _tealSoft,
        borderRadius:
        BorderRadius.circular(30),
      ),
      child:
      Text(
        text,
        style:
        TextStyle(
          color:
          muted ? _muted : _tealDark,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ImagePill extends StatelessWidget {
  const _ImagePill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(0.18),
        borderRadius:
        BorderRadius.circular(30),
        border:
        Border.all(
          color:
          Colors.white.withOpacity(0.18),
        ),
      ),
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style:
            const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child:
      InkWell(
        onTap: onTap,
        customBorder:
        const CircleBorder(),
        child:
        SizedBox(
          width: 42,
          height: 42,
          child:
          Icon(
            icon,
            color: _ink,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(
      BuildContext context,
      ) {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        26,
        90,
        26,
        30,
      ),
      children: [
        Container(
          width: 82,
          height: 82,
          decoration:
          const BoxDecoration(
            color: _tealSoft,
            shape: BoxShape.circle,
          ),
          child:
          const Icon(
            Icons.flight_takeoff_rounded,
            color: _tealDark,
            size: 36,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Build your fleet',
          textAlign:
          TextAlign.center,
          style:
          TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Add the drones you operate so companies can review your equipment before assigning a mission.',
          textAlign:
          TextAlign.center,
          style:
          TextStyle(
            color: _muted,
            fontSize: 11.5,
            height: 1.55,
          ),
        ),

        const SizedBox(height: 22),

        FilledButton.icon(
          onPressed:
          onAdd,
          style:
          FilledButton.styleFrom(
            backgroundColor:
            _tealDark,
            foregroundColor:
            Colors.white,
            padding:
            const EdgeInsets.symmetric(
              vertical: 14,
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(17),
            ),
          ),
          icon:
          const Icon(
            Icons.add_rounded,
          ),
          label:
          const Text(
            'Add your first drone',
            style:
            TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _LoadingState extends StatefulWidget {
  const _LoadingState();

  @override
  State<_LoadingState> createState() =>
      _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            4,
            18,
            32,
          ),
          children: [
            _FleetSummaryShimmer(
              value: value,
            ),
            const SizedBox(height: 16),
            _DroneCardShimmer(
              value: value,
            ),
            const SizedBox(height: 16),
            _DroneCardShimmer(
              value: value,
              compact: true,
            ),
          ],
        );
      },
    );
  }
}

class _FleetSummaryShimmer extends StatelessWidget {
  const _FleetSummaryShimmer({
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF103D4D),
            Color(0xFF0A6672),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.075),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _ShimmerBlock(
            value: value,
            width: 50,
            height: 50,
            radius: 16,
            onDark: true,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(
                  value: value,
                  width: 112,
                  height: 15,
                  radius: 8,
                  onDark: true,
                ),
                const SizedBox(height: 8),
                _ShimmerBlock(
                  value: value,
                  width: 158,
                  height: 9,
                  radius: 6,
                  onDark: true,
                ),
              ],
            ),
          ),
          _ShimmerBlock(
            value: value,
            width: 76,
            height: 28,
            radius: 18,
            onDark: true,
          ),
        ],
      ),
    );
  }
}

class _DroneCardShimmer extends StatelessWidget {
  const _DroneCardShimmer({
    required this.value,
    this.compact = false,
  });

  final double value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 286 : 305,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 11,
            child: _ShimmerSurface(
              value: value,
              radius: 0,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: _ShimmerBlock(
                        value: value,
                        width: 70,
                        height: 25,
                        radius: 16,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          right: 48,
                          bottom: 2,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerBlock(
                              value: value,
                              width: 170,
                              height: 18,
                              radius: 8,
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                _ShimmerBlock(
                                  value: value,
                                  width: 58,
                                  height: 22,
                                  radius: 13,
                                ),
                                const SizedBox(width: 7),
                                _ShimmerBlock(
                                  value: value,
                                  width: 68,
                                  height: 22,
                                  radius: 13,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _ShimmerBlock(
                        value: value,
                        width: 38,
                        height: 38,
                        radius: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                15,
                14,
                15,
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricShimmer(
                          value: value,
                        ),
                      ),
                      const _VerticalDivider(),
                      Expanded(
                        child: _MetricShimmer(
                          value: value,
                        ),
                      ),
                      const _VerticalDivider(),
                      Expanded(
                        child: _MetricShimmer(
                          value: value,
                        ),
                      ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _ShimmerBlock(
                            value: value,
                            width: 62,
                            height: 24,
                            radius: 15,
                          ),
                          const SizedBox(width: 7),
                          _ShimmerBlock(
                            value: value,
                            width: 78,
                            height: 24,
                            radius: 15,
                          ),
                          const SizedBox(width: 7),
                          _ShimmerBlock(
                            value: value,
                            width: 54,
                            height: 24,
                            radius: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricShimmer extends StatelessWidget {
  const _MetricShimmer({
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShimmerBlock(
          value: value,
          width: 20,
          height: 20,
          radius: 7,
        ),
        const SizedBox(height: 7),
        _ShimmerBlock(
          value: value,
          width: 50,
          height: 10,
          radius: 5,
        ),
        const SizedBox(height: 5),
        _ShimmerBlock(
          value: value,
          width: 38,
          height: 7,
          radius: 4,
        ),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.value,
    required this.width,
    required this.height,
    required this.radius,
    this.onDark = false,
  });

  final double value;
  final double width;
  final double height;
  final double radius;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final base = onDark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFFEAF0F3);
    final highlight = onDark
        ? Colors.white.withOpacity(0.25)
        : const Color(0xFFF9FCFD);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + (3.6 * value), 0),
          end: Alignment(-0.8 + (3.6 * value), 0),
          colors: [
            base,
            highlight,
            base,
          ],
          stops: const [
            0.18,
            0.50,
            0.82,
          ],
        ),
      ),
    );
  }
}

class _ShimmerSurface extends StatelessWidget {
  const _ShimmerSurface({
    required this.value,
    required this.child,
    required this.radius,
  });

  final double value;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + (3.6 * value), -0.2),
          end: Alignment(-0.8 + (3.6 * value), 0.2),
          colors: const [
            Color(0xFFE8F2F4),
            Color(0xFFF9FCFD),
            Color(0xFFDDECEF),
            Color(0xFFF9FCFD),
            Color(0xFFE8F2F4),
          ],
          stops: [
            0.00,
            0.28,
            0.50,
            0.72,
            1.00,
          ],
        ),
      ),
      child: child,
    );
  }
}

// ============================================================================
// TEXT
// ============================================================================

String _pretty(
    String value,
    ) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where(
        (item) =>
    item.trim().isNotEmpty,
  )
      .map(
        (item) =>
    '${item[0].toUpperCase()}${item.substring(1).toLowerCase()}',
  )
      .join(' ');
}
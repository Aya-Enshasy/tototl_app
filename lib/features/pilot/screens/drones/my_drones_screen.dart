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

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = DroneController(
      DroneService(
        ApiClient(),
      ),
    );

    _load();
  }

  // ==========================================================================
  // LOAD
  // ==========================================================================

  Future<void> _load() async {
    final result =
    await _controller.loadDrones();

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    if (result == null) {
      _showSnack(
        _controller.errorMessage ??
            'Unable to load drones.',
        isError: true,
      );
    }
  }

  Future<void> _refresh() async {
    await _controller.loadDrones();

    if (!mounted) {
      return;
    }

    setState(() {});
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

    await _refresh();
  }

  // ==========================================================================
  // DETAILS
  // ==========================================================================

  Future<void> _openDrone(
      DroneModel drone,
      ) async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
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

    await _refresh();
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
              child: _loading
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
                    fontSize: 21,
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

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      color:
      const Color(0xFFE9F4F6),
      alignment:
      Alignment.center,
      child:
      const SizedBox(
        width: 24,
        height: 24,
        child:
        CircularProgressIndicator(
          strokeWidth: 2.2,
          color: _tealDark,
        ),
      ),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(
      BuildContext context,
      ) {
    return ListView(
      physics:
      const NeverScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        24,
      ),
      children: const [
        _Skeleton(
          height: 82,
        ),
        SizedBox(height: 16),
        _Skeleton(
          height: 305,
        ),
        SizedBox(height: 16),
        _Skeleton(
          height: 305,
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({
    required this.height,
  });

  final double height;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      height: height,
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFEEF3F5),
        borderRadius:
        BorderRadius.circular(24),
      ),
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
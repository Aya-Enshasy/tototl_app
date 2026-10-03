import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/pilot/models/pilot_home_snapshot.dart';

class MyDroneCard extends StatelessWidget {
  const MyDroneCard({
    super.key,
    required this.drones,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenFleet,
  });

  final List<PilotHomeDroneItem> drones;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) {
    if (loading && drones.isEmpty) {
      return const _FleetShimmer();
    }

    if (errorMessage != null &&
        drones.isEmpty) {
      return _FleetStateCard(
        title: 'My fleet',
        message:
        'Your aircraft could not be refreshed.',
        action: 'Retry',
        onTap: onRetry,
      );
    }

    if (drones.isEmpty) {
      return _FleetStateCard(
        title: 'My fleet',
        message:
        'Add your aircraft to start matching with jobs.',
        action: 'Add aircraft',
        onTap: onOpenFleet,
      );
    }

    final drone = drones.first;

    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(17),
      child: InkWell(
        onTap: () {
          HapticFeedback
              .selectionClick();
          onOpenFleet();
        },
        borderRadius:
        BorderRadius.circular(17),
        child: Container(
          padding:
          const EdgeInsets.fromLTRB(
            11,
            10,
            9,
            10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(17),
            border: Border.all(
              color:
              const Color(0xFFDDE8EC),
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
                      const Color(
                          0xFFE8F8F8),
                      borderRadius:
                      BorderRadius.circular(
                          9),
                    ),
                    child: const Icon(
                      Icons
                          .flight_takeoff_rounded,
                      size: 16,
                      color:
                      Color(0xFF078FA5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'My fleet',
                      style: TextStyle(
                        color:
                        Color(0xFF0A2D46),
                        fontSize: 11.5,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    drones.length == 1
                        ? '1 aircraft'
                        : '${drones.length} aircraft',
                    style: const TextStyle(
                      color:
                      Color(0xFF078FA5),
                      fontSize: 8.9,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _DroneImage(drone: drone),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          drone.title
                              .trim()
                              .isEmpty
                              ? 'Drone'
                              : drone.title
                              .trim(),
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            color:
                            Color(
                                0xFF0A2D46),
                            fontSize: 10.8,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                        if (drone.year
                            .trim()
                            .isNotEmpty ||
                            drone.serialNumber
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(
                              height: 3),
                          Text(
                            [
                              if (drone.year
                                  .trim()
                                  .isNotEmpty)
                                drone.year
                                    .trim(),
                              if (drone
                                  .serialNumber
                                  .trim()
                                  .isNotEmpty)
                                'SN ${drone.serialNumber.trim()}',
                            ].join('  ·  '),
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color:
                              Color(
                                  0xFF7F91A0),
                              fontSize: 8.7,
                            ),
                          ),
                        ],
                        if (drone.capabilities
                            .isNotEmpty) ...[
                          const SizedBox(
                              height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: drone
                                .capabilities
                                .take(2)
                                .map(
                                  (item) =>
                                  _CapabilityPill(
                                    label:
                                    item,
                                  ),
                            )
                                .toList(
                              growable:
                              false,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration:
                    const BoxDecoration(
                      color:
                      Color(0xFFE8F8F8),
                      shape:
                      BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .chevron_right_rounded,
                      color:
                      Color(0xFF078FA5),
                      size: 18,
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

class _DroneImage extends StatelessWidget {
  const _DroneImage({
    required this.drone,
  });

  final PilotHomeDroneItem drone;

  @override
  Widget build(BuildContext context) {
    final url =
    drone.imageUrl.trim();

    return Container(
      width: 88,
      height: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color:
        const Color(0xFFF0F6F7),
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color:
          const Color(0xFFE0E9EC),
        ),
      ),
      child: url.isEmpty
          ? const Icon(
        Icons.flight_rounded,
        color:
        Color(0xFF078FA5),
        size: 26,
      )
          : Image.network(
        url,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality:
        FilterQuality.high,
        errorBuilder:
            (_, __, ___) =>
        const Icon(
          Icons.flight_rounded,
          color:
          Color(0xFF078FA5),
          size: 26,
        ),
      ),
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final clean = label
        .trim()
        .replaceAll('_', ' ');

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFE9F8F8),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        clean,
        style: const TextStyle(
          color: Color(0xFF078FA5),
          fontSize: 7.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FleetStateCard extends StatelessWidget {
  const _FleetStateCard({
    required this.title,
    required this.message,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String message;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        11,
        10,
        9,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          const Color(0xFFDDE8EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration:
            BoxDecoration(
              color:
              const Color(
                  0xFFE8F8F8),
              borderRadius:
              BorderRadius.circular(
                  10),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color:
              Color(0xFF078FA5),
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF0A2D46),
                    fontSize: 10.8,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF7F91A0),
                    fontSize: 8.8,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor:
              const Color(
                  0xFF078FA5),
              visualDensity:
              VisualDensity.compact,
            ),
            child: Text(
              action,
              style:
              const TextStyle(
                fontSize: 8.8,
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

class _FleetShimmer extends StatelessWidget {
  const _FleetShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 111,
      decoration: BoxDecoration(
        color:
        const Color(0xFFE9F0F2),
        borderRadius:
        BorderRadius.circular(17),
      ),
    );
  }
}

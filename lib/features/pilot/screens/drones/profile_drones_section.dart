import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';

import '../../controllers/drone_controller.dart';
import '../../models/drone_model.dart';
import '../../services/drone_service.dart';
import 'drone_details_screen.dart';
import 'drone_form_screen.dart';
import 'my_drones_screen.dart';


const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF63748A);
const Color _muted2 = Color(0xFF98A6B4);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE5EAF0);

class ProfileDronesSection extends StatefulWidget {
  const ProfileDronesSection({
    super.key,
  });

  @override
  State<ProfileDronesSection> createState() =>
      _ProfileDronesSectionState();
}

class _ProfileDronesSectionState
    extends State<ProfileDronesSection> {
  late final DroneController _controller;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller =
        DroneController(
          DroneService(
            ApiClient(),
          ),
        );

    _load();
  }

  Future<void> _load() async {
    await _controller.loadDrones();

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

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

    await _load();
  }

  Future<void> _openAll() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const MyDronesScreen(),
      ),
    );

    if (!mounted) return;

    await _load();
  }

  Future<void> _openDrone(
      DroneModel drone,
      ) async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DroneDetailsScreen(
              drone:
              drone,
            ),
      ),
    );

    if (!mounted) return;

    await _load();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(0.96),
        borderRadius:
        BorderRadius.circular(24),
        border:
        Border.all(
          color:
          Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color:
            _ink.withOpacity(0.04),
            blurRadius:
            18,
            offset:
            const Offset(0, 7),
          ),
        ],
      ),
      child:
      Column(
        children: [
          Row(
            children: [
              const Expanded(
                child:
                Text(
                  'My Drones',
                  style:
                  TextStyle(
                    color:
                    _ink,
                    fontSize:
                    17,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing:
                    -0.3,
                  ),
                ),
              ),

              if (!_loading &&
                  _controller.drones.length > 1)
                TextButton(
                  onPressed:
                  _openAll,
                  style:
                  TextButton.styleFrom(
                    foregroundColor:
                    _muted,
                    visualDensity:
                    VisualDensity.compact,
                  ),
                  child:
                  Text(
                    'View all ${_controller.drones.length}',
                    style:
                    const TextStyle(
                      fontSize:
                      10.5,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),

              TextButton.icon(
                onPressed:
                _add,
                style:
                TextButton.styleFrom(
                  foregroundColor:
                  _tealDark,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    6,
                  ),
                  visualDensity:
                  VisualDensity.compact,
                ),
                icon:
                const Icon(
                  Icons.add_rounded,
                  size:
                  19,
                ),
                label:
                const Text(
                  'Add Drone',
                  style:
                  TextStyle(
                    fontSize:
                    11.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          if (_loading)
            const _PreviewSkeleton()
          else if (_controller.drones.isEmpty)
            _EmptyPreview(
              onAdd:
              _add,
            )
          else
            _DronePreview(
              drone:
              _controller.drones.first,
              onTap:
                  () => _openDrone(
                _controller.drones.first,
              ),
            ),

          if (!_loading &&
              _controller.errorMessage != null &&
              _controller.drones.isEmpty) ...[
            const SizedBox(height: 9),
            TextButton.icon(
              onPressed:
              _load,
              icon:
              const Icon(
                Icons.refresh_rounded,
                size:
                16,
              ),
              label:
              const Text(
                'Retry',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DronePreview extends StatelessWidget {
  const _DronePreview({
    required this.drone,
    required this.onTap,
  });

  final DroneModel drone;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    final capability =
    drone.capabilities.isEmpty
        ? ''
        : _pretty(
      drone.capabilities.first,
    );

    return Material(
      color:
      Colors.transparent,
      borderRadius:
      BorderRadius.circular(18),
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(18),
        child:
        Container(
          constraints:
          const BoxConstraints(
            minHeight:
            108,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.white.withOpacity(0.76),
            borderRadius:
            BorderRadius.circular(18),
            border:
            Border.all(
              color:
              _border,
            ),
          ),
          child:
          Row(
            children: [
              Expanded(
                flex:
                5,
                child:
                Padding(
                  padding:
                  const EdgeInsets.all(9),
                  child:
                  AspectRatio(
                    aspectRatio:
                    1.45,
                    child:
                    Container(
                      clipBehavior:
                      Clip.antiAlias,
                      decoration:
                      BoxDecoration(
                        color:
                        _tealSoft,
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child:
                      drone.imageUrl.isEmpty
                          ? const Center(
                        child:
                        Icon(
                          Icons.flight_takeoff_rounded,
                          color:
                          _tealDark,
                          size:
                          46,
                        ),
                      )
                          : Image.network(
                        drone.imageUrl,
                        fit:
                        BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                        const Center(
                          child:
                          Icon(
                            Icons.flight_takeoff_rounded,
                            color:
                            _tealDark,
                            size:
                            46,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                flex:
                6,
                child:
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    10,
                    12,
                    5,
                    12,
                  ),
                  child:
                  Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        drone.title,
                        maxLines:
                        1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          color:
                          _ink,
                          fontSize:
                          14,
                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          if (drone.yearLabel.isNotEmpty)
                            Text(
                              drone.yearLabel,
                              style:
                              const TextStyle(
                                color:
                                _tealDark,
                                fontSize:
                                11,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          if (drone.yearLabel.isNotEmpty &&
                              capability.isNotEmpty)
                            const Text(
                              ' • ',
                              style:
                              TextStyle(
                                color:
                                _muted2,
                              ),
                            ),
                          if (capability.isNotEmpty)
                            Flexible(
                              child:
                              Text(
                                capability,
                                maxLines:
                                1,
                                overflow:
                                TextOverflow.ellipsis,
                                style:
                                const TextStyle(
                                  color:
                                  _tealDark,
                                  fontSize:
                                  11,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color:
                            _muted,
                            size:
                            13,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child:
                            Text(
                              drone.flightTimeLabel,
                              maxLines:
                              1,
                              overflow:
                              TextOverflow.ellipsis,
                              style:
                              const TextStyle(
                                color:
                                _muted,
                                fontSize:
                                9.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding:
                EdgeInsets.only(
                  right:
                  9,
                ),
                child:
                Icon(
                  Icons.chevron_right_rounded,
                  color:
                  _muted2,
                  size:
                  22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        17,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(0.70),
        borderRadius:
        BorderRadius.circular(18),
        border:
        Border.all(
          color:
          _border,
        ),
      ),
      child:
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
            const BoxDecoration(
              color:
              _tealSoft,
              shape:
              BoxShape.circle,
            ),
            child:
            const Icon(
              Icons.flight_takeoff_rounded,
              color:
              _tealDark,
              size:
              23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your first drone',
                  style:
                  TextStyle(
                    color:
                    _ink,
                    fontSize:
                    13,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Show companies the aircraft you can operate.',
                  style:
                  TextStyle(
                    color:
                    _muted,
                    fontSize:
                    9.8,
                    height:
                    1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
            onAdd,
            icon:
            const Icon(
              Icons.add_circle_rounded,
              color:
              _tealDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSkeleton extends StatelessWidget {
  const _PreviewSkeleton();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      height:
      108,
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF3F7F8),
        borderRadius:
        BorderRadius.circular(18),
      ),
    );
  }
}

String _pretty(
    String value,
    ) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where(
        (item) =>
    item.isNotEmpty,
  )
      .map(
        (item) =>
    '${item[0].toUpperCase()}${item.substring(1).toLowerCase()}',
  )
      .join(' ');
}
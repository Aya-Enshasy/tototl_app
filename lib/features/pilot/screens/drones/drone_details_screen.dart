import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';

import '../../controllers/drone_controller.dart';
import '../../models/drone_model.dart';
import '../../services/drone_service.dart';

import 'drone_form_screen.dart';

const Color _bg = Color(0xFFF7F9FB);
const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF63748A);
const Color _muted2 = Color(0xFF98A6B4);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE5EAF0);
const Color _danger = Color(0xFFE45252);

class DroneDetailsScreen extends StatefulWidget {
  const DroneDetailsScreen({
    super.key,
    required this.drone,
  });

  final DroneModel drone;

  @override
  State<DroneDetailsScreen> createState() =>
      _DroneDetailsScreenState();
}

class _DroneDetailsScreenState
    extends State<DroneDetailsScreen> {
  late final DroneController _controller;

  late DroneModel _drone;

  bool _refreshing = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();

    _drone =
        widget.drone;

    _controller =
        DroneController(
          DroneService(
            ApiClient(),
          ),
        );

    _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;

    _refreshing = true;

    final fresh =
    await _controller.loadDrone(
      _drone.id,
    );

    if (!mounted) return;

    if (fresh != null) {
      setState(() {
        _drone =
            fresh;
      });
    }

    _refreshing = false;
  }

  Future<void> _edit() async {
    HapticFeedback.selectionClick();

    final updated =
    await Navigator.of(context).push<DroneModel>(
      MaterialPageRoute(
        builder: (_) =>
            DroneFormScreen(
              initialDrone:
              _drone,
            ),
      ),
    );

    if (!mounted ||
        updated == null) {
      return;
    }

    setState(() {
      _drone =
          updated;
    });
  }

  Future<void> _delete() async {
    if (_deleting) return;

    final confirmed =
    await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin:
            const EdgeInsets.all(12),
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
              BorderRadius.circular(28),
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                  BoxDecoration(
                    color:
                    _border,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(0xFFFFEEEE),
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  child:
                  const Icon(
                    Icons.delete_outline_rounded,
                    color:
                    _danger,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Remove this drone?',
                  style:
                  TextStyle(
                    color:
                    _ink,
                    fontSize:
                    18,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_drone.title} will be removed from your profile.',
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    _muted,
                    fontSize:
                    11.5,
                    height:
                    1.45,
                  ),
                ),
                const SizedBox(height: 18),
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
                          _ink,
                          side:
                          const BorderSide(
                            color:
                            _border,
                          ),
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                        ),
                        child:
                        const Text(
                          'Cancel',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          _danger,
                          foregroundColor:
                          Colors.white,
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                        ),
                        child:
                        const Text(
                          'Remove',
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

    setState(() {
      _deleting =
      true;
    });

    final deleted =
    await _controller.deleteDrone(
      _drone.id,
    );

    if (!mounted) return;

    if (!deleted) {
      setState(() {
        _deleting =
        false;
      });

      _showSnack(
        _controller.errorMessage ??
            'Unable to remove drone.',
        isError: true,
      );

      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      _bg,
      body:
      SafeArea(
        child:
        Stack(
          children: [
            RefreshIndicator(
              color:
              _tealDark,
              onRefresh:
              _refresh,
              child:
              ListView(
                physics:
                const AlwaysScrollableScrollPhysics(
                  parent:
                  BouncingScrollPhysics(),
                ),
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  34,
                ),
                children: [
                  Row(
                    children: [
                      _RoundButton(
                        icon:
                        Icons.arrow_back_ios_new_rounded,
                        onTap:
                            () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _RoundButton(
                        icon:
                        Icons.edit_outlined,
                        onTap:
                        _edit,
                      ),
                      const SizedBox(width: 9),
                      _RoundButton(
                        icon:
                        Icons.delete_outline_rounded,
                        iconColor:
                        _danger,
                        onTap:
                        _delete,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _Hero(
                    drone:
                    _drone,
                  ),

                  const SizedBox(height: 14),

                  _Section(
                    icon:
                    Icons.flight_takeoff_rounded,
                    title:
                    'Aircraft',
                    child:
                    Column(
                      children: [
                        _InfoRow(
                          label:
                          'Make',
                          value:
                          _drone.make,
                        ),
                        _InfoRow(
                          label:
                          'Model',
                          value:
                          _drone.model,
                        ),
                        _InfoRow(
                          label:
                          'Year',
                          value:
                          _drone.yearLabel,
                        ),
                        _InfoRow(
                          label:
                          'Serial number',
                          value:
                          _drone.serialNumber,
                        ),
                        _InfoRow(
                          label:
                          'Weight',
                          value:
                          _drone.weightLabel,
                          last:
                          true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _Section(
                    icon:
                    Icons.auto_awesome_rounded,
                    title:
                    'Capabilities',
                    child:
                    _drone.capabilities.isEmpty
                        ? const _EmptyText(
                      text:
                      'No capabilities added.',
                    )
                        : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      _drone.capabilities.map(
                            (item) {
                          return _CapabilityChip(
                            value:
                            item,
                          );
                        },
                      ).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _Section(
                    icon:
                    Icons.battery_charging_full_rounded,
                    title:
                    'Power',
                    child:
                    Column(
                      children: [
                        _InfoRow(
                          label:
                          'Flight time',
                          value:
                          _drone.flightTimeLabel,
                        ),
                        _InfoRow(
                          label:
                          'Total batteries',
                          value:
                          _drone.batteriesLabel,
                        ),
                        _InfoRow(
                          label:
                          'Battery type',
                          value:
                          _drone.batteryType,
                        ),
                        _InfoRow(
                          label:
                          'Battery usage fee',
                          value:
                          _drone.batteryUsageFeeLabel,
                          last:
                          true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _PricingRow(
                    drone:
                    _drone,
                  ),
                ],
              ),
            ),

            if (_deleting)
              Positioned.fill(
                child:
                Container(
                  color:
                  Colors.black.withOpacity(0.12),
                  alignment:
                  Alignment.center,
                  child:
                  Container(
                    padding:
                    const EdgeInsets.all(18),
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                    child:
                    const CircularProgressIndicator(
                      color:
                      _tealDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.drone,
  });

  final DroneModel drone;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      height:
      235,
      clipBehavior:
      Clip.antiAlias,
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(28),
        color:
        _tealSoft,
      ),
      child:
      Stack(
        fit:
        StackFit.expand,
        children: [
          if (drone.imageUrl.isNotEmpty)
            Image.network(
              drone.imageUrl,
              fit:
              BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
              const _ImageFallback(),
            )
          else
            const _ImageFallback(),

          Positioned.fill(
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
                  colors: [
                    Colors.transparent,
                    _ink.withOpacity(0.08),
                    _ink.withOpacity(0.74),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 17,
            child:
            Column(
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
                    Colors.white,
                    fontSize:
                    22,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (drone.yearLabel.isNotEmpty)
                      _HeroPill(
                        text:
                        drone.yearLabel,
                      ),
                    if (drone.yearLabel.isNotEmpty)
                      const SizedBox(width: 7),
                    _HeroPill(
                      text:
                      drone.serialNumber.isEmpty
                          ? 'Drone #${drone.id}'
                          : 'SN ${drone.serialNumber}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  const _PricingRow({
    required this.drone,
  });

  final DroneModel drone;

  @override
  Widget build(
      BuildContext context,
      ) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final compact =
            constraints.maxWidth < 345;

        return Row(
          children: [
            Expanded(
              child:
              _PriceCard(
                label:
                'Hourly',
                value:
                drone.hourlyRateLabel,
                compact:
                compact,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child:
              _PriceCard(
                label:
                'Daily',
                value:
                drone.dailyRateLabel,
                compact:
                compact,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child:
              _PriceCard(
                label:
                'Emergency',
                value:
                drone.emergencyRateLabel,
                compact:
                compact,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      height:
      compact ? 92 : 100,
      padding:
      const EdgeInsets.all(9),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(21),
        border:
        Border.all(
          color:
          _border,
        ),
      ),
      child:
      Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.payments_outlined,
            color:
            _tealDark,
            size:
            18,
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit:
            BoxFit.scaleDown,
            child:
            Text(
              value,
              style:
              TextStyle(
                color:
                _ink,
                fontSize:
                compact ? 15 : 17,
                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit:
            BoxFit.scaleDown,
            child:
            Text(
              label,
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
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(24),
        border:
        Border.all(
          color:
          _border,
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                BoxDecoration(
                  color:
                  _tealSoft,
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child:
                Icon(
                  icon,
                  color:
                  _tealDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                const TextStyle(
                  color:
                  _ink,
                  fontSize:
                  15,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(
      BuildContext context,
      ) {
    final display =
    value.trim().isEmpty
        ? 'Not specified'
        : value.trim();

    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child:
          Row(
            children: [
              Expanded(
                child:
                Text(
                  label,
                  style:
                  const TextStyle(
                    color:
                    _muted,
                    fontSize:
                    11.5,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child:
                Text(
                  display,
                  textAlign:
                  TextAlign.right,
                  style:
                  const TextStyle(
                    color:
                    _ink,
                    fontSize:
                    11.8,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(
            height: 1,
            color:
            _border,
          ),
      ],
    );
  }
}

class _CapabilityChip
    extends StatelessWidget {
  const _CapabilityChip({
    required this.value,
  });

  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        _tealSoft,
        borderRadius:
        BorderRadius.circular(30),
      ),
      child:
      Text(
        _prettyCapability(value),
        style:
        const TextStyle(
          color:
          _tealDark,
          fontSize:
          10,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.text,
  });

  final String text;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Flexible(
      child:
      Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 5,
        ),
        decoration:
        BoxDecoration(
          color:
          Colors.white.withOpacity(0.17),
          borderRadius:
          BorderRadius.circular(30),
          border:
          Border.all(
            color:
            Colors.white.withOpacity(0.20),
          ),
        ),
        child:
        Text(
          text,
          maxLines:
          1,
          overflow:
          TextOverflow.ellipsis,
          style:
          const TextStyle(
            color:
            Colors.white,
            fontSize:
            9.5,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.iconColor = _ink,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Colors.white,
      shape:
      const CircleBorder(),
      child:
      InkWell(
        onTap:
        onTap,
        customBorder:
        const CircleBorder(),
        child:
        SizedBox(
          width: 44,
          height: 44,
          child:
          Icon(
            icon,
            color:
            iconColor,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(
      BuildContext context,
      ) {
    return const DecoratedBox(
      decoration:
      BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xFFEAF7F7),
            Color(0xFFD6ECF0),
          ],
        ),
      ),
      child:
      Center(
        child:
        Icon(
          Icons.flight_takeoff_rounded,
          color:
          Color(0x55078B98),
          size:
          82,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({
    required this.text,
  });

  final String text;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Text(
      text,
      style:
      const TextStyle(
        color:
        _muted,
        fontSize:
        11.5,
      ),
    );
  }
}

String _prettyCapability(
    String value,
    ) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((item) => item.isNotEmpty)
      .map(
        (item) =>
    '${item[0].toUpperCase()}${item.substring(1).toLowerCase()}',
  )
      .join(' ');
}
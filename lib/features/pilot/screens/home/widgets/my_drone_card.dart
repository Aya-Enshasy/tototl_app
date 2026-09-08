import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          count: drones.length,
          onOpenFleet: onOpenFleet,
        ),
        const SizedBox(height: 12),
        if (loading && drones.isEmpty)
          const _DroneShimmer()
        else if (errorMessage != null && drones.isEmpty)
          _DroneErrorState(
            message: errorMessage!,
            onRetry: onRetry,
          )
        else if (drones.isEmpty)
            _EmptyDroneState(onOpenFleet: onOpenFleet)
          else
            _DroneRail(
              drones: drones,
              onOpenFleet: onOpenFleet,
            ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.count,
    required this.onOpenFleet,
  });

  final int count;
  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.07),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.flight_takeoff_rounded,
            color: AppColors.blue,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Fleet',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your registered aircraft',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenFleet,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Row(
                children: [
                  if (count > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.055),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const Text(
                    'Manage',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.blue,
                    size: 9,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DroneRail extends StatelessWidget {
  const _DroneRail({
    required this.drones,
    required this.onOpenFleet,
  });

  final List<PilotHomeDroneItem> drones;
  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingle = drones.length == 1;
        final cardWidth = isSingle
            ? constraints.maxWidth
            : (constraints.maxWidth * 0.86).clamp(280.0, 470.0).toDouble();

        return SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: drones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              return SizedBox(
                width: cardWidth,
                child: _DroneItemCard(
                  drone: drones[index],
                  onTap: onOpenFleet,
                  index: index,
                  total: drones.length,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DroneItemCard extends StatefulWidget {
  const _DroneItemCard({
    required this.drone,
    required this.onTap,
    required this.index,
    required this.total,
  });

  final PilotHomeDroneItem drone;
  final VoidCallback onTap;
  final int index;
  final int total;

  @override
  State<_DroneItemCard> createState() => _DroneItemCardState();
}

class _DroneItemCardState extends State<_DroneItemCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final drone = widget.drone;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7FCFD),
                  Color(0xFFF0F9FA),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFDDECEF),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.055),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    right: -36,
                    top: -48,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF18BFC4).withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -45,
                    bottom: -75,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blue.withOpacity(0.035),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 13, 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14B8B6)
                                          .withOpacity(0.09),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.total > 1
                                          ? 'Aircraft ${widget.index + 1}'
                                          : 'Primary aircraft',
                                      style: const TextStyle(
                                        color: Color(0xFF0A8C92),
                                        fontSize: 9.2,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                drone.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 17,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (drone.year.isNotEmpty) ...[
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      color: AppColors.grey,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      drone.year,
                                      style: const TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (drone.year.isNotEmpty &&
                                      drone.serialNumber.isNotEmpty)
                                    Container(
                                      width: 3,
                                      height: 3,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: AppColors.lightGrey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (drone.serialNumber.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        'SN ${drone.serialNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 10.3,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              if (drone.capabilities.isNotEmpty)
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: drone.capabilities
                                      .take(2)
                                      .map(
                                        (item) => _CapabilityPill(label: item),
                                  )
                                      .toList(growable: false),
                                )
                              else
                                Text(
                                  'Tap to manage aircraft details',
                                  style: TextStyle(
                                    color: AppColors.grey.withOpacity(0.82),
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 11,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                right: -12,
                                top: 0,
                                child: Container(
                                  width: 124,
                                  height: 124,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF15BFC1)
                                            .withOpacity(0.10),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              _DroneImage(drone: drone),
                              Positioned(
                                right: -1,
                                bottom: 3,
                                child: Container(
                                  width: 33,
                                  height: 33,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.96),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFDCE9EC),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.navy.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: AppColors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DroneImage extends StatelessWidget {
  const _DroneImage({required this.drone});

  final PilotHomeDroneItem drone;

  @override
  Widget build(BuildContext context) {
    const outerRadius = BorderRadius.only(
      topLeft: Radius.circular(28),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(28),
    );

    const innerRadius = BorderRadius.only(
      topLeft: Radius.circular(26.5),
      topRight: Radius.circular(14.5),
      bottomLeft: Radius.circular(14.5),
      bottomRight: Radius.circular(26.5),
    );

    return Container(
      width: double.infinity,
      height: 118,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF17C6C7).withOpacity(0.48),
            Colors.white.withOpacity(0.96),
            AppColors.blue.withOpacity(0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.09),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: innerRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                      AppColors.navy.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (drone.imageUrl.isNotEmpty) {
      return Image.network(
        drone.imageUrl,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const _FallbackDroneImage(),
      );
    }

    return Image.asset(
      'assets/images/drone.png',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const _FallbackDroneImage(),
    );
  }
}

class _FallbackDroneImage extends StatelessWidget {
  const _FallbackDroneImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAFBFB),
            Color(0xFFF2F7FA),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue.withOpacity(0.055),
            ),
          ),
          const Icon(
            Icons.flight_takeoff_rounded,
            size: 38,
            color: AppColors.logoTurquoiseDark,
          ),
        ],
      ),
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF15BFC1).withOpacity(0.10),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF087F91),
          fontSize: 9.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


class _DroneErrorState extends StatelessWidget {
  const _DroneErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 10.5,
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

class _EmptyDroneState extends StatelessWidget {
  const _EmptyDroneState({required this.onOpenFleet});

  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8FAFA), Color(0xFFF2F8FB)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.logoTurquoiseDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your fleet profile',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add a drone so companies can see your equipment.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onOpenFleet,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _DroneShimmer extends StatefulWidget {
  const _DroneShimmer();

  @override
  State<_DroneShimmer> createState() => _DroneShimmerState();
}

class _DroneShimmerState extends State<_DroneShimmer>
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
        final t = _controller.value;

        Widget glow({
          required double width,
          required double height,
          required double radius,
        }) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment(-1.8 + (3.6 * t), 0),
                end: Alignment(-0.8 + (3.6 * t), 0),
                colors: const [
                  Color(0xFFF0F5F6),
                  Color(0xFFFBFDFD),
                  Color(0xFFE7F2F3),
                  Color(0xFFFBFDFD),
                  Color(0xFFF0F5F6),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 184,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    glow(width: 86, height: 20, radius: 10),
                    const SizedBox(height: 12),
                    glow(width: 160, height: 18, radius: 8),
                    const SizedBox(height: 8),
                    glow(width: 116, height: 10, radius: 6),
                    const Spacer(),
                    Row(
                      children: [
                        glow(width: 65, height: 22, radius: 9),
                        const SizedBox(width: 6),
                        glow(width: 58, height: 22, radius: 9),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              glow(width: 132, height: 118, radius: 24),
            ],
          ),
        );
      },
    );
  }
}


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
        const SizedBox(height: 10),
        if (loading && drones.isEmpty)
          const _DroneShimmer()
        else if (errorMessage != null && drones.isEmpty)
          _DroneErrorState(
            message: errorMessage!,
            onRetry: onRetry,
          )
        else if (drones.isEmpty)
            _EmptyDroneState(
              onOpenFleet: onOpenFleet,
            )
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
            color: AppColors.blue.withOpacity(0.065),
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
                  fontSize: 16,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              child: Row(
                children: [
                  if (count > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF9FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.logoTurquoiseDark,
                          fontSize: 10.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
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
            : (constraints.maxWidth * 0.90)
            .clamp(292.0, 430.0)
            .toDouble();

        return SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: drones.length,
            separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
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
  State<_DroneItemCard> createState() =>
      _DroneItemCardState();
}

class _DroneItemCardState extends State<_DroneItemCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final drone = widget.drone;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.987 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() => _pressed = true);
          },
          onTapCancel: () {
            setState(() => _pressed = false);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFDDE9ED),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned(
                    right: -34,
                    top: -48,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF16C6C7)
                            .withOpacity(0.055),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      13,
                      11,
                      13,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DroneDetails(
                            drone: drone,
                            index: widget.index,
                            total: widget.total,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          height: 95,
                          child: _DroneImage(
                            drone: drone,
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

class _DroneDetails extends StatelessWidget {
  const _DroneDetails({
    required this.drone,
    required this.index,
    required this.total,
  });

  final PilotHomeDroneItem drone;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                total > 1
                    ? 'AIRCRAFT ${index + 1}'
                    : 'PRIMARY AIRCRAFT',
                style: const TextStyle(
                  color: AppColors.logoTurquoiseDark,
                  fontSize: 8.1,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          drone.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14.3,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 5),
        _DroneMeta(
          year: drone.year,
          serialNumber: drone.serialNumber,
        ),
        const Spacer(),
        if (drone.capabilities.isNotEmpty)
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: drone.capabilities
                .take(2)
                .map(
                  (item) => _CapabilityPill(
                label: item,
              ),
            )
                .toList(growable: false),
          )
        else
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 11,
                color: AppColors.grey.withOpacity(0.78),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Open aircraft details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey.withOpacity(0.82),
                    fontSize: 9.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DroneMeta extends StatelessWidget {
  const _DroneMeta({
    required this.year,
    required this.serialNumber,
  });

  final String year;
  final String serialNumber;

  @override
  Widget build(BuildContext context) {
    if (year.isEmpty && serialNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (year.isNotEmpty) ...[
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.grey,
            size: 10.5,
          ),
          const SizedBox(width: 4),
          Text(
            year,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 9.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (year.isNotEmpty &&
            serialNumber.isNotEmpty) ...[
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(
              horizontal: 6,
            ),
            decoration: const BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
          ),
        ],
        if (serialNumber.isNotEmpty)
          Flexible(
            child: Text(
              'SN $serialNumber',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 9.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0FBFB),
                  Color(0xFFF7FAFC),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFDDECEF),
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: _buildImage(),
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.08),
                  blurRadius: 9,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: AppColors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (drone.imageUrl.isNotEmpty) {
      return Image.network(
        drone.imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) =>
        const _FallbackDroneImage(),
      );
    }

    return Image.asset(
      'assets/images/drone.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
      const _FallbackDroneImage(),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue.withOpacity(0.05),
            ),
          ),
          const Icon(
            Icons.flight_takeoff_rounded,
            size: 27,
            color: AppColors.logoTurquoiseDark,
          ),
        ],
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
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 82,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBFB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF15BFC1)
              .withOpacity(0.09),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF087F91),
          fontSize: 8.3,
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
      padding: const EdgeInsets.fromLTRB(
        15,
        14,
        12,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.blue,
              size: 19,
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
  const _EmptyDroneState({
    required this.onOpenFleet,
  });

  final VoidCallback onOpenFleet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        14,
        13,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE8FAFA),
                  Color(0xFFF2F8FB),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.logoTurquoiseDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your fleet profile',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add a drone so companies can see your equipment.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
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
              backgroundColor:
              AppColors.logoTurquoiseDark,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _DroneShimmer extends StatefulWidget {
  const _DroneShimmer();

  @override
  State<_DroneShimmer> createState() =>
      _DroneShimmerState();
}

class _DroneShimmerState extends State<_DroneShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1350,
      ),
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
              borderRadius:
              BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment(
                  -1.8 + (3.6 * t),
                  0,
                ),
                end: Alignment(
                  -0.8 + (3.6 * t),
                  0,
                ),
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
          height: 136,
          padding: const EdgeInsets.fromLTRB(
            14,
            13,
            11,
            13,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    glow(
                      width: 78,
                      height: 16,
                      radius: 8,
                    ),
                    const SizedBox(height: 8),
                    glow(
                      width: 134,
                      height: 15,
                      radius: 7,
                    ),
                    const SizedBox(height: 7),
                    glow(
                      width: 96,
                      height: 9,
                      radius: 5,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        glow(
                          width: 56,
                          height: 18,
                          radius: 9,
                        ),
                        const SizedBox(width: 6),
                        glow(
                          width: 49,
                          height: 18,
                          radius: 9,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              glow(
                width: 96,
                height: 100,
                radius: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}
